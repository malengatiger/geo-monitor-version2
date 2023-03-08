import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/bloc/fcm_bloc.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';
import 'package:geo_monitor/library/cache_manager.dart';
import 'package:geo_monitor/library/data/activity_model.dart';
import 'package:geo_monitor/library/data/geofence_event.dart';
import 'package:geo_monitor/library/data/location_request.dart';
import 'package:geo_monitor/library/data/location_response.dart';
import 'package:geo_monitor/library/data/org_message.dart';
import 'package:geo_monitor/library/ui/camera/video_player_tablet.dart';
import 'package:geo_monitor/library/ui/maps/geofence_map_tablet.dart';
import 'package:geo_monitor/library/ui/media/list/project_media_main.dart';
import 'package:geo_monitor/library/ui/ratings/rating_adder.dart';
import 'package:geo_monitor/library/ui/settings/settings_main.dart';
import 'package:geo_monitor/ui/activity/geo_activity.dart';
import 'package:geo_monitor/ui/charts/summary_chart.dart';
import 'package:geo_monitor/ui/dashboard/dashboard_grid.dart';
import 'package:geo_monitor/ui/dashboard/photo_card.dart';
import 'package:geo_monitor/ui/intro/intro_main.dart';
import 'package:page_transition/page_transition.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../library/api/prefs_og.dart';
import '../../library/bloc/downloader.dart';
import '../../library/bloc/theme_bloc.dart';
import '../../library/data/audio.dart';
import '../../library/data/data_bag.dart';
import '../../library/data/field_monitor_schedule.dart';
import '../../library/data/photo.dart';
import '../../library/data/project.dart';
import '../../library/data/project_polygon.dart';
import '../../library/data/project_position.dart';
import '../../library/data/settings_model.dart';
import '../../library/data/user.dart';
import '../../library/data/video.dart';
import '../../library/functions.dart';
import '../../library/generic_functions.dart';
import '../../library/ui/maps/location_response_map.dart';
import '../../library/ui/maps/photo_map_tablet.dart';
import '../../library/ui/maps/project_map_main.dart';
import '../../library/ui/project_list/project_chooser.dart';
import '../../library/ui/project_list/project_list_main.dart';
import '../../library/users/full_user_photo.dart';
import '../../library/users/list/user_list_main.dart';
import '../audio/audio_player_page.dart';

class DashboardTablet extends StatefulWidget {
  const DashboardTablet({Key? key, required this.user}) : super(key: key);

  final User user;

  @override
  State<DashboardTablet> createState() => DashboardTabletState();
}

class DashboardTabletState extends State<DashboardTablet> {
  final mm = '🍎🍎🍎🍎 DashboardTablet: 🔵 ';
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
  late StreamSubscription<ActivityModel> activitySubscriptionFCM;

  late StreamSubscription<String> killSubscriptionFCM;
  var users = <User>[];
  User? user;
  DataBag? dataBag;
  bool busy = false;
  int numberOfDays = 7;

  @override
  void initState() {
    super.initState();
    _listenForFCM();
    _getData(false);
  }

