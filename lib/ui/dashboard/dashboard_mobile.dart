import 'dart:async';

import 'package:animations/animations.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/connection_check.dart';
import 'package:geo_monitor/library/data/audio.dart';
import 'package:geo_monitor/library/data/data_bag.dart';
import 'package:geo_monitor/library/data/project_polygon.dart';
import 'package:geo_monitor/library/ui/maps/project_map_mobile.dart';
import 'package:geo_monitor/library/ui/media/list/project_media_list_mobile.dart';
import 'package:geo_monitor/ui/intro_page_viewer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../library/api/sharedprefs.dart';
import '../../library/bloc/fcm_bloc.dart';
import '../../library/bloc/organization_bloc.dart';
import '../../library/bloc/theme_bloc.dart';
import '../../library/data/field_monitor_schedule.dart';
import '../../library/data/org_message.dart';
import '../../library/data/photo.dart';
import '../../library/data/project.dart';
import '../../library/data/project_position.dart';
import '../../library/data/user.dart';
import '../../library/data/video.dart';
import '../../library/functions.dart';
import '../../library/generic_functions.dart';
import '../../library/geofence/geofencer_two.dart';
import '../../library/ui/maps/project_polygon_map_mobile.dart';
import '../../library/ui/media/user_media_list/user_media_list_main.dart';
import '../../library/ui/media/user_media_list/user_media_list_mobile.dart';
import '../../library/ui/message/message_main.dart';
import '../../library/ui/project_list/project_chooser.dart';
import '../../library/ui/project_list/project_list_mobile.dart';
import '../../library/users/list/user_list_main.dart';
import '../../main.dart';
import '../intro/intro_mobile.dart';

class DashboardMobile extends StatefulWidget {
  const DashboardMobile({
    Key? key,
    this.user,
  }) : super(key: key);
  final User? user;
  @override
  DashboardMobileState createState() => DashboardMobileState();
}

