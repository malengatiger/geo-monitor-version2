import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/data/project_position.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../api/data_api.dart';
import '../../api/sharedprefs.dart';
import '../../bloc/project_bloc.dart';
import '../../data/city.dart';
import '../../data/project.dart';
import '../../data/position.dart' as local;
import '../../data/project_polygon.dart';
import '../../data/user.dart';
import '../../emojis.dart';
import '../../functions.dart';
import '../../generic_functions.dart';
import '../../location/loc_bloc.dart';

class ProjectPolygonMapMobile extends StatefulWidget {
  final Project project;

  const ProjectPolygonMapMobile({
    super.key,
    required this.project,
  });

  @override
  ProjectPolygonMapMobileState createState() => ProjectPolygonMapMobileState();
}

class ProjectPolygonMapMobileState extends State<ProjectPolygonMapMobile>
    with SingleTickerProviderStateMixin {
  final mm = '🍎🍎🍎 ProjectPolygonMapMobile: ';
  late AnimationController _animationController;
  final Completer<GoogleMapController> _mapController = Completer();
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  var random = Random(DateTime.now().millisecondsSinceEpoch);
  final _key = GlobalKey<ScaffoldState>();
  bool busy = false;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 6,
  );
  final Set<Polygon> _polygons = HashSet<Polygon>();
  final Set<Marker> _positionMarkers = HashSet<Marker>();
  var projectPolygons = <ProjectPolygon>[];
  var projectPositions = <ProjectPosition>[];

  User? user;

  void _getData(bool forceRefresh) async {
    setState(() {
      busy = true;
    });
    try {
      user = await Prefs.getUser();
      projectPolygons = await projectBloc.getProjectPolygons(
          projectId: widget.project.projectId!, forceRefresh: forceRefresh);
      projectPositions = await projectBloc.getProjectPositions(projectId: widget.project.projectId!,
          forceRefresh: forceRefresh);
      var loc = await locationBloc.getLocation();
      _latitude = loc.latitude;
      _longitude = loc.longitude;
      _addMarkers();
      _buildProjectPolygons();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    setState(() {
      busy = false;
    });
  }

  void _addMarkers() {
    markers.clear();
    for (var pos in projectPositions) {
      var marker = Marker(
          position: LatLng(pos.position!.coordinates.elementAt(1), pos.position!.coordinates.elementAt(0)),
          markerId: MarkerId(DateTime.now().toIso8601String()));
      _positionMarkers.add(marker);
    }
    pp('$mm _addMarkers: 🍏project markers added.: '
        '🔵 ${_positionMarkers.length} markers ...');
    _animateCamera(zoom: 12.6);
    setState(() {});
  }
  void _buildProjectPolygons() {
    pp('$mm _buildProjectPolygons happening ... projectPolygons: ${projectPolygons.length}');
    _polygons.clear();
    for (var polygon in projectPolygons) {
      var points = <LatLng>[];
      for (var position in polygon.positions) {
        points.add(LatLng(position.coordinates[1], position.coordinates[0]));
      }
      _polygons.add(Polygon(
        polygonId: PolygonId(polygon.projectPolygonId!),
        points: points,
        fillColor: Colors.black26,
        strokeColor: Colors.pink,
        geodesic: true,
        strokeWidth: 4,
      ));
    }

    pp('$mm _buildProjectPolygons: 🍏project polygons created.: '
        '🔵 ${_polygons.length} points in polygon ...');
    _animateCamera(zoom: 12.6);
    setState(() {});
  }

  @override
  void initState() {
    _animationController = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 2000),
        reverseDuration: const Duration(milliseconds: 1500),
        vsync: this);
    super.initState();
    _getData(false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  GoogleMapController? googleMapController;
  double _latitude = 0.0, _longitude = 0.0;

  final _myPoints = <LatLng>[];

  void _drawPolygon() {
    pp('$mm about to draw my Polygon with 💜 ${_myPoints.length} points');
    _polygons.add(Polygon(
      polygonId: PolygonId(DateTime.now().toIso8601String()),
      points: _myPoints,
      fillColor: Colors.black26,
      strokeColor: Colors.pink,
      geodesic: true,
      strokeWidth: 4,
    ));
    setState(() {});
  }

  void _clearPolygon() {
    pp('$mm about to CLEAR my Polygon with ${_myPoints.length} points');
    _myPoints.clear();
    _polygons.clear();
    _buildProjectPolygons();
    setState(() {});
  }

  void _onMapTap(LatLng argument) {
    pp('$mm Map detected a tap! at $argument');
    if (user!.userType == UserType.fieldMonitor) {
      pp('$mm FieldMonitor not allowed to create polygon, 🔶 quitting!');
      return;
    }
    _myPoints.add(argument);
    pp('$mm Polygon has collected ${_myPoints.length} ');
    if (_myPoints.length > 1) {
      _drawPolygon();
    }
  }

  Future<void> _submitNewPolygon() async {
    pp('\n\n$mm _submitNewPolygon started. 🍏🍏adding polygon to project ...'
        '${Emoji.blueDot} polygon points: ${_myPoints.length}');

    setState(() {
      busy = true;
    });
    try {
      _latitude = _myPoints.first.latitude;
      _longitude = _myPoints.first.longitude;

      pp('Go and find nearest cities to this location : lat: $_latitude lng: $_longitude ...');
      List<City> cities = await DataAPI.findCitiesByLocation(
          latitude: _latitude, longitude: _longitude, radiusInKM: 5.0);

      pp('$mm Cities around this project polygon: ${cities.length}');

      var positions = <local.Position>[];
      for (var point in _myPoints) {
        positions.add(local.Position(
            type: 'Point', coordinates: [point.longitude, point.latitude]));
      }
      pp('$mm Positions in this project polygon: ${positions.length}; 🔷 polygon about to be created');
      var pos = ProjectPolygon(
          projectName: widget.project.name,
          projectPolygonId: const Uuid().v4(),
          created: DateTime.now().toUtc().toIso8601String(),
          positions: positions,
          nearestCities: cities,
          organizationId: widget.project.organizationId,
          projectId: widget.project.projectId);

      var resultPolygon = await DataAPI.addProjectPolygon(polygon: pos);
      pp('$mm polygon saved in DB. we are good to go! '
          '🍏🍏${resultPolygon.toJson()}🍏🍏 ');
      projectPolygons.add(resultPolygon);
      _buildProjectPolygons();
      _myPoints.clear();
    } catch (e) {
      pp(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            duration: const Duration(seconds: 10), content: Text('$e')));
      }
    }
    setState(() {
      busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          // backgroundColor: Colors.white,
          elevation: 0.0,
          titleSpacing: 10.0,
          centerTitle: true,
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child:  Icon(
              Icons.arrow_back_ios,
              color: Theme.of(context).primaryColor,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Project Monitoring Areas',
                      style: myTextStyleSmall(context),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 24,
                )
              ],
            ),
          ),
          actions: [
            IconButton(onPressed: (){
               _getData(true);
            }, icon: Icon(Icons.refresh, size: 20,
              color: Theme.of(context).primaryColor,)),
            _myPoints.length > 2
                ? IconButton(
                    onPressed: () {
                      _submitNewPolygon();
                    },
                    icon: Icon(
                      Icons.check,
                      size: 28,
                      color: Theme.of(context).primaryColor,
                    ))
                : const SizedBox(),
            _myPoints.isEmpty
                ? const SizedBox()
                : IconButton(
                    tooltip: 'Clear area you are working on',
                    onPressed: () {
                      _clearPolygon();
                    },
                    icon: Icon(
                      Icons.layers_clear,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    )),

            IconButton(onPressed: (){

            }, icon: Icon(Icons.close, size: 20,
              color: Theme.of(context).primaryColor,)),
          ],
        ),
        body: Stack(
          children: [
            GestureDetector(
              onTap: () {
                _animateCamera(zoom: 10.0);
              },
              child: Badge(
                badgeColor: Colors.pink,
                badgeContent: Text(
                  '${projectPolygons.length + projectPositions.length}',
                  style: myNumberStyleSmall(context),
                ),
                padding: const EdgeInsets.all(8.0),
                position: BadgePosition.topEnd(top: 8, end: 8),
                elevation: 16,
                child: GoogleMap(
                  mapType: MapType.hybrid,
                  mapToolbarEnabled: true,
                  initialCameraPosition: _kGooglePlex,
                  onMapCreated: (GoogleMapController controller) {
                    pp('🍎🍎🍎........... GoogleMap onMapCreated ... ready to rumble!');
                    _mapController.complete(controller);
                    googleMapController = controller;
                    setState(() {});
                  },
                  // myLocationEnabled: true,
                  markers: _positionMarkers,
                  polygons: _polygons,
                  compassEnabled: true,
                  buildingsEnabled: true,
                  zoomControlsEnabled: true,
                  onLongPress: _onLongPress,
                  onTap: _onMapTap,
                  rotateGesturesEnabled: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _animateCamera({required double zoom}) {
    CameraPosition? first;
    if (projectPolygons.isEmpty) {
      first = CameraPosition(
        target: LatLng(_latitude, _longitude),
        zoom: zoom,
      );
    } else {
      first = CameraPosition(
        target: LatLng(
            projectPolygons
                .elementAt(0)
                .positions
                .elementAt(0)
                .coordinates
                .elementAt(1),
            projectPolygons
                .elementAt(0)
                .positions
                .elementAt(0)
                .coordinates
                .elementAt(0)),
        zoom: zoom,
      );
    }
    googleMapController!.animateCamera(CameraUpdate.newCameraPosition(first));
    setState(() {});
  }

  void _onLongPress(LatLng latLng) {
    pp('$mm long pressed location: 🍎 $latLng');
    var isOK = checkIfLocationIsWithinPolygons(
        latitude: latLng.latitude, longitude: latLng.longitude, polygons: projectPolygons);
    pp('$mm long pressed location found in any of the project\s 🍎 '
        'polygons; isWithin the polygons: $isOK - ${isOK? Emoji.leaf: Emoji.redDot}');
    if (isOK) {
      showToast(
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.teal,
          toastGravity: ToastGravity.TOP,
          padding: 12.0,
          textStyle: GoogleFonts.lato(
              textStyle: Theme.of(context).textTheme.bodySmall,
              fontWeight: FontWeight.normal,
              color: Colors.white),
          message: 'Bravo! You are inside!',
          context: context);
    } else {
      showToast(
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.pink,
          toastGravity: ToastGravity.TOP,
          padding: 12.0,
          textStyle: GoogleFonts.lato(
              textStyle: Theme.of(context).textTheme.bodySmall,
              fontWeight: FontWeight.normal,
              color: Colors.white),
          message: 'Sorry! You are outside!',
          context: context);
    }
  }
}