  void _listenForFCM() async {
    var android = UniversalPlatform.isAndroid;
    var ios = UniversalPlatform.isIOS;
    if (android || ios) {
      pp('$mm 🍎 🍎 _listen to FCM message streams ... 🍎 🍎');
      pp('$mm ... _listenToFCM activityStream ...');

      activitySubscriptionFCM =
          fcmBloc.activityStream.listen((ActivityModel model) {
        pp('\n\n$mm activityStream delivered activity data ... ${model.date!}\n\n');
        _getData(false);
        if (mounted) {
          setState(() {});
        }
      });
      projectSubscriptionFCM =
          fcmBloc.projectStream.listen((Project project) async {
        _getData(false);
        if (mounted) {
          pp('$mm: 🍎 🍎 project arrived: ${project.name} ... 🍎 🍎');
          setState(() {});
        }
      });

      settingsSubscriptionFCM = fcmBloc.settingsStream.listen((settings) async {
        pp('$mm: 🍎🍎 settings arrived with themeIndex: ${settings.themeIndex}... 🍎🍎');
        themeBloc.themeStreamController.sink.add(settings.themeIndex!);
        if (mounted) {
          setState(() {});
        }
      });
      userSubscriptionFCM = fcmBloc.userStream.listen((user) async {
        pp('$mm: 🍎 🍎 user arrived... 🍎 🍎');
        _getData(false);
        if (mounted) {
          setState(() {});
        }
      });
      photoSubscriptionFCM = fcmBloc.photoStream.listen((user) async {
        pp('$mm: 🍎 🍎 photoSubscriptionFCM photo arrived... 🍎 🍎');
        _getData(false);
        if (mounted) {
          setState(() {});
        }
      });

      videoSubscriptionFCM = fcmBloc.videoStream.listen((Video message) async {
        pp('$mm: 🍎 🍎 videoSubscriptionFCM video arrived... 🍎 🍎');
        _getData(false);
        if (mounted) {
          pp('DashboardMobile: 🍎 🍎 showMessageSnackbar: ${message.projectName} ... 🍎 🍎');
          setState(() {});
        }
      });
      audioSubscriptionFCM = fcmBloc.audioStream.listen((Audio message) async {
        pp('$mm: 🍎 🍎 audioSubscriptionFCM audio arrived... 🍎 🍎');
        _getData(false);
        if (mounted) {}
      });
      projectPositionSubscriptionFCM =
          fcmBloc.projectPositionStream.listen((ProjectPosition message) async {
        pp('$mm: 🍎 🍎 projectPositionSubscriptionFCM position arrived... 🍎 🍎');
        _getData(false);
        if (mounted) {}
      });
      projectPolygonSubscriptionFCM =
          fcmBloc.projectPolygonStream.listen((ProjectPolygon message) async {
        pp('$mm: 🍎 🍎 projectPolygonSubscriptionFCM polygon arrived... 🍎 🍎');
        _getData(false);
        if (mounted) {}
      });
    } else {
      pp('App is running on the Web 👿👿👿firebase messaging is OFF 👿👿👿');
    }
  }

