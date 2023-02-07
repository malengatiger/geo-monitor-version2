import 'dart:async';

import 'package:animations/animations.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geo_monitor/library/bloc/downloader.dart';
import 'package:geo_monitor/library/users/full_user_photo.dart';
import 'package:geo_monitor/ui/dashboard/dashboard_grid.dart';
import 'package:geofence_service/geofence_service.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../library/api/prefs_og.dart';
import '../../library/bloc/connection_check.dart';
import '../../library/bloc/fcm_bloc.dart';
import '../../library/bloc/organization_bloc.dart';
import '../../library/bloc/theme_bloc.dart';
import '../../library/bloc/uploader.dart';
import '../../library/data/audio.dart';
import '../../library/data/data_bag.dart';
import '../../library/data/field_monitor_schedule.dart';
import '../../library/data/geofence_event.dart';
import '../../library/data/photo.dart';
import '../../library/data/project.dart';
import '../../library/data/project_polygon.dart';
import '../../library/data/project_position.dart';
import '../../library/data/settings_model.dart';
import '../../library/data/user.dart';
import '../../library/data/video.dart';
import '../../library/emojis.dart';
import '../../library/functions.dart';
import '../../library/geofence/geofencer_two.dart';
import '../../library/ui/maps/project_map_mobile.dart';
import '../../library/ui/media/list/project_media_list_mobile.dart';
import '../../library/ui/media/user_media_list/user_media_list_mobile.dart';
import '../../library/ui/project_list/project_chooser.dart';
import '../../library/ui/project_list/project_list_mobile.dart';
import '../../library/ui/settings.dart';
import '../../library/ui/weather/daily_forecast_page.dart';
import '../../library/users/list/user_list_main.dart';
import '../chat/chat_page.dart';
import '../intro/intro_page_viewer_portrait.dart';

class DashboardTabletPortrait extends StatefulWidget {
  const DashboardTabletPortrait({
    Key? key,
    required this.user,
  }) : super(key: key);
  final User user;
  @override
  DashboardTabletPortraitState createState() => DashboardTabletPortraitState();
}