class DashboardMobileState extends State<DashboardMobile>
    with TickerProviderStateMixin {
  late AnimationController _projectAnimationController;
  late AnimationController _userAnimationController;
  late AnimationController _photoAnimationController;
  late AnimationController _videoAnimationController;
  late AnimationController _positionAnimationController;
  late AnimationController _polygonAnimationController;
  late AnimationController _audioAnimationController;

  var isBusy = false;
  var _projects = <Project>[];
  var _users = <User>[];
  var _photos = <Photo>[];
  var _videos = <Video>[];
  var _projectPositions = <ProjectPosition>[];
  var _projectPolygons = <ProjectPolygon>[];
  var _schedules = <FieldMonitorSchedule>[];
  var _audioss = <Audio>[];
  User? user;

  static const nn = '🎽🎽🎽🎽🎽🎽 DashboardMobile: 🎽';
  static const mm = '🎽🎽🎽🎽🎽🎽 DashboardMobile: 🎽';
  bool networkAvailable = false;
  final dur = 600;
  @override
  void initState() {
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
    super.initState();
    _setItems();
    _listenToStreams();
    _listenForFCM();

    _getAuthenticationStatus();

    if (widget.user != null) {
      _refreshData(true);
    } else {
      _refreshData(false);
    }
    _subscribeToConnectivity();
    _subscribeToGeofenceStream();
    _buildGeofences();
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

  void _listenToStreams() async {
    var user = await Prefs.getUser();
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

  void _buildGeofences() async {
    pp('\n\n$nn _buildGeofences starting ........................');
    await geofencerTwo.buildGeofences();
    pp('$nn _buildGeofences done.\n');
  }

  late StreamSubscription<bool> subscription;

  Future<void> _subscribeToConnectivity() async {
    subscription = connectionCheck.connectivityStream.listen((bool connected) {
      if (connected) {
        pp('$mm We have a connection! - $connected');
      } else {
        pp('$mm We DO NOT have a connection! - show snackbar ...');
        if (mounted) {
          //showConnectionProblemSnackBar(context: context);
        }
      }
    });
    var isConnected = await connectionCheck.internetAvailable();
    pp('$mm Are we connected? answer: $isConnected');
  }

  void _subscribeToGeofenceStream() async {
    geofencerTwo.geofenceStream.listen((event) {
      pp('\n$nn geofenceEvent delivered by geofenceStream: ${event.projectName} ...');
      if (mounted) {
        showToast(
            message:
                'Geofence triggered: ${event.projectName} projectPositionId: ${event.projectPositionId}',
            context: context);
      }
    });
  }

  void _listenToOrgStreams() async {
    organizationBloc.projectStream.listen((event) {
      if (mounted) {
        setState(() {
          _projects = event;
          pp('$nn projects delivered by stream: ${_projects.length} ...');
        });
        _projectAnimationController.forward();
      }
    });
    organizationBloc.usersStream.listen((event) {
      if (mounted) {
        setState(() {
          _users = event;
          pp('$mm users delivered by stream: ${_users.length} ...');
        });
        // _controller.reset();
        _userAnimationController.forward();
      }
    });
    organizationBloc.photoStream.listen((event) {
      if (mounted) {
        setState(() {
          _photos = event;
          pp('$mm photos delivered by stream: ${_photos.length} ...');
        });
      }
      // _controller.reset();
      _photoAnimationController.forward();
    });
    organizationBloc.videoStream.listen((event) {
      if (mounted) {
        setState(() {
          _videos = event;
          pp('$mm videos delivered by stream: ${_videos.length} ...');
        });
        // _controller.reset();
        _videoAnimationController.forward();
      }
    });
    organizationBloc.projectPositionsStream.listen((event) {
      if (mounted) {
        setState(() {
          _projectPositions = event;
          pp('$mm projectPositions delivered by stream: ${_projectPositions.length} ...');
        });
        // _controller.reset();
        _projectAnimationController.forward();
      }
    });
    organizationBloc.fieldMonitorScheduleStream.listen((event) {
      if (mounted) {
        setState(() {
          _schedules = event;
          pp('$mm fieldMonitorSchedules delivered by stream: ${_schedules.length} ...');
        });
        // _controller.reset();
        _projectAnimationController.forward();
      }
    });
  }

  void _listenToMonitorStreams() async {
    organizationBloc.projectStream.listen((event) {
      if (mounted) {
        setState(() {
          _projects = event;
          pp('$nn setting state after projects delivered by stream: ${_projects.length} ...');
        });
        _projectAnimationController.forward();
      }
    });
    organizationBloc.usersStream.listen((event) {
      if (mounted) {
        setState(() {
          _users = event;
          pp('$mm setting state after users delivered by stream: ${_users.length} ...');
        });
        _userAnimationController.forward();
      }
    });
    organizationBloc.photoStream.listen((event) {
      if (mounted) {
        setState(() {
          _photos = event;
          pp('$mm setting state after photos delivered by stream: ${_photos.length} ...');
        });
        _photoAnimationController.forward();
      }
    });
    organizationBloc.videoStream.listen((event) {
      if (mounted) {
        setState(() {
          _videos = event;
          pp('$mm setting state after videos delivered by stream: ${_videos.length} ...');
        });
        _videoAnimationController.forward();
      }
    });
    organizationBloc.projectPositionsStream.listen((event) {
      if (mounted) {
        setState(() {
          _projectPositions = event;
          pp('$mm setting state after projectPositions delivered by stream: ${_projectPositions.length} ...');
        });
      }
    });
    organizationBloc.fieldMonitorScheduleStream.listen((event) {
      if (mounted) {
        setState(() {
          _schedules = event;
          pp('$mm fieldMonitorSchedules delivered by stream: ${_schedules.length} ...');
        });
      }
    });
  }

  @override
  void dispose() {
    _projectAnimationController.dispose();
    subscription.cancel();
    super.dispose();
  }

  var items = <BottomNavigationBarItem>[];

  void _setItems() {
    // items
    //     .add(BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'));
    items.add(const BottomNavigationBarItem(
        icon: Icon(
          Icons.home,
        ),
        label: 'Projects'));
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

  void _refreshData(bool forceRefresh) async {
    pp('$mm ............................................Refreshing data ....');
    setState(() {
      isBusy = true;
    });

    await _doTheWork(forceRefresh);
    setState(() {});
  }

  Future<void> _doTheWork(bool forceRefresh) async {
    try {
      user = await Prefs.getUser();
      var bag = await organizationBloc.getOrganizationData(
          organizationId: user!.organizationId!, forceRefresh: forceRefresh);
      pp('$mm  result: users found ${bag.users!.length}');
      await _extractData(bag);
      setState(() {});
    } catch (e) {
      pp('$mm $e - will show snackbar ..');
      showConnectionProblemSnackBar(
          context: context,
          message: 'Data refresh failed. Possible network problem - $e');
    }
    setState(() {
      isBusy = false;
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
    _audioss = bag.audios!;

    pp('$mm ..... setting state extracting org data from bag');
    setState(() {});
  }

  void _listenForFCM() async {
    var android = UniversalPlatform.isAndroid;
    var ios = UniversalPlatform.isIOS;

    if (android || ios) {
      pp('DashboardMobile: 🍎 🍎 _listen to FCM message streams ... 🍎 🍎');
      fcmBloc.projectStream.listen((Project project) async {
        if (mounted) {
          pp('DashboardMobile: 🍎 🍎 showProjectSnackbar: ${project.name} ... 🍎 🍎');
          _projects = await organizationBloc.getOrganizationProjects(
              organizationId: user!.organizationId!, forceRefresh: false);
          setState(() {});
        }
      });

      fcmBloc.userStream.listen((user) async {
        if (mounted) {
          pp('DashboardMobile: 🍎 🍎 showUserSnackbar: ${user.name} ... 🍎 🍎');
          _users = await organizationBloc.getUsers(
              organizationId: user.organizationId!, forceRefresh: false);
          setState(() {});
          // SpecialSnack.showUserSnackbar(
          //     scaffoldKey: _key, user: user, listener: this);
        }
      });

      fcmBloc.messageStream.listen((OrgMessage message) {
        if (mounted) {
          pp('DashboardMobile: 🍎 🍎 showMessageSnackbar: ${message.message} ... 🍎 🍎');

          // SpecialSnack.showMessageSnackbar(
          //     scaffoldKey: _key, message: message, listener: this);
        }
      });
    } else {
      pp('App is running on the Web 👿 👿 👿  firebase messaging is OFF 👿 👿 👿');
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

  void _navigateToMediaList() {
    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(seconds: 1),
              child: UserMediaListMain(user!)));
    }
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
              child: const IntroPageViewer()));
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

  bool _showProjectChooser = false;
  bool _showProjectSelected = false;

  Project? selectedProject;

  @override
  Widget build(BuildContext context) {
    var type = 'Field Monitor';
    if (user != null) {
      if (user!.userType == UserType.orgAdministrator) {
        type = 'Administrator';
      }
      if (user!.userType == UserType.orgExecutive) {
        type = 'Executive';
      }
    }
    var style = GoogleFonts.secularOne(
        textStyle: Theme.of(context).textTheme.headline6,
        fontWeight: FontWeight.w900);
    return SafeArea(
      child: Scaffold(
        key: _key,
        appBar: AppBar(
          actions: [
            IconButton(
                icon: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: _navigateToIntro),
            IconButton(
              icon: Icon(
                Icons.settings,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                themeBloc.changeToRandomTheme();
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
            )
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  user == null
                      ? const SizedBox()
                      : Text(
                          user!.organizationName!,
                          style: GoogleFonts.lato(
                            textStyle: Theme.of(context).textTheme.bodySmall,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                  const SizedBox(
                    height: 16,
                  ),
                  user == null
                      ? const SizedBox()
                      : Text(user!.name!,
                          style: GoogleFonts.lato(
                              textStyle: Theme.of(context).textTheme.headline6,
                              fontWeight: FontWeight.normal)),
                  const SizedBox(
                    height: 12,
                  ),
                  user == null
                      ? const Text('')
                      : Text(
                          type,
                          style: GoogleFonts.lato(
                            textStyle: Theme.of(context).textTheme.bodySmall,
                            fontWeight: FontWeight.normal,
                          ),
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
        body: isBusy
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
                                  borderRadius: BorderRadius.circular(16.0)),
                              child: Column(
                                children: [
                                  const SizedBox(
                                    height: 32,
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
                                  borderRadius: BorderRadius.circular(16.0)),
                              child: Column(
                                children: [
                                  const SizedBox(
                                    height: 32,
                                  ),
                                  Text(
                                    '${_users.length}',
                                    style: style,
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    'Users',
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
                              setState(() {
                                _showProjectChooser = true;
                                instruction = goToMedia;
                              });
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
                              setState(() {
                                _showProjectChooser = true;
                                instruction = goToMedia;
                              });
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
                              setState(() {
                                _showProjectChooser = true;
                                instruction = goToMedia;
                              });
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
                                  Text('${_audioss.length}', style: style),
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
                          animation: _polygonAnimationController,
                          builder: (BuildContext context, Widget? child) {
                            return FadeScaleTransition(
                              animation: _polygonAnimationController,
                              child: child,
                            );
                          },
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _showProjectChooser = true;
                                instruction = goToMap;
                              });
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
                              setState(() {
                                _showProjectChooser = true;
                                instruction = goToMap;
                              });
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
                              setState(() {
                                _showProjectChooser = true;
                                instruction = goToSchedule;
                              });
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
                        ),
                      ],
                    ),
                  ),
                  _showProjectChooser
                      ? Positioned(
                          left: 24, right: 24,
                          top: 0,
                          child: SizedBox(
                            height: 420,
                            width: 280,
                            child: ProjectChooser(
                              onClose: () {
                                setState(() {
                                  _showProjectChooser = false;
                                });
                              },
                              onSelected: (project) {
                                pp('$mm project selected ${project.name!}');
                                selectedProject = project;
                                setState(() {
                                  _showProjectChooser = false;
                                  _showProjectSelected = true;
                                });
                              },
                            ),
                          ),
                        )
                      : const SizedBox(),
                  _showProjectSelected
                      ? Positioned(left: 29, top: -8,
                          child: SizedBox(
                            height: 80,
                            width: 300,
                            child: Card(
                              color: Theme.of(context).primaryColor,
                              elevation: 8,
                              shape: getRoundedBorder(radius: 8),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _showProjectSelected = false;
                                  });
                                  _navigateToProjectList();
                                },
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 12,
                                    ),
                                     Text('Tap to see more:', style: myTextStyleSmall(context),),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Text('${selectedProject!.name}',style: myTextStyleMedium(context),),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(),
                ],
              ),
      ),
    );
  }
}
