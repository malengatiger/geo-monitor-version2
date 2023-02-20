import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geo_monitor/library/data/geofence_event.dart';
import 'package:geo_monitor/library/data/settings_model.dart';
import 'package:geo_monitor/library/ui/maps/project_map_mobile.dart';
import 'package:geo_monitor/library/ui/media/list/project_media_list_mobile.dart';
import 'package:geo_monitor/ui/activity/activity_list_mobile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../library/api/prefs_og.dart';
import '../../library/bloc/connection_check.dart';
import '../../library/bloc/fcm_bloc.dart';
import '../../library/bloc/organization_bloc.dart';
import '../../library/bloc/project_bloc.dart';
import '../../library/bloc/theme_bloc.dart';
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
import '../../library/ui/media/user_media_list/user_media_list_mobile.dart';
import '../../library/ui/message/message_main.dart';
import '../../library/ui/project_list/project_list_mobile.dart';
import '../../library/ui/settings/settings_mobile.dart';
import '../intro/intro_page_viewer_portrait.dart';
import 'dashboard_portrait.dart';

class ProjectDashboardMobile extends StatefulWidget {
  const ProjectDashboardMobile({
    Key? key,
    this.user,
    required this.project,
  }) : super(key: key);
  final Project project;
  final User? user;
  @override
  ProjectDashboardMobileState createState() => ProjectDashboardMobileState();
}

