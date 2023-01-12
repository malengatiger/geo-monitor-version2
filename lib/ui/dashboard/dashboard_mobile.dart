import 'dart:async';

import 'package:animations/animations.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../library/api/sharedprefs.dart';
import '../../library/bloc/fcm_bloc.dart';
import '../../library/bloc/organization_bloc.dart';
import '../../library/bloc/user_bloc.dart';
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
import '../../library/snack.dart';
import '../../library/ui/media/user_media_list/user_media_list_main.dart';
import '../../library/ui/media/user_media_list/user_media_list_mobile.dart';
import '../../library/ui/message/message_main.dart';
import '../../library/ui/project_list/project_list_mobile.dart';
import '../../library/users/list/user_list_main.dart';
import '../intro/intro_mobile.dart';
import '../schedules/schedules_list_main.dart';

class DashboardMobile extends StatefulWidget {
  final User user;
  const DashboardMobile({Key? key, required this.user}) : super(key: key);

  @override
  DashboardMobileState createState() => DashboardMobileState();
}

class DashboardMobileState extends State<DashboardMobile>
    with TickerProviderStateMixin {
  late AnimationController _projectAnimationController;
  late AnimationController _userAnimationController;
  late AnimationController _photoAnimationController;
  late AnimationController _videoAnimationController;
  var isBusy = false;
  var _projects = <Project>[];
  var _users = <User>[];
  var _photos = <Photo>[];
  var _videos = <Video>[];
  var _projectPositions = <ProjectPosition>[];
  var _schedules = <FieldMonitorSchedule>[];
  User? user;

  late StreamSubscription<ConnectivityResult> subscription;

  static const nn = '🎽🎽🎽🎽🎽🎽 DashboardMobile: 🎽';
  static const mm = '🎽🎽🎽🎽🎽🎽 DashboardMobile: 🎽';
  bool networkAvailable = false;
  @override
  void initState() {
    _projectAnimationController = AnimationController(
        duration: const Duration(milliseconds: 1000),
        reverseDuration: const Duration(milliseconds: 200),
        vsync: this);
    _userAnimationController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        reverseDuration: const Duration(milliseconds: 200),
        vsync: this);
    _photoAnimationController = AnimationController(
        duration: const Duration(milliseconds: 2000),
        reverseDuration: const Duration(milliseconds: 200),
        vsync: this);
    _videoAnimationController = AnimationController(
        duration: const Duration(milliseconds: 2500),
        reverseDuration: const Duration(milliseconds: 200),
        vsync: this);
    super.initState();
    _setItems();
    _listenToStreams();
    _listenForFCM();
    _refreshData(false);
    _subscribeToConnectivity();
    _subscribeToGeofenceStream();
    _buildGeofences();
  }

  void _buildGeofences() async {
    pp('\n\n$nn _buildGeofences starting ........................');
    await geofencerTwo.buildGeofences();
    pp('$nn _buildGeofences done.\n');
  }

  void _subscribeToConnectivity() {
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      pp('$nn onConnectivityChanged: result index: ${result.index}');
      if (result.index == ConnectivityResult.mobile.index) {
        pp('$nn ConnectivityResult.mobile.index: ${result.index} - 🍎 MOBILE NETWORK is on!');
        networkAvailable = true;
      }
      if (result.index == ConnectivityResult.wifi.index) {
        pp('$nn ConnectivityResult.wifi.index:  ${result.index} - 🍎 WIFI is on!');
        networkAvailable = true;
      }
      if (result.index == ConnectivityResult.none.index) {
        pp('ConnectivityResult.none.index: ${result.index} = 🍎 NONE - AIRPLANE MODE?');
        networkAvailable = false;
      }
      setState(() {});
    });
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

  void _listenToStreams() async {
    var user = await Prefs.getUser();
    if (user == null) return;
    switch(user.userType) {
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
    pp('$mm ............... Refreshing data ....');
    setState(() {
      isBusy = true;
    });
    try {
      user = await Prefs.getUser();
      //todo what kind of user is this? if monitor or admin or executive
      if (user != null) {
        switch (user!.userType) {
          case UserType.orgAdministrator:
            organizationBloc.refreshOrganizationData(
                organizationId: user!.organizationId!, forceRefresh: forceRefresh);
            break;
          case UserType.fieldMonitor:
            userBloc.refreshUserData(
                userId: user!.userId!,
                forceRefresh: forceRefresh);

            organizationBloc.refreshOrganizationData(
                organizationId: user!.organizationId!, forceRefresh: forceRefresh);

            break;
          case UserType.orgExecutive:
            organizationBloc.refreshOrganizationData(
                organizationId: user!.organizationId!, forceRefresh: true);
            break;
        }
      }
    } catch (e) {
      pp(e);
      AppSnackbar.showErrorSnackbar(
          scaffoldKey: _key, message: 'Dashboard refresh failed: $e');
    }
    setState(() {
      isBusy = false;
    });
  }

  void _listenForFCM() async {
    var android = UniversalPlatform.isAndroid;
    var ios = UniversalPlatform.isIOS;

    if (android || ios) {
      pp('DashboardMobile: 🍎 🍎 _listen to FCM message streams ... 🍎 🍎');
      fcmBloc.projectStream.listen((Project project) async {
        if (mounted) {
          pp('DashboardMobile: 🍎 🍎 showProjectSnackbar: ${project.name} ... 🍎 🍎');
          _projects = await organizationBloc.getProjects(
              organizationId: user!.organizationId!, forceRefresh: false);
          setState(() {});
        }
      });

      fcmBloc.userStream.listen((User user) async {
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

  void _navigateToProjectList() {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: ProjectListMobile(widget.user)));
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
    pp('$mm _navigateToIntro to Intro ....');
    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(seconds: 1),
              child: IntroMobile(
                user: widget.user,
              )));
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
        title: Text(
          'Digital Monitor',
          style: Styles.whiteTiny,
        ),
        actions: [
          IconButton(
              icon:  Icon(
                Icons.info_outline,
                size: 18, color: Theme.of(context).primaryColor,
              ),
              onPressed: _navigateToIntro),
          IconButton(
            icon:  Icon(
              Icons.settings,
              size: 18, color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              themeBloc.changeToRandomTheme();
            },
          ),
          IconButton(
            icon:  Icon(
              Icons.refresh,
              size: 18, color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              _refreshData(true);
            },
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  widget.user.organizationName!,
                  style: GoogleFonts.lato(
                    textStyle: Theme.of(context).textTheme.bodySmall,
                    fontWeight: FontWeight.w900,),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                   widget.user.name!,
                  style: GoogleFonts.lato(
                      textStyle: Theme.of(context).textTheme.headline6,
                      fontWeight: FontWeight.normal)
                ),
                user == null? const Text(''):Text(type, style: GoogleFonts.lato(
                  textStyle: Theme.of(context).textTheme.bodySmall,
                  fontWeight: FontWeight.normal,),),
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
        onTap: _handleBottomNav,elevation: 8,
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

                            return FadeScaleTransition(animation: _projectAnimationController, child: child,);
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
                                  '${_projects.length}',
                                    style: style),
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
                            return FadeScaleTransition(animation: _userAnimationController, child: child,);
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
                          return FadeScaleTransition(animation: _photoAnimationController, child: child,);
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
                              Text(
                                '${_photos.length}',
                                style: style),
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
                      AnimatedBuilder(
                        animation: _videoAnimationController,
                        builder: (BuildContext context, Widget? child) {
                          return FadeScaleTransition(animation: _videoAnimationController, child: child,);
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
                              Text(
                                '${_videos.length}',
                                  style: style),
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
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0)),
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 32,
                            ),
                            Text(
                                '${_projectPositions.length}',
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
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0)),
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 32,
                            ),
                            Text(
                                '${_schedules.length}',
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
                    ],
                  ),
                ),
              ],
            ),
    ));
  }


}