class DashboardTabletPortraitState extends State<DashboardTabletPortrait>
    with TickerProviderStateMixin {
  late AnimationController _projectAnimationController;
  late AnimationController _userAnimationController;
  late AnimationController _photoAnimationController;
  late AnimationController _videoAnimationController;
  late AnimationController _positionAnimationController;
  late AnimationController _polygonAnimationController;
  late AnimationController _audioAnimationController;

  // var busy = false;
  // var _projects = <Project>[];
  // var _users = <User>[];
  // var _photos = <Photo>[];
  // var _videos = <Video>[];
  // var _projectPositions = <ProjectPosition>[];
  // var _projectPolygons = <ProjectPolygon>[];
  // var _schedules = <FieldMonitorSchedule>[];
  // var _audios = <Audio>[];
  User? user;

  static const mm = '🎽🎽🎽🎽🎽🎽 DashboardTabletPortrait: 🎽';
  bool networkAvailable = false;
  final dur = 300;

  @override
  void initState() {
    _setAnimationControllers();
    super.initState();
    _setItems();
    _getAuthenticationStatus();
    _subscribeToConnectivity();
    _subscribeToGeofenceStream();
    _buildGeofences();
    _startTimer();

    uploader.startTimer(const Duration(seconds: 60));
  }

  void _setAnimationControllers() {
    _projectAnimationController = AnimationController(
        duration: Duration(milliseconds: dur),
        reverseDuration: Duration(milliseconds: dur),
        vsync: this);
    _audioAnimationController = AnimationController(
        duration: Duration(milliseconds: dur),
        reverseDuration: Duration(milliseconds: dur),
        vsync: this);
    _userAnimationController = AnimationController(
        duration: Duration(milliseconds: dur),
        reverseDuration: Duration(milliseconds: dur),
        vsync: this);
    _photoAnimationController = AnimationController(
        duration: Duration(milliseconds: dur),
        reverseDuration: Duration(milliseconds: dur),
        vsync: this);
    _videoAnimationController = AnimationController(
        duration: Duration(milliseconds: dur),
        reverseDuration: Duration(milliseconds: dur),
        vsync: this);
    _polygonAnimationController = AnimationController(
        duration: Duration(milliseconds: dur),
        reverseDuration: Duration(milliseconds: dur),
        vsync: this);
    _positionAnimationController = AnimationController(
        duration: Duration(milliseconds: dur),
        reverseDuration: Duration(milliseconds: dur),
        vsync: this);
  }

  final fb.FirebaseAuth firebaseAuth = fb.FirebaseAuth.instance;
  bool authed = false;

  void _getAuthenticationStatus() async {
    var cUser = firebaseAuth.currentUser;
    if (cUser == null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _navigateToIntro();
      });
      //
    }
  }

  void _buildGeofences() async {
    pp('\n$mm _buildGeofences starting ........................');
    await theGreatGeofencer.buildGeofences();
    pp('$mm _buildGeofences should be done and dusted ....');
  }

  late StreamSubscription<bool> connectionSubscription;
  Future<void> _subscribeToConnectivity() async {
    connectionSubscription =
        connectionCheck.connectivityStream.listen((bool connected) {
      if (connected) {
        pp('$mm We have a connection! - $connected');
      } else {
        pp('$mm We DO NOT have a connection! - show snackbar ...  🍎 mounted? $mounted');
        if (mounted) {
          //showConnectionProblemSnackBar(context: context);
        }
      }
    });
    var isConnected = await connectionCheck.internetAvailable();
    pp('$mm Are we connected? answer: $isConnected');
  }

  late StreamSubscription<GeofenceEvent> geofenceSubscription;

  void _subscribeToGeofenceStream() async {
    geofenceSubscription =
        theGreatGeofencer.geofenceEventStream.listen((event) {
      pp('\n$mm geofenceEvent delivered by geofenceStream: ${event.projectName} ...');
      // if (mounted) {
      //   showToast(
      //       message:
      //           'Geofence triggered for ${event.projectName}',
      //       context: context);
      // }
    });
  }

  void _startTimer() async {
    Future.delayed(const Duration(seconds: 5), () {
      Timer.periodic(const Duration(minutes: 30), (timer) async {
        pp('$mm ........ set state timer tick: ${timer.tick}');
        try {
          //_refreshData(false);
        } catch (e) {
          //ignore
        }
      });
    });
  }

  @override
  void dispose() {
    _projectAnimationController.dispose();
    _audioAnimationController.dispose();
    _photoAnimationController.dispose();
    _videoAnimationController.dispose();
    _userAnimationController.dispose();
    _polygonAnimationController.dispose();
    _positionAnimationController.dispose();
    connectionSubscription.cancel();

    geofenceSubscription.cancel();
    super.dispose();
  }

  var items = <BottomNavigationBarItem>[];

  void _setItems() {
    items.add(const BottomNavigationBarItem(
        icon: Icon(
          Icons.person,
          color: Colors.pink,
        ),
        label: 'My Work'));

    items.add(const BottomNavigationBarItem(
        icon: Icon(
          Icons.send,
          color: Colors.blue,
        ),
        label: 'Send Message'));

    items.add(const BottomNavigationBarItem(
        icon: Icon(
          Icons.radar,
          color: Colors.teal,
        ),
        label: 'Weather'));
  }

  String type = 'Unknown Rider';


  final _key = GlobalKey<ScaffoldState>();

  void _handleBottomNav(int value) {
    switch (value) {
      case 0:
        pp('$mm 🔆🔆🔆 Navigate to UserMediaList');
        _navigateToUserMediaList();
        break;

      case 1:
        pp('$mm 🔆🔆🔆 Navigate to MessageSender');
        _navigateToMessageSender();
        break;
      case 2:
        pp('$mm 🔆🔆🔆 Navigate to Weather');
        _navigateToDailyForecast();
        break;
    }
  }

  int instruction = stayOnList;
  void _navigateToProjectList() {
    if (selectedProject != null) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(seconds: 1),
              child: ProjectListMobile(
                instruction: instruction,
                project: selectedProject,
              )));
      selectedProject = null;
    } else {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(seconds: 1),
              child: ProjectListMobile(
                instruction: instruction,
              )));
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

  void _navigateToUserMediaList() async {
    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(seconds: 1),
              child: UserMediaListMobile(user: user!)));
    }
  }

  void _navigateToIntro() {
    pp('$mm .................. _navigateToIntro to Intro ....');
    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(seconds: 1),
              child: const IntroPageViewerPortrait()));
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
    pp('$mm .................. _navigateToIntro to Settings ....');
    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.rotate,
              alignment: Alignment.center,
              duration: const Duration(seconds: 1),
              child: const Settings()));
    }
  }

  void _navigateToUserList() {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: const UserListMain()));
  }

  void _navigateToProjectMedia(Project project) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: ProjectMediaListMobile(project: project)));
  }

  void _navigateToProjectMap(Project project) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: ProjectMapMobile(project: project)));
  }

  void _navigateToDailyForecast() {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: const DailyForecastPage()));
  }

  void _showProjectDialog(int destination) {
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

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Dashboard'),
      // ),
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
                DashboardGrid(onTypeTapped: (type) {
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
                  }
                }),
              ],
            ),
    );
  }
}
///////

class DashboardTabletLandscape extends StatefulWidget {
  const DashboardTabletLandscape({Key? key, required this.user})
      : super(key: key);

  final User user;
  @override
  State<DashboardTabletLandscape> createState() =>
      _DashboardTabletLandscapeState();
}

class _DashboardTabletLandscapeState extends State<DashboardTabletLandscape> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Geo Dashboard'),
      ),
      body: Stack(
        children: [
          Row(
            children: [
              SizedBox(width: 600,
                child: DashboardTabletPortrait(
                  user: widget.user,
                ),
              ),
              const SizedBox(
                width: 24,
              ),
              Container(
                color: Colors.teal,
                width: 400,
              ),
            ],
          )
        ],
      ),
    ));
  }
}

class Headline extends StatelessWidget {
  const Headline({Key? key, required this.user}) : super(key: key);
  final User user;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Column(
        children: [
          const SizedBox(
            height: 12,
          ),
          Text(
            '${user.organizationName}',
            style: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.bodyLarge,
                fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor,
              fontSize: 24
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            '${user.name}',
            style: myTextStyleLarge(context),
          ),
          const SizedBox(
            height: 0,
          ),
        ],
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

StreamSubscription<String> listenForKill({required BuildContext context}) {
  pp('\n$mm Kill message; listen for KILL message ...... 🍎🍎🍎🍎 ......');

  var sub = fcmBloc.killStream.listen((event) {
    pp('$mm Kill message arrived: 🍎🍎🍎🍎 $event 🍎🍎🍎🍎');
    try {
      showKillDialog(message: event, context: context);
    } catch (e) {
      pp(e);
    }
  });

  return sub;
}
