import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/bloc/downloader.dart';
import 'package:geo_monitor/library/ui/camera/video_player_tablet.dart';
import 'package:geo_monitor/library/ui/project_list/project_list_main.dart';
import 'package:geo_monitor/library/users/full_user_photo.dart';
import 'package:geo_monitor/ui/activity/geo_activity_tablet.dart';
import 'package:geo_monitor/ui/audio/audio_player_page.dart';
import 'package:geo_monitor/ui/dashboard/dashboard_grid.dart';
import 'package:geofence_service/geofence_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../library/api/prefs_og.dart';
import '../../library/bloc/connection_check.dart';
import '../../library/bloc/fcm_bloc.dart';
import '../../library/bloc/organization_bloc.dart';
import '../../library/data/audio.dart';
import '../../library/data/data_bag.dart';
import '../../library/data/geofence_event.dart';
import '../../library/data/photo.dart';
import '../../library/data/project.dart';
import '../../library/data/user.dart';
import '../../library/data/video.dart';
import '../../library/emojis.dart';
import '../../library/functions.dart';
import '../../library/generic_functions.dart';
import '../../library/geofence/geofencer_two.dart';
import '../../library/ui/maps/photo_map_tablet.dart';
import '../../library/ui/maps/project_map_mobile.dart';
import '../../library/ui/media/list/project_media_list_mobile.dart';
import '../../library/ui/media/user_media_list/user_media_list_mobile.dart';
import '../../library/ui/project_list/project_chooser.dart';
import '../../library/ui/project_list/project_list_mobile.dart';
import '../../library/ui/settings/settings_main.dart';
import '../../library/ui/weather/daily_forecast_page.dart';
import '../../library/users/list/user_list_main.dart';
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

  var busy = false;
  var _users = <User>[];
  User? user;

  static const mm = '🎽🎽🎽🎽🎽🎽 DashboardTabletPortrait: 🎽';
  bool networkAvailable = false;
  final dur = 300;
  DataBag? dataBag;

  @override
  void initState() {
    _setAnimationControllers();
    super.initState();
    _setItems();
    _getAuthenticationStatus();
    _subscribeToConnectivity();
    _subscribeToGeofenceStream();
    _startTimer();
    _getData(false);
  }

  void _getData(bool forceRefresh) async {
    setState(() {
      busy = true;
    });
    try {
      user = await prefsOGx.getUser();
      dataBag = await organizationBloc.getOrganizationData(
          organizationId: user!.organizationId!, forceRefresh: forceRefresh);
      _users = dataBag!.users!;
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

  bool _showPhoto = false;
  bool _showVideo = false;
  bool _showAudio = false;

  void _displayPhoto(Photo photo) async {
    pp('$mm _displayPhoto ...');
    this.photo = photo;
    setState(() {
      _showPhoto = true;
      _showVideo = false;
      _showAudio = false;
    });
  }

  void _displayVideo(Video video) async {
    pp('$mm _displayVideo ...');
    this.video = video;
    setState(() {
      _showPhoto = false;
      _showVideo = true;
      _showAudio = false;
    });
  }

  void _displayAudio(Audio audio) async {
    pp('$mm _displayAudio ...');
    this.audio = audio;
    setState(() {
      _showPhoto = false;
      _showVideo = false;
      _showAudio = true;
    });
  }

  Photo? photo;
  Video? video;
  Audio? audio;

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
    pp('$mm _navigateToUserMediaList ...');

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
              users: _users,
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
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: const DailyForecastPage()));
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
                      width: 500,
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

  void _navigateToPhotoMap() {
    pp('$mm _navigateToPhotoMap ...');

    if (mounted) {
      if (photo == null) return;
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1000),
              child: PhotoMapTablet(
                photo: photo!,
              )));
    }
  }

  Project? selectedProject;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return SafeArea(
        child: WillStartForegroundTask(
      onWillStart: () async {
        pp('$mm WillStartForegroundTask: onWillStart - what do we do now, Boss?');
        return geofenceService.isRunningService;
      },
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'geofence_service_notification_channel',
        channelName: 'Geofence Service Notification',
        channelDescription:
            'This notification appears when the geofence service is running in the background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        isSticky: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      notificationTitle: 'GeoMonitor Service is running',
      notificationText: 'Tap to return to the app',
      foregroundTaskOptions: const ForegroundTaskOptions(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Geo Dashboard'),
          actions: [
            IconButton(
                icon: Icon(
                  Icons.info_outline,
                  size: 28,
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
                          size: 28,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: _navigateToSettings,
                      ),
            IconButton(
              icon: Icon(
                Icons.refresh,
                size: 28,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                _getData(true);
              },
            )
          ],
        ),
        body: busy
            ? Center(
                child: Card(
                  elevation: 16,
                  shape: getRoundedBorder(radius: 12),
                  child: const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        backgroundColor: Colors.amber,
                      ),
                    ),
                  ),
                ),
              )
            : Stack(
                children: [
                  dataBag == null
                      ? const SizedBox()
                      : Row(
                          children: [
                            SizedBox(
                              width: (width / 2) + 100,
                              child: DashboardGrid(
                                  dataBag: dataBag!,
                                  topPadding: 40,
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
                                    }
                                  }),
                            ),
                            GeoActivityTablet(
                              width: 280,
                              thinMode: true,
                              showPhoto: (photo) {
                                _displayPhoto(photo);
                              },
                              showVideo: (video) {
                                _displayVideo(video);
                              },
                              showAudio: (audio) {
                                _displayAudio(audio);
                              },
                            ),
                          ],
                        ),
                  _showPhoto
                      ? Positioned(
                          left: 100,
                          right: 100,
                          top: 12,
                          child: SizedBox(
                            width: 600,
                            height: 800,
                            // color: Theme.of(context).primaryColor,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showPhoto = false;
                                  });
                                },
                                child: Card(
                                  shape: getRoundedBorder(radius: 16),
                                  elevation: 8,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 12,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 48.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${photo!.projectName}',
                                                style:
                                                    myTextStyleLargePrimaryColor(
                                                        context),
                                              ),
                                              IconButton(
                                                  onPressed: () {
                                                    pp('$mm .... put photo on a map!');
                                                    _navigateToPhotoMap();
                                                  },
                                                  icon: Icon(
                                                    Icons.location_on,
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    size: 24,
                                                  )),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 12,
                                        ),
                                        Text(
                                          '${photo!.userName}',
                                          style: myTextStyleSmallBold(context),
                                        ),
                                        const SizedBox(
                                          height: 4,
                                        ),
                                        Text(
                                          getFormattedDateShortWithTime(
                                              photo!.created!, context),
                                          style: myTextStyleTiny(context),
                                        ),
                                        const SizedBox(
                                          height: 12,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 2.0, vertical: 2.0),
                                          child: InteractiveViewer(
                                              child: CachedNetworkImage(
                                                  fit: BoxFit.fill,
                                                  progressIndicatorBuilder: (context,
                                                          url,
                                                          downloadProgress) =>
                                                      Center(
                                                          child: SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child: CircularProgressIndicator(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .pink,
                                                                  value: downloadProgress
                                                                      .progress))),
                                                  errorWidget: (context, url, error) =>
                                                      const Icon(Icons.error),
                                                  fadeInDuration: const Duration(
                                                      milliseconds: 1500),
                                                  fadeInCurve:
                                                      Curves.easeInOutCirc,
                                                  placeholderFadeInDuration:
                                                      const Duration(milliseconds: 1500),
                                                  imageUrl: photo!.url!)),
                                        ),
                                        const SizedBox(
                                          height: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ))
                      : const SizedBox(),
                  _showVideo
                      ? Positioned(
                          left: 100,
                          right: 100,
                          top: 12,
                          child: VideoPlayerTabletPage(
                            video: video!,
                            onCloseRequested: () {
                              if (mounted) {
                                setState(() {
                                  _showVideo = false;
                                });
                              }
                            },
                          ),
                        )
                      : const SizedBox(),
                  _showAudio
                      ? Positioned(
                          left: 100,
                          right: 100,
                          top: 160,
                          child: AudioPlayerCard(
                            audio: audio!,
                            onCloseRequested: () {
                              if (mounted) {
                                setState(() {
                                  _showAudio = false;
                                });
                              }
                            },
                          ))
                      : const SizedBox(),
                ],
              ),
      ),
    ));
  }
}
///////

class Headline extends StatelessWidget {
  const Headline({Key? key, required this.user, required this.paddingLeft})
      : super(key: key);
  final User user;
  final double paddingLeft;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Column(
        children: [
          const SizedBox(
            height: 12,
          ),
          user.organizationName == null
              ? const SizedBox()
              : Text(
                  '${user.organizationName}',
                  style: GoogleFonts.lato(
                      textStyle: Theme.of(context).textTheme.bodyLarge,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).primaryColor,
                      fontSize: 24),
                ),
          const SizedBox(
            height: 12,
          ),
          Padding(
            padding: EdgeInsets.only(left: paddingLeft),
            child: Row(
              children: [
                user.thumbnailUrl == null
                    ? const CircleAvatar(
                        radius: 28,
                      )
                    : CircleAvatar(
                        backgroundImage: NetworkImage(user.thumbnailUrl!),
                        radius: 28,
                      ),
                const SizedBox(
                  width: 28,
                ),
                Text(
                  '${user.name}',
                  style: myTextStyleLarge(context),
                ),
              ],
            ),
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
