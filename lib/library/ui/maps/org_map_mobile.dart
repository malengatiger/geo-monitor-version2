import 'dart:async';
import 'dart:math';

import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../api/prefs_og.dart';
import '../../bloc/organization_bloc.dart';
import '../../data/organization.dart';
import '../../data/project.dart';
import '../../data/project_position.dart';
import '../../data/user.dart';
import '../../functions.dart';

class OrganizationMapMobile extends StatefulWidget {
  const OrganizationMapMobile({
    super.key,
  });

  // final Organization organization;
  @override
  OrganizationMapMobileState createState() => OrganizationMapMobileState();
}

class OrganizationMapMobileState extends State<OrganizationMapMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Completer<GoogleMapController> _mapController = Completer();
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  var random = Random(DateTime.now().millisecondsSinceEpoch);
  final _key = GlobalKey<ScaffoldState>();
  static const defaultZoom = 10.0;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(-25.42796133580664, 26.085749655962),
    zoom: defaultZoom,
  );
  List<ProjectPosition> _projectPositions = [];
  List<Project> _projects = [];

  Organization? organization;
  bool loading = false;
  User? user;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getOrganization();
  }

  void _getOrganization() async {
    setState(() {
      loading = true;
    });
    user = await prefsOGx.getUser();
    organization = await organizationBloc.getOrganizationById(
        organizationId: user!.organizationId!);

    _refreshProjectPositions(forceRefresh: false);
  }

  void _refreshProjectPositions({required bool forceRefresh}) async {
    setState(() {
      loading = true;
    });
    var map = await getStartEndDates();
    final startDate = map['startDate'];
    final endDate = map['endDate'];
    _projectPositions = await organizationBloc.getProjectPositions(
        organizationId: organization!.organizationId!,
        forceRefresh: forceRefresh, startDate: startDate!, endDate: endDate!);
    _projects = await organizationBloc.getOrganizationProjects(
        organizationId: organization!.organizationId!, forceRefresh: forceRefresh);
    _createMarkers();
    setState(() {
      loading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final mm = '💜 💜 💜 💜 💜 💜 Organization Map ';
  GoogleMapController? googleMapController;
  var latLngs = <LatLng>[];
  LatLngBounds? bounds;
  Future<void> _createMarkers() async {
    pp('$mm OrganizationMapMobile: _addMarkers: ....... 🍎 ${_projectPositions.length}');
    markers.clear();
    latLngs.clear();
    for (var projectPosition in _projectPositions) {
      final latLng = LatLng(
        projectPosition.position!.coordinates.elementAt(1),
        projectPosition.position!.coordinates.elementAt(0),
      );
      latLngs.add(latLng);
      final MarkerId markerId =
          MarkerId('${projectPosition.projectId}_${random.nextInt(9999988)}');
      final Marker marker = Marker(
        markerId: markerId,
        // icon: markerIcon,
        position: latLng,
        infoWindow: InfoWindow(
            title: projectPosition.projectName,
            snippet: 'Project Located Here'),
        onTap: () {
          _onMarkerTapped(projectPosition);
        },
      );
      markers[markerId] = marker;
    }
    bounds = boundsFromLatLngList(latLngs);
    pp(' bounds: ${bounds!.toJson()}  🍎');
    // try {
    //   _animateMap();
    // } catch (e) {
    //   pp('$mm $e ');
    // }

    final CameraPosition first = CameraPosition(
      target: LatLng(
          _projectPositions.elementAt(0).position!.coordinates.elementAt(1),
          _projectPositions.elementAt(0).position!.coordinates.elementAt(0)),
      zoom: 10.0,
    );
    googleMapController!.animateCamera(CameraUpdate.newCameraPosition(first));

  }
  Future<void> _animateMap() async {
    if (bounds != null) {
      googleMapController = await _mapController.future;
      await googleMapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds!, 12));
      setState(() {

      });
    } else {
      pp('$mm bounds still null .....');
    }
  }

  void _onMarkerTapped(ProjectPosition projectPosition) {
    pp('$mm OrganizationMapMobile: _onMarkerTapped ....... ${projectPosition.projectName}');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _key,
        appBar: AppBar(
          title: Text(
            'Organization Project Locations',
            style: myTextStyleSmall(context),
          ),
          bottom: PreferredSize(preferredSize: const Size.fromHeight(48), child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: InkWell(
                  onTap: (){
                    _refreshProjectPositions(forceRefresh: true);
                  },
                  child: bd.Badge(
                    // badgeColor: Theme.of(context).primaryColor,
                    position:bd. BadgePosition.topEnd(top: -20,end: 12),
                    badgeContent: Text('${_projects.length}', style: myTextStyleMedium(context),),
                    // padding: const EdgeInsets.all(8.0),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        organization == null? const SizedBox(): Text(organization!.name!, style: myTextStyleLarge(context),),
                        const SizedBox(width: 28,),

                        loading? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 4, backgroundColor: Colors.pink,
                          ),): const SizedBox(),
                      ],

                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24,),
            ],
          ),),
        ),
        body: Stack(
          children: [
            GestureDetector(
              onTap: () {
                _refreshProjectPositions(forceRefresh: true);
              },
              child: bd.Badge(
                badgeContent: Text(
                  '${_projectPositions.length}',
                  style: myTextStyleSmall(context),
                ),
                badgeStyle:  bd.BadgeStyle(
                  badgeColor: Theme.of(context).primaryColor,
                  elevation: 8, padding: const EdgeInsets.all(8),
                ),

                position: bd.BadgePosition.topEnd(top: 8, end: 8),
                child: GoogleMap(
                  mapType: MapType.hybrid,
                  mapToolbarEnabled: true,
                  initialCameraPosition: _kGooglePlex,
                  zoomControlsEnabled: true,
                  // myLocationButtonEnabled: true,
                  compassEnabled: true,
                  buildingsEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    pp('$mm onMapCreated ... ready to rumble? ...');
                    _mapController.complete(controller);
                    googleMapController = controller;
                    _createMarkers();
                  },
                  markers: Set<Marker>.of(markers.values),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
