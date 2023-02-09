import 'package:flutter/material.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';
import 'package:geo_monitor/library/ui/maps/project_map_main.dart';
import 'package:geo_monitor/library/ui/media/list/project_media_main.dart';
import 'package:geo_monitor/library/ui/project_edit/project_edit_main.dart';
import 'package:geo_monitor/library/ui/project_list/project_list_card.dart';
import 'package:geo_monitor/library/ui/project_monitor/project_monitor_main.dart';
import 'package:geo_monitor/library/ui/settings/settings_form.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:page_transition/page_transition.dart';

import '../../../ui/audio/audio_mobile.dart';
import '../../../ui/dashboard/project_dashboard_mobile.dart';
import '../../bloc/project_bloc.dart';
import '../../data/position.dart';
import '../../data/project.dart';
import '../../data/user.dart' as mon;
import '../../data/user.dart';
import '../../functions.dart';
import '../../generic_functions.dart';
import '../maps/org_map_mobile.dart';
import '../maps/project_polygon_map_mobile.dart';
import '../media/list/project_media_list_mobile.dart';
import '../project_location/project_location_main.dart';
import '../schedule/project_schedules_mobile.dart';

class ProjectListTabletLandscape extends StatefulWidget {
  final mon.User? user;

  const ProjectListTabletLandscape({this.user, super.key});

  @override
  ProjectListTabletLandscapeState createState() =>
      ProjectListTabletLandscapeState();
}

class ProjectListTabletLandscapeState extends State<ProjectListTabletLandscape>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  User? user;
  var projects = <Project>[];
  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getData(false);
  }

  void _getData(bool forceRefresh) async {
    setState(() {
      busy = true;
    });
    try {
      user = await prefsOGx.getUser();
      projects = await organizationBloc.getOrganizationProjects(
          organizationId: user!.organizationId!, forceRefresh: forceRefresh);
    } catch (e) {
      pp(e);
      if (mounted) {
        showToast(message: '$e', context: context);
      }
    }

    setState(() {
      busy = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToDetail(Project? p) {
    if (user!.userType == UserType.fieldMonitor) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1500),
              child: ProjectEditMain(p)));
    }
    if (user!.userType! == UserType.orgAdministrator ||
        user!.userType == UserType.orgExecutive) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1500),
              child: ProjectEditMain(p)));
    }
  }

  void _navigateToProjectLocation(Project p) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(milliseconds: 1500),
            child: ProjectLocationMain(p)));
  }

  void _navigateToMonitorStart(Project p) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(milliseconds: 1500),
            child: ProjectMonitorMain(p)));
  }

  void _navigateToProjectMedia(Project p) {
    if (user!.userType == UserType.fieldMonitor) {}
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(milliseconds: 1500),
            child: ProjectMediaMain(project: p)));
  }

  void _navigateToProjectSchedules(Project p) {
    if (user!.userType == UserType.fieldMonitor) {}
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(milliseconds: 1500),
            child: ProjectSchedulesMobile(project: p)));
  }

  void _navigateToProjectAudio(Project p) {
    if (user!.userType == UserType.fieldMonitor) {}
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(milliseconds: 1500),
            child: AudioHandler(project: p)));
  }

  Future<void> _navigateToOrgMap() async {
    pp('_navigateToOrgMap: ');

    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.leftToRightWithFade,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1000),
              child: const OrganizationMapMobile()));
    }
  }

  void _navigateToProjectMap(Project p) async {
    pp('.................. _navigateToProjectMap: ');

    var positions = await projectBloc.getProjectPositions(
        projectId: p.projectId!, forceRefresh: false);
    var polygons = await projectBloc.getProjectPolygons(
        projectId: p.projectId!, forceRefresh: false);
    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1000),
              child: ProjectMapMain(
                project: p,
              )));
    }
  }

  void _navigateToProjectPolygonMap(Project p) async {
    pp('.................. _navigateToProjectPolygonMap: ');

    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1000),
              child: ProjectPolygonMapMobile(
                project: p,
              )));
    }
  }

  void _navigateToProjectDashboard(Project p) async {
    pp('.................. _navigateToProjectPolygonMap: ');

    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1000),
              child: ProjectDashboardMobile(
                project: p,
              )));
    }
  }

  bool _showPositionChooser = false;

  void _navigateToDirections(
      {required double latitude, required double longitude}) async {
    pp('$mm 🍎 🍎 🍎 start Google Maps Directions .....');

    final availableMaps = await MapLauncher.installedMaps;
    pp('$mm 🍎 🍎 🍎 availableMaps: $availableMaps'); // [AvailableMap { mapName: Google Maps, mapType: google }, ...]

    var coordinates = Coords(latitude, longitude);
    await availableMaps.first.showDirections(destination: coordinates);
  }

  _onPositionSelected(Position p1) {
    setState(() {
      _showPositionChooser = false;
    });
    _navigateToDirections(
        latitude: p1.coordinates[1], longitude: p1.coordinates[0]);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Geo Projects', style: myTextStyleLarge(context),),
        actions: [
          IconButton(
              onPressed: () {
                _getData(true);
              },
              icon: Icon(
                Icons.refresh,
                color: Theme.of(context).primaryColor,
              ))
        ],
      ),
      body: Row(
        children: [
          user == null
              ? const SizedBox()
              : Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ProjectListCard(
                      projects: projects,
                      width: width/2,
                      horizontalPadding: 24,
                      navigateToDetail: _navigateToDetail,
                      navigateToProjectLocation: _navigateToProjectLocation,
                      navigateToProjectMedia: _navigateToProjectMedia,
                      navigateToProjectMap: _navigateToProjectMap,
                      navigateToProjectPolygonMap: _navigateToProjectPolygonMap,
                      navigateToProjectDashboard: _navigateToProjectDashboard,
                      user: user!),
                ),
              ),
          GeoPlaceHolder(
            width: (width/2) - 64,
          ),
        ],
      ),
    ));
  }
}
