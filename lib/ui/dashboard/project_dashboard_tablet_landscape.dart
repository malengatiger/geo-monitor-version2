import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/downloader.dart';
import 'package:geo_monitor/library/ui/maps/project_map_mobile.dart';
import 'package:geo_monitor/library/ui/maps/project_polygon_map_mobile.dart';
import 'package:geo_monitor/library/ui/media/list/project_media_list_mobile.dart';
import 'package:geo_monitor/library/ui/settings/settings_form.dart';
import 'package:geo_monitor/ui/dashboard/project_dashboard_grid.dart';
import 'package:page_transition/page_transition.dart';

import '../../library/data/project.dart';
import '../../library/functions.dart';
import '../../library/ui/geo_activity.dart';

class ProjectDashboardTabletLandscape extends StatefulWidget {
  const ProjectDashboardTabletLandscape({Key? key, required this.project})
      : super(key: key);

  final Project project;

  @override
  ProjectDashboardTabletLandscapeState createState() =>
      ProjectDashboardTabletLandscapeState();
}

class ProjectDashboardTabletLandscapeState
    extends State<ProjectDashboardTabletLandscape>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _navigateToMedia() async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: ProjectMediaListMobile(
              project: widget.project,
            )));
  }

  _navigateToPositionsMap() async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: ProjectMapMobile(
              project: widget.project,
            )));
  }

  _navigateToPolygonsMap() async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: ProjectPolygonMapMobile(
              project: widget.project,
            )));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Project Dashboard',
          style: myTextStyleLarge(context),
        ),
      ),
      body: Row(
        children: [
          SizedBox(
              width: width / 2,
              height: 500,
              child: Center(
                child: ProjectDashboardGrid(
                    topPadding: 32,
                    showProjectName: true,
                    onTypeTapped: onTypeTapped,
                    project: widget.project),
              ),
          ),
          GeoActivity(width: width/2,),
        ],
      ),
    ));
  }

  onTypeTapped(int p1) {
    switch (p1) {
      case typePhotos:
        _navigateToMedia();
        break;
      case typeVideos:
        _navigateToMedia();
        break;
      case typeAudios:
        _navigateToMedia();
        break;
      case typePositions:
        _navigateToPositionsMap();
        break;
      case typePolygons:
        _navigateToPolygonsMap();
        break;
    }
  }
}
