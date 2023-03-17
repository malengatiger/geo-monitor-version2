import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/l10n/translation_handler.dart';
import 'package:geo_monitor/library/generic_functions.dart';
import 'package:geo_monitor/library/ui/project_list/project_list_main.dart';
import 'package:geo_monitor/library/ui/settings/settings_main.dart';
import 'package:geo_monitor/library/users/full_user_photo.dart';
import 'package:geo_monitor/ui/activity/geo_activity_mobile.dart';
import 'package:geo_monitor/ui/dashboard/dashboard_grid.dart';
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
import '../../library/bloc/user_bloc.dart';
import '../../library/data/audio.dart';
import '../../library/data/data_bag.dart';
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
import '../../library/ui/weather/daily_forecast_page.dart';
import '../../library/users/list/user_list_main.dart';
import '../intro/intro_page_viewer_portrait.dart';

class DashboardPortrait extends StatefulWidget {
  const DashboardPortrait({
    Key? key,
    this.user,
    this.project,
  }) : super(key: key);
  final User? user;
  final Project? project;
  @override
  DashboardPortraitState createState() => DashboardPortraitState();
}

class DashboardPortraitState extends State<DashboardPortrait>
    with SingleTickerProviderStateMixin {
  static const mm = '🎽🎽🎽🎽🎽🎽 DashboardPortrait: 🎽';

  late AnimationController _gridViewAnimationController;
  late StreamSubscription<Photo> photoSubscriptionFCM;
  late StreamSubscription<Video> videoSubscriptionFCM;
  late StreamSubscription<Audio> audioSubscriptionFCM;
  late StreamSubscription<ProjectPosition> projectPositionSubscriptionFCM;
  late StreamSubscription<ProjectPolygon> projectPolygonSubscriptionFCM;
  late StreamSubscription<Project> projectSubscriptionFCM;
  late StreamSubscription<User> userSubscriptionFCM;
  late StreamSubscription<SettingsModel> settingsSubscriptionFCM;
  late StreamSubscription<String> killSubscriptionFCM;
  late StreamSubscription<bool> connectionSubscription;
  late StreamSubscription<GeofenceEvent> geofenceSubscription;
  //
  late StreamSubscription<Photo> photoSubscription;
  late StreamSubscription<Video> videoSubscription;
  late StreamSubscription<Audio> audioSubscription;
  late StreamSubscription<ProjectPosition> projectPositionSubscription;
  late StreamSubscription<ProjectPolygon> projectPolygonSubscription;
  late StreamSubscription<Project> projectSubscription;

  late StreamSubscription<SettingsModel> settingsSubscription;


  late StreamSubscription<DataBag> dataBagSubscription;
  //

  var busy = false;
  User? deviceUser;
  final fb.FirebaseAuth firebaseAuth = fb.FirebaseAuth.instance;
  bool authed = false;
  bool networkAvailable = false;
  final dur = 3000;
  String type = 'Unknown Rider';
  DataBag? dataBag;
  final _key = GlobalKey<ScaffoldState>();
  int instruction = stayOnList;
  var items = <BottomNavigationBarItem>[];
  SettingsModel? settings;

  int numberOfDays = 7;
  @override
  void initState() {
    _gridViewAnimationController = AnimationController(
        duration: Duration(milliseconds: dur),
        reverseDuration: Duration(milliseconds: dur),
        vsync: this);
    super.initState();
    _getData(false);
    _setItems();
    _listenForData();
    _listenForFCM();
    _getAuthenticationStatus();
    _subscribeToConnectivity();
    _subscribeToGeofenceStream();
    // _startTimer();
  }

  void _listenForData() async {
    settingsSubscription =
        organizationBloc.settingsStream.listen((SettingsModel settings) async {
          pp('$mm settingsStream delivered settings ... ${settings.locale!}');
          await _handleNewSettings(settings);
          if (mounted) {
            setState(() {});
          }
        });
    settingsSubscriptionFCM = fcmBloc.settingsStream.listen((settings) async {
      pp('$mm: 🍎🍎 settings arrived with themeIndex: ${settings.themeIndex}... locale: ${settings.locale} 🍎🍎');
      await _handleNewSettings(settings);
    });
    dataBagSubscription = organizationBloc.dataBagStream.listen((DataBag bag) {
      dataBag = bag;
      pp('$mm dataBagStream delivered a dataBag!! 🍐Yebo! 🍐');
      if (mounted) {
        setState(() {

        });
      }
    });
  }
  Future<void> _handleNewSettings(SettingsModel settings) async {
    Locale newLocale = Locale(settings.locale!);
    await mTx.translate('settings', settings.locale!);
    final m = LocaleAndTheme(themeIndex: settings!.themeIndex!,
        locale: newLocale);
    themeBloc.themeStreamController.sink.add(m);
    this.settings = settings;
    _getData(false);
  }

  void _getAuthenticationStatus() async {
    var cUser = firebaseAuth.currentUser;
    if (cUser == null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _navigateToIntro();
      });
      //
    }
  }

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

  void _subscribeToGeofenceStream() async {
    geofenceSubscription =
        theGreatGeofencer.geofenceEventStream.listen((event) {
      pp('\n$mm geofenceEvent delivered by geofenceStream: ${event.projectName} ...');
      if (mounted) {
        showToast(
            message: '${event.user!.name} at ${event.projectName}',
            context: context);
      }
    });
  }

  @override
  void dispose() {
    _gridViewAnimationController.dispose();

    connectionSubscription.cancel();
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

  var subTitle = 'Data is for ';

  Future _getData(bool forceRefresh) async {
    pp('$mm ............................................ Refreshing dashboard data ....');
    deviceUser = await prefsOGx.getUser();
    settings = await prefsOGx.getSettings();
    if (settings != null) {
      numberOfDays = settings!.numberOfDays!;
    }
    var sub = await mTx.translate('dashboardSubTitle', settings!.locale!);
    pp(sub);
    subTitle = sub.replaceAll('\$count', '$numberOfDays');
    pp(subTitle);
    setState(() {

    });

    if (deviceUser != null) {
      if (deviceUser!.userType == UserType.orgAdministrator) {
        type = await mTx.translate('administrator', settings!.locale!);
      }
      if (deviceUser!.userType == UserType.orgExecutive) {
        type = await mTx.translate('executive', settings!.locale!);
      }
      if (deviceUser!.userType == UserType.fieldMonitor) {
        type = await mTx.translate('fieldMonitor', settings!.locale!);
      }
    } else {
      throw Exception('No user cached on device');
    }

    setState(() {
      busy = true;
    });
    await _doTheWork(forceRefresh);

    _gridViewAnimationController.forward();
  }

  Future<void> _doTheWork(bool forceRefresh) async {
    if (deviceUser == null) {
      throw Exception("The data refresh man is fucked! Device User is not found");
    }
    if (widget.project != null) {
      await _getProjectData(widget.project!.projectId!, forceRefresh);
    } else if (widget.user != null) {
      await _getUserData(widget.user!.userId!, forceRefresh);
    } else {
      await _getOrganizationData(deviceUser!.organizationId!, forceRefresh);
    }
    _gridViewAnimationController.forward();
    setState(() {
      busy = false;
    });
  }

  Future _getOrganizationData(String organizationId, bool forceRefresh) async {
    var map = await getStartEndDates();
    final startDate = map['startDate'];
    final endDate = map['endDate'];
    pp('$mm _getOrganizationData: startDate : $startDate endDate: $endDate');
    final start = DateTime.now();
    dataBag = await organizationBloc.getOrganizationData(
        organizationId: organizationId,
        forceRefresh: forceRefresh,
        startDate: startDate!,
        endDate: endDate!);
    final end = DateTime.now();
    pp('$mm _getOrganizationData: data bag returned ... ${end.difference(start).inSeconds} seconds elepased');
  }

  Future _getProjectData(String projectId, bool forceRefresh) async {
    var map = await getStartEndDates();
    final startDate = map['startDate'];
    final endDate = map['endDate'];
    pp('$mm _getOrganizationData: startDate : $startDate endDate: $endDate');
    dataBag = await projectBloc.getProjectData(
        projectId: projectId,
        forceRefresh: forceRefresh,
        startDate: startDate!,
        endDate: endDate!);
    pp('$mm _getProjectData: data bag returned ...');
  }

  Future _getUserData(String userId, bool forceRefresh) async {
    var map = await getStartEndDates();
    final startDate = map['startDate'];
    final endDate = map['endDate'];
    pp('$mm _getOrganizationData: startDate : $startDate endDate: $endDate');
    dataBag = await userBloc.getUserData(
        userId: userId,
        forceRefresh: forceRefresh,
        startDate: startDate!,
        endDate: endDate!);
    pp('$mm _getUserData: data bag returned ...');
  }

  void _listenForFCM() async {
    var android = UniversalPlatform.isAndroid;
    var ios = UniversalPlatform.isIOS;
    if (android || ios) {
      pp('$mm 🍎 🍎 _listen to FCM message streams ... 🍎 🍎');
      projectSubscriptionFCM =
          fcmBloc.projectStream.listen((Project project) async {
        await _getData(false);
        if (mounted) {
          pp('$mm: 🍎 🍎 project arrived: ${project.name} ... 🍎 🍎');
          setState(() {});
        }
      });

      settingsSubscriptionFCM = fcmBloc.settingsStream.listen((settings) async {
        pp('$mm: 🍎🍎 settings arrived with themeIndex: ${settings.themeIndex}... 🍎🍎');
        _handleNewSettings(settings);

      });
      userSubscriptionFCM = fcmBloc.userStream.listen((user) async {
        pp('$mm: 🍎 🍎 user arrived... 🍎 🍎');
        if (user.userId == deviceUser!.userId!) {
          deviceUser = user;
        }
        _getData(false);
      });
      photoSubscriptionFCM = fcmBloc.photoStream.listen((user) async {
        pp('$mm: 🍎 🍎 photoSubscriptionFCM photo arrived... 🍎 🍎');
        _getData(false);

      });

      videoSubscriptionFCM = fcmBloc.videoStream.listen((Video message) async {
        pp('$mm: 🍎 🍎 videoSubscriptionFCM video arrived... 🍎 🍎');
        await _getData(false);
        if (mounted) {
          pp('DashboardMobile: 🍎 🍎 showMessageSnackbar: ${message.projectName} ... 🍎 🍎');
          setState(() {});
        }
      });
      audioSubscriptionFCM = fcmBloc.audioStream.listen((Audio message) async {
        pp('$mm: 🍎 🍎 audioSubscriptionFCM audio arrived... 🍎 🍎');
        await _getData(false);
        if (mounted) {}
      });
      projectPositionSubscriptionFCM =
          fcmBloc.projectPositionStream.listen((ProjectPosition message) async {
        pp('$mm: 🍎 🍎 projectPositionSubscriptionFCM position arrived... 🍎 🍎');
        await _getData(false);
        if (mounted) {}
      });
      projectPolygonSubscriptionFCM =
          fcmBloc.projectPolygonStream.listen((ProjectPolygon message) async {
        pp('$mm: 🍎 🍎 projectPolygonSubscriptionFCM polygon arrived... 🍎 🍎');
        await _getData(false);
        if (mounted) {}
      });
    } else {
      pp('App is running on the Web 👿👿👿firebase messaging is OFF 👿👿👿');
    }
  }

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

  void _navigateToProjectList() {
    if (selectedProject != null) {
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
              child: ProjectListMobile(
                instruction: instruction,
              )));
    }
  }

  void _navigateToMessageSender() {
    // Navigator.push(
    //     context,
    //     PageTransition(
    //         type: PageTransitionType.scale,
    //         alignment: Alignment.topLeft,
    //         duration: const Duration(seconds: 1),
    //         child: const ChatPage()));
    showToast(
        textStyle: myTextStyleMediumBold(context),
        toastGravity: ToastGravity.TOP,
        message: 'Messaging under construction, see you later!',
        context: context);
  }

  void _navigateToUserMediaList() async {
    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(seconds: 1),
              child: UserMediaListMobile(user: deviceUser!)));
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
    deviceUser = await prefsOGx.getUser();
    if (deviceUser != null) {
      if (mounted) {
        Navigator.push(
            context,
            PageTransition(
                type: PageTransitionType.scale,
                alignment: Alignment.topLeft,
                duration: const Duration(seconds: 1),
                child: FullUserPhoto(user: deviceUser!)));
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
              child: const SettingsMain()));
    }
  }

  void showPhoto(Photo p) async {}

  void showVideo(Video p) async {}

  void showAudio(Audio p) async {}

  void _navigateToActivity() {
    pp('$mm .................. _navigateToActivity ....');
    final width = MediaQuery.of(context).size.width;
    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.rotate,
              alignment: Alignment.center,
              duration: const Duration(seconds: 1),
              child: GeoActivityMobile(
                user: widget.user,
                project: widget.project,
              )));
    }
  }

  void _navigateToUserList() {
    if (dataBag == null) return;
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.fade,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: UserListMain(
              user: deviceUser!,
              users: dataBag!.users!,
            )));
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
                      width: 400,
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
    bool showAdminIcons = false;
    if (deviceUser != null) {
      switch (deviceUser!.userType) {
        case UserType.orgAdministrator:
          showAdminIcons = true;
          break;
        case UserType.orgExecutive:
          showAdminIcons = true;
          break;
        case UserType.fieldMonitor:
          showAdminIcons = true;
          break;
      }
    }
    return SafeArea(
      child: Scaffold(
        key: _key,
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            IconButton(
                icon: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: _navigateToIntro),
            showAdminIcons
                ? IconButton(
                    icon: Icon(
                      Icons.access_alarm,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: _navigateToActivity,
                  )
                : const SizedBox(),
            showAdminIcons
                ? IconButton(
                    icon: Icon(
                      Icons.settings,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: _navigateToSettings,
                  )
                : const SizedBox(),
            IconButton(
              icon: Icon(
                Icons.refresh,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                _getData(true);
              },
            )
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(180),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  deviceUser == null
                      ? const SizedBox()
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                deviceUser!.organizationName!,
                                style: myTextStyleLarge(context),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(
                    height: 16,
                  ),
                  deviceUser == null
                      ? const SizedBox()
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(deviceUser!.name!,
                                style: GoogleFonts.lato(
                                    textStyle:
                                        Theme.of(context).textTheme.titleLarge,
                                    fontWeight: FontWeight.normal,
                                    color: Theme.of(context).primaryColor)),
                            const SizedBox(
                              width: 8,
                            ),
                            deviceUser!.thumbnailUrl == null
                                ? const CircleAvatar()
                                : GestureDetector(
                                    onTap: _navigateToFullUserPhoto,
                                    child: CircleAvatar(
                                      backgroundImage: NetworkImage(
                                          deviceUser!.thumbnailUrl!),
                                      radius: 28,
                                    ),
                                  ),
                          ],
                        ),
                  const SizedBox(
                    height: 0,
                  ),
                  deviceUser == null
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(subTitle,
                        style: myTextStyleSmall(context),
                      ),

                    ],
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
        // backgroundColor: Colors.brown[100],
        // bottomNavigationBar: BottomNavigationBar(
        //   items: items,
        //   onTap: _handleBottomNav,
        //   elevation: 8,
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
            : Stack(children: [
                dataBag == null
                    ? const SizedBox()
                    : DashboardGrid(
                      gridPadding: 16,
                      topPadding: 12,
                      elementPadding: 48,
                      leftPadding: 12,
                      crossAxisCount: 2,
                      dataBag: dataBag!,
                      onTypeTapped: (type) {
                        switch (type) {
                          case typeProjects:
                            _navigateToProjectList();
                            break;
                          case typeUsers:
                            _navigateToUserList();
                            break;
                          case typePhotos:
                            _navigateToProjectList();
                            break;
                          case typeVideos:
                            _navigateToProjectList();
                            break;
                          case typeAudios:
                            _navigateToProjectList();
                            break;
                          case typePositions:
                            _navigateToProjectList();
                            break;
                          case typePolygons:
                            _navigateToProjectList();
                            break;
                        }
                      },
                    ),
              ]),
      ),
    );
  }
}

final mm = '${E.heartRed}${E.heartRed}${E.heartRed}${E.heartRed} Dashboard: ';
