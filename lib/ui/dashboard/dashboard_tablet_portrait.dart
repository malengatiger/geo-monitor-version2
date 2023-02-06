import 'dart:async';

import 'package:animations/animations.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geo_monitor/library/users/full_user_photo.dart';
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
import '../intro/intro_page_viewer.dart';

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

  static const mm = '🎽🎽🎽🎽🎽🎽 DashboardTabletPortrait: 🎽';
  bool networkAvailable = false;
  final dur = 300;

  @override
  void initState() {
    _setAnimationControllers();
    super.initState();
    _setItems();
    _listenToOrgStreams();
    _listenForFCM();
    _getAuthenticationStatus();

    if (widget.user == null) {
      _refreshData(true);
    } else {
      _refreshData(false);
    }
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

  // late StreamSubscription<>
  late StreamSubscription<List<Project>> projectSubscription;
  late StreamSubscription<List<User>> userSubscription;
  late StreamSubscription<List<Photo>> photoSubscription;
  late StreamSubscription<List<Video>> videoSubscription;
  late StreamSubscription<List<Audio>> audioSubscription;
  late StreamSubscription<List<ProjectPosition>> projectPositionSubscription;
  late StreamSubscription<List<ProjectPolygon>> projectPolygonSubscription;
  late StreamSubscription<List<FieldMonitorSchedule>> schedulesSubscription;

  late StreamSubscription<Photo> photoSubscriptionFCM;
  late StreamSubscription<Video> videoSubscriptionFCM;
  late StreamSubscription<Audio> audioSubscriptionFCM;
  late StreamSubscription<ProjectPosition> projectPositionSubscriptionFCM;
  late StreamSubscription<ProjectPolygon> projectPolygonSubscriptionFCM;
  late StreamSubscription<Project> projectSubscriptionFCM;
  late StreamSubscription<User> userSubscriptionFCM;
  late StreamSubscription<SettingsModel> settingsSubscriptionFCM;

  late StreamSubscription<String> killSubscriptionFCM;

  void _listenToOrgStreams() async {
    projectSubscription = organizationBloc.projectStream.listen((event) {
      _projects = event;
      pp('$mm attempting to set state after projects delivered by stream: ${_projects.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
        _projectAnimationController.forward();
      }
    });
    userSubscription = organizationBloc.usersStream.listen((event) {
      _users = event;
      pp('$mm attempting to set state after users delivered by stream: ${_users.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
        _userAnimationController.forward();
      }
    });
    photoSubscription = organizationBloc.photoStream.listen((event) {
      _photos = event;
      pp('$mm attempting to set state after photos delivered by stream: ${_photos.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
      }
      _photoAnimationController.forward();
    });

    videoSubscription = organizationBloc.videoStream.listen((event) {
      _videos = event;
      pp('$mm attempting to set state after videos delivered by stream: ${_videos.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
        _videoAnimationController.forward();
      }
    });
    audioSubscription = organizationBloc.audioStream.listen((event) {
      _audios = event;
      pp('$mm attempting to set state after audios delivered by stream: ${_audios.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
        _audioAnimationController.forward();
      }
    });
    projectPositionSubscription =
        organizationBloc.projectPositionsStream.listen((event) {
      _projectPositions = event;
      pp('$mm attempting to set state after projectPositions delivered by stream: ${_projectPositions.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
        _projectAnimationController.forward();
      }
    });
    projectPolygonSubscription =
        organizationBloc.projectPolygonsStream.listen((event) {
      _projectPolygons = event;
      pp('$mm attempting to set state after projectPolygons delivered by stream: ${_projectPolygons.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
        _projectAnimationController.forward();
      }
    });

    schedulesSubscription =
        organizationBloc.fieldMonitorScheduleStream.listen((event) {
      _schedules = event;
      pp('$mm attempting to set state after schedules delivered by stream: ${_schedules.length} ... mounted: $mounted');

      if (mounted) {
        setState(() {});
        _projectAnimationController.forward();
      }
    });
  }

  void _startTimer() async {
    Future.delayed(const Duration(seconds: 5), () {
      Timer.periodic(const Duration(minutes: 30), (timer) async {
        pp('$mm ........ set state timer tick: ${timer.tick}');
        try {
          _refreshData(false);
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
    projectPolygonSubscription.cancel();
    projectPositionSubscription.cancel();
    projectSubscription.cancel();
    photoSubscription.cancel();
    videoSubscription.cancel();
    userSubscription.cancel();
    audioSubscription.cancel();
    projectPolygonSubscriptionFCM.cancel();
    projectPositionSubscriptionFCM.cancel();
    projectSubscriptionFCM.cancel();
    photoSubscriptionFCM.cancel();
    videoSubscriptionFCM.cancel();
    userSubscriptionFCM.cancel();
    audioSubscriptionFCM.cancel();
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

  void _refreshData(bool forceRefresh) async {
    pp('$mm ............................................Refreshing data ....');
    user = await prefsOGx.getUser();
    if (user != null) {
      if (user!.userType == UserType.orgAdministrator) {
        type = 'Administrator';
      }
      if (user!.userType == UserType.orgExecutive) {
        type = 'Executive';
      }
      if (user!.userType == UserType.fieldMonitor) {
        type = 'Field Monitor';
      }
    } else {
      throw Exception('No user cached on device');
    }

    if (mounted) {
      setState(() {
        busy = true;
      });
    }
    await _doTheWork(forceRefresh);
  }

  Future<void> _doTheWork(bool forceRefresh) async {
    try {
      if (user == null) {
        throw Exception("Tax man is fucked! User is not found");
      }

      var bag = await organizationBloc.getOrganizationData(
          organizationId: user!.organizationId!, forceRefresh: forceRefresh);
      await _extractData(bag);
      setState(() {});
    } catch (e) {
      pp('$mm $e - will show snackbar ..');
      showConnectionProblemSnackBar(
          context: context,
          message: 'Data refresh failed. Possible network problem - $e');
    }
    setState(() {
      busy = false;
    });

    _projectAnimationController.reset();
    _userAnimationController.reset();
    _photoAnimationController.reset();
    _videoAnimationController.reset();
    _positionAnimationController.reset();
    _polygonAnimationController.reset();
    _audioAnimationController.reset();

    _projectAnimationController.forward().then((value) {
      _userAnimationController.forward().then((value) {
        _photoAnimationController.forward().then((value) {
          _videoAnimationController.forward().then((value) {
            _positionAnimationController.forward().then((value) {
              _polygonAnimationController.forward().then((value) {
                _audioAnimationController.forward();
              });
            });
          });
        });
      });
    });
  }

  Future _extractData(DataBag bag) async {
    pp('$mm ............ Extracting org data from bag');
    _projects = bag.projects!;
    _projectPositions = bag.projectPositions!;
    _projectPolygons = bag.projectPolygons!;
    _users = bag.users!;
    _photos = bag.photos!;
    _videos = bag.videos!;
    _schedules = bag.fieldMonitorSchedules!;
    _audios = bag.audios!;

    pp('$mm ..... setting state after extracting org data from bag');
    setState(() {});
  }

  void _listenForFCM() async {
    var android = UniversalPlatform.isAndroid;
    var ios = UniversalPlatform.isIOS;
    await fcmBloc.initialize();
    pp('$mm 🍎 🍎 🍎 🍎 FCM should be initialized!!  ... 🍎 🍎');
    if (android || ios) {
      pp('$mm 🍎 🍎 _listen to FCM message streams ... 🍎 🍎');
      projectSubscriptionFCM =
          fcmBloc.projectStream.listen((Project project) async {
        if (mounted) {
          pp('$mm: 🍎 🍎 projects arrived: ${project.name} ... 🍎 🍎');
          _projects = await organizationBloc.getOrganizationProjects(
              organizationId: user!.organizationId!, forceRefresh: false);
          setState(() {});
        }
      });
      if (mounted) {
        killSubscriptionFCM = listenForKill(context: context);
      }

      settingsSubscriptionFCM = fcmBloc.settingsStream.listen((settings) async {
        pp('$mm: 🍎🍎 settings arrived with themeIndex: ${settings.themeIndex}... 🍎🍎');
        themeBloc.themeStreamController.sink.add(settings.themeIndex!);
        if (mounted) {
          setState(() {});
        }
      });
      userSubscriptionFCM = fcmBloc.userStream.listen((user) async {
        pp('$mm: 🍎 🍎 user arrived... 🍎 🍎');

        if (mounted) {
          _users = await organizationBloc.getUsers(
              organizationId: user.organizationId!, forceRefresh: false);
          setState(() {});
        }
      });
      photoSubscriptionFCM = fcmBloc.photoStream.listen((user) async {
        pp('$mm: 🍎 🍎 photoSubscriptionFCM photo arrived... 🍎 🍎');
        if (mounted) {
          _photos = await organizationBloc.getPhotos(
              organizationId: user.organizationId!, forceRefresh: false);
          setState(() {});
        }
      });

      videoSubscriptionFCM = fcmBloc.videoStream.listen((Video message) async {
        pp('$mm: 🍎 🍎 videoSubscriptionFCM video arrived... 🍎 🍎');
        if (mounted) {
          pp('DashboardMobile: 🍎 🍎 showMessageSnackbar: ${message.projectName} ... 🍎 🍎');
          _videos = await organizationBloc.getVideos(
              organizationId: user!.organizationId!, forceRefresh: false);
          setState(() {});
        }
      });
      audioSubscriptionFCM = fcmBloc.audioStream.listen((Audio message) async {
        pp('$mm: 🍎 🍎 audioSubscriptionFCM audio arrived... 🍎 🍎');
        if (mounted) {
          _refreshData(false);
        }
      });
      projectPositionSubscriptionFCM =
          fcmBloc.projectPositionStream.listen((ProjectPosition message) async {
        pp('$mm: 🍎 🍎 projectPositionSubscriptionFCM position arrived... 🍎 🍎');
        if (mounted) {
          _refreshData(false);
        }
      });
      projectPolygonSubscriptionFCM =
          fcmBloc.projectPolygonStream.listen((ProjectPolygon message) async {
        pp('$mm: 🍎 🍎 projectPolygonSubscriptionFCM polygon arrived... 🍎 🍎');
        if (mounted) {
          _refreshData(false);
        }
      });
    } else {
      pp('App is running on the Web 👿👿👿firebase messaging is OFF 👿👿👿');
    }
  }

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

  static const typeVideo = 0,
      typeAudio = 1,
      typePhoto = 2,
      typePositions = 3,
      typePolygons = 4,
      typeSchedules = 5;

  void _showProjectDialog(int destination) {
    late String title;
    switch (destination) {
      case typePhoto:
        title = 'Photos';
        break;
      case typeVideo:
        title = 'Videos';
        break;
      case typeAudio:
        title = 'Audio';
        break;
      case typePositions:
        title = 'Map';
        break;
      case typePolygons:
        title = 'Map';
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
      case typeVideo:
        _navigateToProjectMedia(p1);
        break;
      case typeAudio:
        _navigateToProjectMedia(p1);
        break;
      case typePhoto:
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
    var style = GoogleFonts.secularOne(
        textStyle: Theme.of(context).textTheme.titleLarge,
        fontWeight: FontWeight.w900);
    var stylePrimary = GoogleFonts.secularOne(
        textStyle: Theme.of(context).textTheme.titleLarge,
        fontWeight: FontWeight.w900,
        color: Theme.of(context).primaryColor);
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
                SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 100, child: Headline(user: widget.user)),
                      SizedBox(height: 800,
                        child: Padding(
                          padding: const EdgeInsets.all(72.0),
                          child: GridView.count(
                            crossAxisCount: 3,
                            children: [
                              GestureDetector(
                                onTap: _navigateToProjectList,
                                child: AnimatedBuilder(
                                  animation: _projectAnimationController,
                                  builder: (BuildContext context, Widget? child) {
                                    return FadeScaleTransition(
                                      animation: _projectAnimationController,
                                      child: child,
                                    );
                                  },
                                  child: Card(
                                    // color: Colors.brown[50],
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16.0)),
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 80,
                                        ),
                                        Text('${_projects.length}', style: style),
                                        const SizedBox(
                                          height: 8,
                                        ),
                                        Text(
                                          'Projects',
                                          style: Styles.greyLabelSmall,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _navigateToUserList,
                                child: AnimatedBuilder(
                                  animation: _userAnimationController,
                                  builder: (BuildContext context, Widget? child) {
                                    return FadeScaleTransition(
                                      animation: _userAnimationController,
                                      child: child,
                                    );
                                  },
                                  child: Card(
                                    // color: Colors.brown[50],
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16.0)),
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 80,
                                        ),
                                        Text(
                                          '${_users.length}',
                                          style: style,
                                        ),
                                        const SizedBox(
                                          height: 8,
                                        ),
                                        Text(
                                          'Members',
                                          style: Styles.greyLabelSmall,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _photoAnimationController,
                                builder: (BuildContext context, Widget? child) {
                                  return FadeScaleTransition(
                                    animation: _photoAnimationController,
                                    child: child,
                                  );
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    _showProjectDialog(typePhoto);
                                  },
                                  child: Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16.0)),
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 80,
                                        ),
                                        Text('${_photos.length}',
                                            style: stylePrimary),
                                        const SizedBox(
                                          height: 8,
                                        ),
                                        Text(
                                          'Photos',
                                          style: Styles.greyLabelSmall,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _videoAnimationController,
                                builder: (BuildContext context, Widget? child) {
                                  return FadeScaleTransition(
                                    animation: _videoAnimationController,
                                    child: child,
                                  );
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    _showProjectDialog(typeVideo);
                                  },
                                  child: Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16.0)),
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 80,
                                        ),
                                        Text('${_videos.length}', style: style),
                                        const SizedBox(
                                          height: 8,
                                        ),
                                        Text(
                                          'Videos',
                                          style: Styles.greyLabelSmall,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _audioAnimationController,
                                builder: (BuildContext context, Widget? child) {
                                  return FadeScaleTransition(
                                    animation: _audioAnimationController,
                                    child: child,
                                  );
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    _showProjectDialog(typeAudio);
                                  },
                                  child: Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16.0)),
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 80,
                                        ),
                                        Text('${_audios.length}', style: style),
                                        const SizedBox(
                                          height: 8,
                                        ),
                                        Text(
                                          'Audio Clips',
                                          style: Styles.greyLabelSmall,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _positionAnimationController,
                                builder: (BuildContext context, Widget? child) {
                                  return FadeScaleTransition(
                                    animation: _positionAnimationController,
                                    child: child,
                                  );
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    _showProjectDialog(typePositions);
                                  },
                                  child: Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16.0)),
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 80,
                                        ),
                                        Text('${_projectPositions.length}',
                                            style: style),
                                        const SizedBox(
                                          height: 8,
                                        ),
                                        Text(
                                          'Locations',
                                          style: Styles.greyLabelSmall,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _polygonAnimationController,
                                builder: (BuildContext context, Widget? child) {
                                  return FadeScaleTransition(
                                    animation: _polygonAnimationController,
                                    child: child,
                                  );
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    _showProjectDialog(typePolygons);
                                  },
                                  child: Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16.0)),
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 80,
                                        ),
                                        Text('${_projectPolygons.length}',
                                            style: style),
                                        const SizedBox(
                                          height: 8,
                                        ),
                                        Text(
                                          'Areas',
                                          style: Styles.greyLabelSmall,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _polygonAnimationController,
                                builder: (BuildContext context, Widget? child) {
                                  return FadeScaleTransition(
                                    animation: _polygonAnimationController,
                                    child: child,
                                  );
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    _showProjectDialog(typeSchedules);
                                  },
                                  child: Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16.0)),
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 80,
                                        ),
                                        Text('${_schedules.length}',
                                            style: style),
                                        const SizedBox(
                                          height: 8,
                                        ),
                                        Text(
                                          'Schedules',
                                          style: Styles.greyLabelSmall,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