class ProjectDashboardMobileState extends State<ProjectDashboardMobile>
    with TickerProviderStateMixin {
  late AnimationController _gridViewAnimationController;

  var busy = false;
  var _projects = <Project>[];
  var _users = <User>[];
  var _photos = <Photo>[];
  var _videos = <Video>[];
  var _projectPositions = <ProjectPosition>[];
  var _projectPolygons = <ProjectPolygon>[];
  var _schedules = <FieldMonitorSchedule>[];
  var _audios = <Audio>[];
  final _settings = <SettingsModel>[];
  User? user;

  static const mm = '🎽🎽🎽🎽🎽🎽 ProjectDashboardMobile: 🎽';
  bool networkAvailable = false;
  final dur = 600;

  @override
  void initState() {
    _gridViewAnimationController = AnimationController(
        duration: const Duration(milliseconds: 3000),
        reverseDuration: const Duration(milliseconds: 3000),
        vsync: this);

    super.initState();
    _setItems();
    _listenToStreams();
    _listenForFCM();

    if (widget.user != null) {
      _refreshData(true);
    } else {
      _refreshData(false);
    }
  }

  final fb.FirebaseAuth firebaseAuth = fb.FirebaseAuth.instance;
  bool authed = false;

  void _listenToStreams() async {
    var user = await prefsOGx.getUser();
    if (user == null) return;
    switch (user.userType) {
      case UserType.orgExecutive:
        _listenToOrgStreams();
        break;
      case UserType.orgAdministrator:
        _listenToOrgStreams();
        break;
      case UserType.fieldMonitor:
        _listenToMonitorStreams();
        break;
    }
  }

  late StreamSubscription<GeofenceEvent> geofenceSubscription;

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
        _gridViewAnimationController.forward();
      }
    });
    userSubscription = organizationBloc.usersStream.listen((event) {
      _users = event;
      pp('$mm attempting to set state after users delivered by stream: ${_users.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
      }
    });
    photoSubscription = organizationBloc.photoStream.listen((event) {
      _photos = event;
      pp('$mm attempting to set state after photos delivered by stream: ${_photos.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
      }
    });

    videoSubscription = organizationBloc.videoStream.listen((event) {
      _videos = event;
      pp('$mm attempting to set state after videos delivered by stream: ${_videos.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
      }
    });
    audioSubscription = organizationBloc.audioStream.listen((event) {
      _audios = event;
      pp('$mm attempting to set state after audios delivered by stream: ${_audios.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
      }
    });
    projectPositionSubscription =
        organizationBloc.projectPositionsStream.listen((event) {
      _projectPositions = event;
      pp('$mm attempting to set state after projectPositions delivered by stream: ${_projectPositions.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
        _gridViewAnimationController.forward();
      }
    });
    projectPolygonSubscription =
        organizationBloc.projectPolygonsStream.listen((event) {
      _projectPolygons = event;
      pp('$mm attempting to set state after projectPolygons delivered by stream: ${_projectPolygons.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
        _gridViewAnimationController.forward();
      }
    });

    schedulesSubscription =
        organizationBloc.fieldMonitorScheduleStream.listen((event) {
      _schedules = event;
      pp('$mm attempting to set state after schedules delivered by stream: ${_schedules.length} ... mounted: $mounted');

      if (mounted) {
        setState(() {});
        // _controller.reset();
        _gridViewAnimationController.forward();
      }
    });
  }

  void _listenToMonitorStreams() async {
    projectSubscription = organizationBloc.projectStream.listen((event) {
      _projects = event;
      pp('$mm attempting to set state after projects delivered by stream: ${_projects.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
        _gridViewAnimationController.forward();
      }
    });
    userSubscription = organizationBloc.usersStream.listen((event) {
      _users = event;
      pp('$mm attempting to set state after users delivered by stream: ${_users.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
      }
    });
    photoSubscription = organizationBloc.photoStream.listen((event) {
      pp('$mm attempting to set state after photos delivered by stream: ${_photos.length} ... mounted: $mounted');
      _photos = event;
      if (mounted) {
        setState(() {});
      }
    });

    videoSubscription = organizationBloc.videoStream.listen((event) {
      _videos = event;
      pp('$mm attempting to set state after videos delivered by stream: ${_videos.length} ... mounted: $mounted');

      if (mounted) {
        setState(() {});
      }
    });
    audioSubscription = organizationBloc.audioStream.listen((event) {
      _audios = event;
      pp('$mm attempting to set state after audios delivered by stream: ${_audios.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
      }
    });
    projectPositionSubscription =
        organizationBloc.projectPositionsStream.listen((event) {
      _projectPositions = event;
      pp('$mm attempting to set state after project positions delivered by stream: ${_projectPositions.length} ... mounted: $mounted');

      if (mounted) {
        setState(() {});
      }
    });
    schedulesSubscription =
        organizationBloc.fieldMonitorScheduleStream.listen((event) {
      _schedules = event;
      pp('$mm attempting to set state after fieldMonitorSchedules delivered by stream: ${_schedules.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _gridViewAnimationController.dispose();

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
    // items
    //     .add(BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'));

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
      var bag = await projectBloc.getProjectData(
          projectId: widget.project.projectId!, forceRefresh: forceRefresh);
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

      photoSubscriptionFCM = fcmBloc.photoStream.listen((user) async {
        pp('$mm: 🍎 🍎 photoSubscriptionFCM photo arrived... 🍎 🍎');
        if (mounted) {
          _photos = await projectBloc.getPhotos(
              projectId: user.projectId!, forceRefresh: false);
          setState(() {});
        }
      });

      videoSubscriptionFCM = fcmBloc.videoStream.listen((Video message) async {
        pp('$mm: 🍎 🍎 videoSubscriptionFCM video arrived... 🍎 🍎');
        if (mounted) {
          pp('ProjectDashboardMobile: 🍎 🍎 showMessageSnackbar: ${message.projectName} ... 🍎 🍎');
          _videos = await projectBloc.getProjectVideos(
              projectId: message.projectId!, forceRefresh: false);
        }
      });
      audioSubscriptionFCM = fcmBloc.audioStream.listen((Audio message) async {
        pp('$mm: 🍎 🍎 audioSubscriptionFCM audio arrived... 🍎 🍎');
        if (mounted) {
          _audios = await projectBloc.getProjectAudios(
              projectId: message.projectId!, forceRefresh: false);
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
        pp(' 🔆🔆🔆 Navigate to ProjectList');
        _navigateToProjectList();
        break;

      case 1:
        pp(' 🔆🔆🔆 Navigate to UserMediaList');
        _navigateToUserMediaList();
        break;

      case 2:
        pp(' 🔆🔆🔆 Navigate to MessageSender');
        _navigateToMessageSender();
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
            child: MessageMain(user: user)));
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

  void _navigateToSettings() {
    pp('$mm .................. _navigateToIntro to Settings ....');
    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.leftToRight,
              alignment: Alignment.center,
              duration: const Duration(seconds: 1),
              child: const SettingsMobile()));
    }
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

  void _navigateToActivity() {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.fade,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: ActivityListMobile(
              project: widget.project,
              onPhotoTapped: (photo) {},
              onVideoTapped: (video) {},
              onAudioTapped: (audio) {},
              onUserTapped: (user) {},
              onProjectTapped: (project) {},
              onProjectPositionTapped: (projectPosition) {},
              onPolygonTapped: (projectPolygon) {},
              onGeofenceEventTapped: (geofenceEvent) {},
              onOrgMessage: (orgMessage) {},
            )));
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

  static const typeVideo = 0,
      typeAudio = 1,
      typePhoto = 2,
      typePositions = 3,
      typePolygons = 4,
      typeSchedules = 5;

  // bool _showProjectChooser = false;
  // bool _showProjectSelected = false;

  Project? selectedProject;

  @override
  Widget build(BuildContext context) {
    var style = GoogleFonts.secularOne(
        textStyle: Theme.of(context).textTheme.titleLarge,
        fontWeight: FontWeight.w900,
        color: Theme.of(context).primaryColor);
    return SafeArea(
      child: Scaffold(
        key: _key,
        appBar: AppBar(
          title: Text(
            'Project Dashboard',
            style: myTextStyleMedium(context),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.access_alarm,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                _navigateToActivity();
              },
            ),
            IconButton(
              icon: Icon(
                Icons.refresh,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                _refreshData(true);
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const SizedBox(
                    height: 12,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                      ),
                      Flexible(
                        child: Text(
                          widget.project.name!,
                          style: GoogleFonts.lato(
                              textStyle: Theme.of(context).textTheme.titleLarge,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                ],
              ),
            ),
          ),
        ),
        // backgroundColor: Colors.brown[100],
        bottomNavigationBar: BottomNavigationBar(
          items: items,
          onTap: _handleBottomNav,
          elevation: 8,
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
                    child: GridView.count(
                      crossAxisCount: 2,
                      children: [
                        GestureDetector(
                          onTap: () {
                            _navigateToProjectMedia(widget.project);
                          },
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0)),
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 32,
                                ),
                                Text('${_photos.length}', style: style),
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
                        GestureDetector(
                          onTap: () {
                            _navigateToProjectMedia(widget.project);
                          },
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0)),
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 32,
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
                        GestureDetector(
                          onTap: () {
                            _navigateToProjectMedia(widget.project);
                          },
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0)),
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 32,
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
                        GestureDetector(
                          onTap: () {
                            _navigateToProjectMap(widget.project);
                          },
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0)),
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 32,
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
                        GestureDetector(
                          onTap: () {
                            _navigateToProjectMap(widget.project);
                          },
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0)),
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 32,
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
                        GestureDetector(
                          onTap: () {},
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0)),
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 32,
                                ),
                                Text('${_schedules.length}', style: style),
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
                      ],
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
