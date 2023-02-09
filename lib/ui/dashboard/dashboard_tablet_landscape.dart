import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';
import 'package:geo_monitor/library/ui/geo_activity.dart';
import 'package:geo_monitor/library/ui/settings/settings_main.dart';
import 'package:geo_monitor/ui/dashboard/dashboard_grid.dart';
import 'package:geo_monitor/ui/intro/intro_main.dart';
import 'package:page_transition/page_transition.dart';

import '../../library/api/prefs_og.dart';
import '../../library/bloc/downloader.dart';
import '../../library/bloc/uploader.dart';
import '../../library/data/project.dart';
import '../../library/data/user.dart';
import '../../library/functions.dart';
import '../../library/generic_functions.dart';
import '../../library/ui/maps/project_map_mobile.dart';
import '../../library/ui/media/list/project_media_list_mobile.dart';
import '../../library/ui/media/user_media_list/user_media_list_mobile.dart';
import '../../library/ui/project_list/project_chooser.dart';
import '../../library/ui/project_list/project_list_main.dart';
import '../../library/ui/settings/settings_form.dart';
import '../../library/ui/settings/settings_mobile.dart';
import '../../library/users/full_user_photo.dart';
import '../../library/users/list/user_list_main.dart';
import '../chat/chat_page.dart';

class DashboardTabletLandscape extends StatefulWidget {
  const DashboardTabletLandscape({Key? key, required this.user})
      : super(key: key);

  final User user;
  @override
  State<DashboardTabletLandscape> createState() =>
      _DashboardTabletLandscapeState();
}

class _DashboardTabletLandscapeState extends State<DashboardTabletLandscape> {
  final mm = '🍎🍎🍎🍎DashboardTabletLandscape: ';
  var users = <User>[];
  User? user;
  @override
  void initState() {
    super.initState();
    _getData(false);

    uploader.startTimer(const Duration(seconds: 30));

  }

  void _getData(bool forceRefresh) async {
    setState(() {
      busy = true;
    });
    try {
      user = await prefsOGx.getUser();
      users = await organizationBloc.getUsers(organizationId: user!.organizationId!, forceRefresh: forceRefresh);
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

  void _navigateToProjectList() {
    if (selectedProject != null) {
      pp('$mm _navigateToProjectList ...');

      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(seconds: 1),
              child: const ProjectListMain()));
      selectedProject = null;
    } else {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(seconds: 1),
              child: const ProjectListMain()));
    }
  }

  void _navigateToMessageSender() {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: const ChatPage()));
  }

  // void _navigateToUserMediaList() async {
  //   pp('$mm _navigateToUserMediaList ...');
  //
  //   if (mounted) {
  //     Navigator.push(
  //         context,
  //         PageTransition(
  //             type: PageTransitionType.scale,
  //             alignment: Alignment.topLeft,
  //             duration: const Duration(seconds: 1),
  //             child: UserMediaListMobile(user: user!)));
  //   }
  // }

  void _navigateToIntro() {
    pp('$mm .................. _navigateToIntro to Intro ....');
    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(seconds: 1),
              child: const IntroMain()));
    }
  }


  Future<void> _navigateToFullUserPhoto() async {
    pp('$mm .................. _navigateToFullUserPhoto  ....');
    user = await prefsOGx.getUser();
    if (user != null) {
      if (mounted) {
        Navigator.push(
            context,
            PageTransition(
                type: PageTransitionType.scale,
                alignment: Alignment.topLeft,
                duration: const Duration(seconds: 1),
                child: FullUserPhoto(user: user!)));
        setState(() {});
      }
    }
  }

  void _navigateToSettings() {
    pp('$mm .................. _navigateToSettings to Settings ....');
    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.center,
              duration: const Duration(seconds: 1),
              child: const SettingsMain()));
    }
  }

  void _navigateToUserList() {
    pp('$mm _navigateToUserList ...');
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: UserListMain(
              user: user!,
              users: users,
            )));
  }

  void _navigateToProjectMedia(Project project) {
    pp('$mm _navigateToProjectMedia ...');

    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: ProjectMediaListMobile(project: project)));
  }

  void _navigateToProjectMap(Project project) {
    pp('$mm _navigateToProjectMap ...');

    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: ProjectMapMobile(project: project)));
  }

  void _navigateToDailyForecast() {
    // Navigator.push(
    //     context,
    //     PageTransition(
    //         type: PageTransitionType.scale,
    //         alignment: Alignment.topLeft,
    //         duration: const Duration(seconds: 1),
    //         child: const DailyForecastPage()));
  }

  void _showProjectDialog(int destination) {
    pp('$mm _showProjectDialog ...');

    late String title;
    switch (destination) {
      case typePhotos:
        title = 'Photos';
        break;
      case typeVideos:
        title = 'Videos';
        break;
      case typeAudios:
        title = 'Audio';
        break;
      case typePositions:
        title = 'Map';
        break;
      case typePolygons:
        title = 'Map';
        break;
      case typeSchedules:
        title = 'Schedules';
        break;
    }

    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Container(
                  color: Colors.black12,
                  child: ProjectChooser(
                      title: title,
                      height: 500,
                      onSelected: (p1) {
                        Navigator.of(context).pop();
                        _onProjectSelected(p1, destination);
                      },
                      onClose: () {
                        Navigator.pop(context);
                      }),
                ),
              ),
            ));
  }

  _onProjectSelected(Project p1, int destination) {
    switch (destination) {
      case typeVideos:
        _navigateToProjectMedia(p1);
        break;
      case typeAudios:
        _navigateToProjectMedia(p1);
        break;
      case typePhotos:
        _navigateToProjectMedia(p1);
        break;
      case typePositions:
        _navigateToProjectMap(p1);
        break;
      case typePolygons:
        _navigateToProjectMap(p1);
        break;
    }
  }

  Project? selectedProject;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Geo Dashboard'),
        actions: [
          IconButton(
              icon: Icon(
                Icons.info_outline,
                size: 24,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: _navigateToIntro),
          user == null
              ? const SizedBox()
              : user!.userType == UserType.fieldMonitor
              ? const SizedBox()
              : IconButton(
            icon: Icon(
              Icons.settings,
              size: 24,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: _navigateToSettings,
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              size: 24,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              _getData(true);
            },
          )
        ],
      ),
      body: Stack(
        children: [
          Row(
            children: [
              SizedBox(
                width: size.width/2,
                child: DashboardGrid(
                  topPadding: 24,
                  onTypeTapped: (type) {
                    switch (type) {
                      case typeProjects:
                        _navigateToProjectList();
                        break;
                      case typeUsers:
                        _navigateToUserList();
                        break;
                      case typePhotos:
                        _showProjectDialog(typePhotos);
                        break;
                      case typeVideos:
                        _showProjectDialog(typeVideos);
                        break;
                      case typeAudios:
                        _showProjectDialog(typeAudios);
                        break;
                      case typePositions:
                        _showProjectDialog(typePositions);
                        break;
                      case typePolygons:
                        _showProjectDialog(typePolygons);
                        break;
                      case typeSchedules:
                        _showProjectDialog(typeSchedules);
                        break;
                    }
                  },
                ),
              ),
              GeoActivity(width: size.width/2,),

            ],
          )
        ],
      ),
    ));
  }
}
