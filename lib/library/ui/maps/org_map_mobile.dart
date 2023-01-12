import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../api/sharedprefs.dart';
import '../../bloc/organization_bloc.dart';
import '../../data/organization.dart';
import '../../data/project_position.dart';
import '../../data/user.dart';
import '../../functions.dart';
import '../../hive_util.dart';

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
  Completer<GoogleMapController> _mapController = Completer();
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  var random = Random(DateTime.now().millisecondsSinceEpoch);
  final _key = GlobalKey<ScaffoldState>();
  static const DEFAULT_ZOOM = 10.0;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(-25.42796133580664, 26.085749655962),
    zoom: DEFAULT_ZOOM,
  );
  List<ProjectPosition> _projectPositions = [];
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
    user = await Prefs.getUser();
    organization = await organizationBloc.getOrganizationById(
        organizationId: user!.organizationId!);
    _refreshProjectPositions(forceRefresh: false);

  }

  void _refreshProjectPositions({required bool forceRefresh}) async {
    _projectPositions = await organizationBloc.getProjectPositions(
        organizationId: organization!.organizationId!,
        forceRefresh: forceRefresh);
    _addMarkers();
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
  Future<void> _addMarkers() async {
    pp('$mm OrganizationMapMobile: _addMarkers: ....... 🍎 ${_projectPositions.length}');
    markers.clear();
    for (var projectPosition in _projectPositions) {
      final MarkerId markerId =
          MarkerId('${projectPosition.projectId}_${random.nextInt(9999988)}');
      final Marker marker = Marker(
        markerId: markerId,
        // icon: markerIcon,
        position: LatLng(
          projectPosition.position!.coordinates.elementAt(1),
          projectPosition.position!.coordinates.elementAt(0),
        ),
        infoWindow: InfoWindow(
            title: projectPosition.projectName,
            snippet: 'Project Located Here'),
        onTap: () {
          _onMarkerTapped(projectPosition);
        },
      );
      markers[markerId] = marker;
    }
    final CameraPosition _first = CameraPosition(
      target: LatLng(_projectPositions.elementAt(0).position!.coordinates.elementAt(1),
          _projectPositions.elementAt(0).position!.coordinates.elementAt(0)),
      zoom: DEFAULT_ZOOM,
    );
    googleMapController = await _mapController.future;
    googleMapController!.animateCamera(CameraUpdate.newCameraPosition(_first));
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
            style: GoogleFonts.lato(
          textStyle:
          Theme.of(context).textTheme.bodyMedium,
          fontWeight: FontWeight.normal,
        ),
          ),
        ),
        body: Stack(
          children: [
            GoogleMap(
              mapType: MapType.hybrid,
              mapToolbarEnabled: true,
              initialCameraPosition: _kGooglePlex,
              zoomControlsEnabled: true,
              myLocationButtonEnabled: true,
              compassEnabled: true,
              buildingsEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                _mapController.complete(controller);
                googleMapController = controller;
              },
              myLocationEnabled: true,
              markers: Set<Marker>.of(markers.values),
            ),
          ],
        ),
      ),
    );
  }
}
