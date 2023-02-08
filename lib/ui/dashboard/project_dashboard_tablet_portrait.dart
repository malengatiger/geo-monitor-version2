import 'dart:async';

import 'package:animations/animations.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geo_monitor/library/data/geofence_event.dart';
import 'package:geo_monitor/library/data/settings_model.dart';
import 'package:geo_monitor/library/ui/maps/project_map_mobile.dart';
import 'package:geo_monitor/library/ui/media/list/project_media_list_mobile.dart';
import 'package:geo_monitor/ui/dashboard/dashboard_grid.dart';
import 'package:geofence_service/geofence_service.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../library/api/prefs_og.dart';
import '../../library/bloc/connection_check.dart';
import '../../library/bloc/downloader.dart';
import '../../library/bloc/fcm_bloc.dart';
import '../../library/bloc/organization_bloc.dart';
import '../../library/bloc/project_bloc.dart';
import '../../library/bloc/theme_bloc.dart';
import '../../library/bloc/uploader.dart';
import '../../library/data/audio.dart';
import '../../library/data/data_bag.dart';
import '../../library/data/field_monitor_schedule.dart';
import '../../library/data/photo.dart';
import '../../library/data/project.dart';
import '../../library/data/project_polygon.dart';
import '../../library/data/project_position.dart';
import '../../library/data/user.dart';
import '../../library/data/video.dart';
import '../../library/emojis.dart';
import '../../library/functions.dart';
import '../../library/geofence/geofencer_two.dart';
import '../../library/ui/maps/project_polygon_map_mobile.dart';
import '../../library/ui/media/user_media_list/user_media_list_mobile.dart';
import '../../library/ui/message/message_main.dart';
import '../../library/ui/project_list/project_chooser.dart';
import '../../library/ui/project_list/project_list_mobile.dart';
import '../../library/ui/settings/settings_mobile.dart';
import '../../library/users/list/user_list_main.dart';
import '../intro/intro_page_viewer_portrait.dart';
import 'dashboard_mobile.dart';
import 'project_dashboard_grid.dart';

class ProjectDashboardTabletPortrait extends StatefulWidget {
  const ProjectDashboardTabletPortrait({
    Key? key,
     required this.project,
  }) : super(key: key);
  final Project project;
  @override
  ProjectDashboardTabletPortraitState createState() => ProjectDashboardTabletPortraitState();
}

class ProjectDashboardTabletPortraitState extends State<ProjectDashboardTabletPortrait>
    with TickerProviderStateMixin {

  var busy = false;
  var _projects = <Project>[];
  var _users = <User>[];
  var _photos = <Photo>[];
  var _videos = <Video>[];
  var _projectPositions = <ProjectPosition>[];
  var _projectPolygons = <ProjectPolygon>[];
  var _schedules = <FieldMonitorSchedule>[];
  var _audios = <Audio>[];
  User? user;

  static const mm = '🎽🎽🎽🎽🎽🎽 ProjectDashboardTabletPortrait: 🎽';
  bool networkAvailable = false;
  final dur = 600;

  @override
  void initState() {
    // _setAnimationControllers();
    super.initState();

  }


  final _key = GlobalKey<ScaffoldState>();

  _navigateToMedia() async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: ProjectMediaListMobile(project: widget.project,)));

  }

  _navigateToPositionsMap() async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: ProjectMapMobile(project: widget.project,)));

  }

  _navigateToPolygonsMap() async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: ProjectPolygonMapMobile(project: widget.project,)));

  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _key,
        appBar: AppBar(
          actions: [

            IconButton(
              icon: Icon(
                Icons.refresh,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                //
              },
            )
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(160),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const SizedBox(height: 20,),
                  Text('Project Dashboard', style: myTextStyleSmall(context),),
                   const SizedBox(height: 48,),
                   Text(
                          widget.project.name!,
                          style: GoogleFonts.lato(
                            textStyle: Theme.of(context).textTheme.titleLarge,
                            fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor
                          ),
                        ),
                  const SizedBox(
                    height: 28,
                  ),
                ],
              ),
            ),
          ),
        ),

        body: busy
            ? const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    backgroundColor: Colors.amber,
                  ),
                ),
              )
            : Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ProjectDashboardGrid(
                      showProjectName: false,
                      onTypeTapped: (type){
                        switch(type) {
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
                      }, project: widget.project,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

//////
void showKillDialog({required String message, required BuildContext context}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(
        "Critical App Message",
        style: myTextStyleLarge(ctx),
      ),
      content: Text(
        message,
        style: myTextStyleMedium(ctx),
      ),
      shape: getRoundedBorder(radius: 16),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            pp('$mm Navigator popping for the last time, Sucker! 🔵🔵🔵');
            var android = UniversalPlatform.isAndroid;
            var ios = UniversalPlatform.isIOS;
            if (android) {
              SystemNavigator.pop();
            }
            if (ios) {
              Navigator.of(ctx).pop();
              Navigator.of(ctx).pop();
            }
          },
          child: const Text("Exit the App"),
        ),
      ],
    ),
  );
}

final mm = '${E.heartRed}${E.heartRed}${E.heartRed}${E.heartRed} Dashboard: ';