  void _getData(bool forceRefresh) async {
    setState(() {
      busy = true;
    });
    try {
      user = await prefsOGx.getUser();
      var settings = await prefsOGx.getSettings();
      if (settings != null) {
        numberOfDays = settings.numberOfDays!;
      }
      var map = await getStartEndDates();
      final startDate = map['startDate'];
      final endDate = map['endDate'];

      dataBag = await organizationBloc.getOrganizationData(
          organizationId: user!.organizationId!,
          forceRefresh: forceRefresh,
          startDate: startDate!,
          endDate: endDate!);
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

  void _navigateToIntro() {
    pp('$mm .................. _navigateToIntro  ....');
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

  void _navigateToCharts() {
    pp('$mm .................. _navigateToCharts  ....');
    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(seconds: 1),
              child: const ProjectSummaryChart()));
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
            child: ProjectMediaMain(project: project)));
  }

  void _navigateToProjectMap(Project project) {
    pp('$mm _navigateToProjectMap ...');

    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1000),
              child: ProjectMapMain(
                project: project,
              )));
    }
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

  onMapRequested(Photo p1) {
    pp('$mm onMapRequested ... ');
    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1000),
              child: PhotoMap(
                photo: p1,
              )));
    }
  }

  bool _showRatingAdder = false;

  onRatingRequested(Photo p1) {
    pp('$mm onRatingRequested ...');
    if (mounted) {
      setState(() {
        photo = p1;
        _showRatingAdder = true;
        _showAudio = false;
        _showVideo = false;
      });
    }
  }

  Project? selectedProject;
  bool _showPhoto = false;
  bool _showVideo = false;
  bool _showAudio = false;

  bool _showLocationResponse = false;
  bool _showProjectPosition = false;
  bool _showALocationRequest = false;
  bool _showProjectPolygon = false;
  bool _showMessage = false;
  bool _showUser = false;

  Photo? photo;
  Video? video;
  Audio? audio;
  LocationRequest? request;
  LocationResponse? response;
  ProjectPolygon? projectPolygon;
  ProjectPosition? projectPosition;
  OrgMessage? orgMessage;
  User? someUser;

  void _resetFlags() {
    _showPhoto = false;
    _showVideo = false;
    _showAudio = false;
    _showLocationResponse = false;
    _showALocationRequest = false;
    _showProjectPosition = false;
    _showProjectPolygon = false;
    _showMessage = false;
    _showUser = false;
  }

  void _displayPhoto(Photo photo) async {
    pp('$mm _displayPhoto ...');
    this.photo = photo;
    _resetFlags();
    setState(() {
      _showPhoto = true;
    });
  }

  void _displayVideo(Video video) async {
    pp('$mm _displayVideo ...');
    this.video = video;
    _resetFlags();
    setState(() {
      _showVideo = true;
    });
  }

  void _displayAudio(Audio audio) async {
    pp('$mm _displayAudio ...');
    this.audio = audio;
    _resetFlags();
    setState(() {
      _showAudio = true;
    });
  }

  void _displayProjectPosition(ProjectPosition pos) async {
    pp('$mm _displayProjectPosition ...');
    projectPosition = pos;
    _resetFlags();
    setState(() {
      _showProjectPosition = true;
    });
  }
  void _displayProjectPolygon(ProjectPolygon pol) async {
    pp('$mm _displayProjectPolygon ...');
    projectPolygon = pol;
    _resetFlags();
    setState(() {
      _showProjectPolygon = true;
    });
  }
  void _displayLocationRequest(LocationRequest req) async {
    pp('$mm _displayLocationRequest ...');
    request = req;
    _resetFlags();
    setState(() {
      _showALocationRequest = true;
    });
  }

  void _navigateToLocationResponseMap(LocationResponse resp) async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: LocationResponseMap(
              locationResponse: resp!,
            )));
  }
  void _navigateToGeofenceMap(GeofenceEvent event) async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: GeofenceMapTablet(
              geofenceEvent: event!,
            )));
  }
  void _displayUser(User user) async {
    pp('$mm _displayUser ...');
    someUser = user;
    _resetFlags();
    setState(() {
      _showALocationRequest = true;
    });
  }



  void _navigateToPhotoMap() {
    pp('$mm _navigateToPhotoMap ...');

    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1000),
              child: PhotoMap(
                photo: photo!,
              )));
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var ori = MediaQuery.of(context).orientation;
    var bottomHeight = 140.0;
    var padding = 360.0;
    var extPadding = 200.0;
    var top = -12.0;
    if (ori.name == 'portrait') {
      padding = 200;
      top = 0;
      bottomHeight = 140;
      extPadding = 120;
    }

    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Organization Dashboard'),
        actions: [
          IconButton(
              icon: Icon(
                Icons.info_outline,
                size: 24,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: _navigateToIntro),
          IconButton(
              icon: Icon(
                Icons.bar_chart,
                size: 24,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: _navigateToCharts),
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
              pp('$mm =======================> requesting refresh .......');
              _getData(true);
            },
          )
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(bottomHeight),
          child: Column(
            children: [
              user == null
                  ? const SizedBox()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          '${user!.name}',
                          style: myTextStyleSmall(context),
                        ),
                        const SizedBox(
                          width: 24,
                        ),
                        user!.imageUrl == null
                            ? const CircleAvatar(
                                radius: 8,
                              )
                            : CircleAvatar(
                                radius: 28,
                                backgroundImage: NetworkImage(user!.imageUrl!),
                              )
                      ],
                    ),
              const SizedBox(
                height: 8,
              ),
              const SizedBox(
                height: 32,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 28.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Data is for the last',
                      style: myTextStyleSmall(context),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Text(
                      '$numberOfDays',
                      style: myNumberStyleMediumPrimaryColor(context),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Text(
                      'days',
                      style: myTextStyleSmall(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          OrientationLayoutBuilder(
            portrait: (context) {
              return Row(
                children: [
                  SizedBox(
                    width: (size.width / 2) + 80,
                    child: dataBag == null
                        ? const SizedBox()
                        : DashboardGrid(
                            dataBag: dataBag!,
                            crossAxisCount: 2,
                            topPadding: 48,
                            elementPadding: 56,
                            leftPadding: 12,
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
                                case typeSchedules:
                                  _navigateToProjectList();
                                  break;
                              }
                            },
                            gridPadding: 64,
                          ),
                  ),
                  GeoActivity(
                    width: (size.width / 2) - 100,
                    forceRefresh: true,
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
                    showUser: (user) {},
                    showLocationRequest: (req) {},
                    showLocationResponse: (resp) {
                      _navigateToLocationResponseMap(resp);
                    },
                    showGeofenceEvent: (event) {},
                    showProjectPolygon: (polygon) {},
                    showProjectPosition: (position) {},
                    showOrgMessage: (message) {},
                  ),
                ],
              );
            },
            landscape: (context) {
              return Row(
                children: [
                  SizedBox(
                    width: (size.width / 2) + 60,
                    child: dataBag == null
                        ? const SizedBox()
                        : DashboardGrid(
                            dataBag: dataBag!,
                            crossAxisCount: 3,
                            topPadding: 12,
                            elementPadding: 48,
                            leftPadding: 12,
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
                                case typeSchedules:
                                  _navigateToProjectList();
                                  break;
                              }
                            },
                            gridPadding: 80,
                          ),
                  ),
                  GeoActivity(
                    width: (size.width / 2) - 140,
                    forceRefresh: true,
                    thinMode: false,
                    showPhoto: (photo) {
                      _displayPhoto(photo);
                    },
                    showVideo: (video) {
                      _displayVideo(video);
                    },
                    showAudio: (audio) {
                      _displayAudio(audio);
                    },
                    showUser: (user) {},
                    showLocationRequest: (req) {},
                    showLocationResponse: (resp) {
                      _navigateToLocationResponseMap(resp);
                    },
                    showGeofenceEvent: (event) {
                      _navigateToGeofenceMap(event);
                    },
                    showProjectPolygon: (polygon) async {
                      var proj = await cacheManager.getProjectById(projectId: polygon.projectId!);
                      if (proj != null) {
                        _navigateToProjectMap(proj);
                      }
                    },
                    showProjectPosition: (position) async {
                      var proj = await cacheManager.getProjectById(projectId: position.projectId!);
                      if (proj != null) {
                        _navigateToProjectMap(proj);
                      }
                    },
                    showOrgMessage: (message) {},
                  ),
                ],
              );
            },
          ),
          busy
              ? const Positioned(
                  left: 80,
                  top: 140,
                  child: Card(
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          backgroundColor: Colors.pink,
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox(),
          _showPhoto
              ? Positioned(
                  left: extPadding,
                  right: extPadding,
                  top: 0,
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
                        child: PhotoCard(
                            photo: photo!,
                            onMapRequested: onMapRequested,
                            onRatingRequested: onRatingRequested),
                      ),
                    ),
                  ))
              : const SizedBox(),
          _showVideo
              ? Positioned(
                  left: padding,
                  right: padding,
                  top: top,
                  child: VideoPlayerTablet(
                    video: video!,
                    width: 400,
                    onCloseRequested: () {
                      setState(() {
                        _showVideo = false;
                      });
                    },
                  ))
              : const SizedBox(),
          _showAudio
              ? Positioned(
                  left: padding,
                  right: padding,
                  top: 12,
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
          _showRatingAdder
              ? Positioned(
                  left: 200,
                  right: 200,
                  top: 60,
                  child: RatingAdder(
                    photo: photo,
                    audio: audio,
                    video: video,
                    width: 400.0,
                    onDone: () {
                      setState(() {
                        _showRatingAdder = false;
                      });
                    },
                    elevation: 8.0,
                  ))
              : const SizedBox(),
        ],
      ),
    ));
  }
}
