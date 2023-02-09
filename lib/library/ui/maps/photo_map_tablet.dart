import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:animations/animations.dart';
import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/bloc/fcm_bloc.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';
import 'package:geo_monitor/library/bloc/project_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../api/data_api.dart';
import '../../data/city.dart';
import '../../data/photo.dart';
import '../../data/project.dart';
import '../../data/position.dart' as local;
import '../../data/project_polygon.dart';
import '../../data/project_position.dart';
import '../../data/user.dart';
import '../../emojis.dart';
import '../../functions.dart';
import '../../location/loc_bloc.dart';

class PhotoMapTablet extends StatefulWidget {
  final Photo photo;

  const PhotoMapTablet({
    super.key,
    required this.photo,
  });

  @override
  PhotoMapTabletState createState() => PhotoMapTabletState();
}

class PhotoMapTabletState extends State<PhotoMapTablet>
    with SingleTickerProviderStateMixin {
  final mm = '🔷🔷🔷PhotoMapTablet: ';
  late AnimationController _animationController;
  final Completer<GoogleMapController> _mapController = Completer();

  BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  var random = Random(DateTime.now().millisecondsSinceEpoch);
  final _key = GlobalKey<ScaffoldState>();
  bool busy = false;
  User? user;
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(-25.85656, 27.7857),
    zoom: 14.4746,
  );

  @override
  void initState() {
    _animationController = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 2000),
        reverseDuration: const Duration(milliseconds: 1500),
        vsync: this);
    super.initState();
    _getUser();
    _setMarkerIcon();
  }

  void _setMarkerIcon() async {
    BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(4.0, 4.0)),
      "assets/avatar.png",
    ).then(
      (icon) {
        setState(() {
          markerIcon = icon;
        });
      },
    );
  }

  void _getUser() async {
    user = await prefsOGx.getUser();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  GoogleMapController? googleMapController;
  double _latitude = 0.0, _longitude = 0.0;

  Future<void> _addMarker() async {
    pp('$mm _addMarker for photo: ....... 🍎 ');
    markers.clear();
    var latLongs = <LatLng>[];
    var latLng = LatLng(widget.photo.projectPosition!.coordinates[1],
        widget.photo.projectPosition!.coordinates[0]);
    latLongs.add(latLng);

    final MarkerId markerId =
        MarkerId('${widget.photo.photoId}_${random.nextInt(9999988)}');
    final Marker marker = Marker(
      markerId: markerId,
      // icon: markerIcon,
      position: latLng,
      infoWindow: InfoWindow(
          title: widget.photo.projectName,
          snippet: 'Photo was taken here'),
      onTap: () {
        _onMarkerTapped();
      },
    );
    markers[markerId] = marker;

    googleMapController = await _mapController.future;
    _animateCamera(latitude: latLng.latitude, longitude: latLng.longitude, zoom: 14.0);
  }

  void _onMarkerTapped() {
    pp('💜 💜 💜 💜 💜 💜 PhotoMapTablet: _onMarkerTapped ....... ');
  }

  bool isWithin = false;

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat.yMMMEd().format(DateTime.parse(widget.photo.created!));
    var time = TimeOfDay.fromDateTime(DateTime.parse(widget.photo.created!));
    return SafeArea(
      child: Scaffold(
        key: _key,
        appBar: AppBar(
          title: Text(
            'Photo Location',
            style: myTextStyleMediumBold(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 12,
                    ),
                    Flexible(
                      child: Text(
                        widget.photo.projectName!,
                        style: myTextStyleLargePrimaryColor(context),
                      ),
                    ),
                    const SizedBox(
                      width: 28,
                    ),

                    busy
                        ? const SizedBox(
                            width: 48,
                          )
                        : const SizedBox(),
                    busy
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              backgroundColor: Colors.pink,
                            ),
                          )
                        : const SizedBox(),
                  ],
                ),
                const SizedBox(
                  height: 16,
                )
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            GoogleMap(
              mapType: MapType.hybrid,
              mapToolbarEnabled: true,
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) async {
                pp('\n\\$mm 🍎🍎🍎........... GoogleMap onMapCreated ... ready to rumble!\n\n');
                _mapController.complete(controller);
                googleMapController = controller;
                _addMarker();
                setState(() {});
                _animationController.forward();
              },
              // myLocationEnabled: true,
              markers: Set<Marker>.of(markers.values),
              compassEnabled: true,
              buildingsEnabled: true,
              zoomControlsEnabled: true,

            ),
             Positioned(
                    left: 12,
                    top: 12,
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (BuildContext context, Widget? child) {
                        return FadeScaleTransition(
                          animation: _animationController,
                          child: child,
                        );
                      },
                      child: Card(
                        elevation: 8,
                        color: Colors.black38,
                        child: SizedBox(
                          height: 420,
                          width: 220,
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 12,
                              ),
                              Image.network(
                                widget.photo.thumbnailUrl!,
                                width: 220,
                                height: 340,
                                fit: BoxFit.fill,
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              Text(
                                '$formattedDate ${time.hour}:${time.minute}',
                                style: myTextStyleSmall(context),
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              Text('${widget.photo.userName}', style: myTextStyleSmall(context),),
                              const SizedBox(
                                height: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

          ],
        ),
      ),
    );
  }

  void _animateCamera(
      {required double latitude,
      required double longitude,
      required double zoom}) {
    final CameraPosition cameraPosition = CameraPosition(
      target: LatLng(latitude, longitude),
      zoom: zoom,
    );
    googleMapController!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  _onSelected(local.Position p1) {
    _animateCamera(
        latitude: p1.coordinates[1], longitude: p1.coordinates[0], zoom: 14.6);
  }
}

class ProjectPositionChooser extends StatelessWidget {
  const ProjectPositionChooser(
      {Key? key,
      required this.projectPositions,
      required this.projectPolygons,
      required this.onSelected})
      : super(key: key);
  final List<ProjectPosition> projectPositions;
  final List<ProjectPolygon> projectPolygons;
  final Function(local.Position) onSelected;
  @override
  Widget build(BuildContext context) {
    var list = <local.Position>[];
    // projectPositions.sort((a,b) => a.created!.compareTo(b.created!));
    for (var value in projectPositions) {
      list.add(value.position!);
    }
    for (var value in projectPolygons) {
      list.add(value.positions.first);
      // for (var element in value.positions) {
      //
      // }
    }
    var cnt = 0;
    var menuItems = <DropdownMenuItem>[];
    for (var pos in list) {
      cnt++;
      menuItems.add(
        DropdownMenuItem<local.Position>(
          value: pos,
          child: Row(
            children: [
              Text(
                'Location No. ',
                style: myTextStyleSmall(context),
              ),
              const SizedBox(
                width: 8,
              ),
              Text(
                '$cnt',
                style: myNumberStyleSmall(context),
              ),
            ],
          ),
        ),
      );
    }
    return DropdownButton(
        hint: Text(
          'Locations',
          style: myTextStyleSmall(context),
        ),
        items: menuItems,
        onChanged: (value) {
          onSelected(value);
        });
  }
}
