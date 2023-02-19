import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geo_monitor/library/data/activity_model.dart';
import 'package:geo_monitor/library/ui/maps/project_map_mobile.dart';
import 'package:geo_monitor/library/ui/media/list/project_media_list_mobile.dart';
import 'package:geo_monitor/ui/activity/geo_activity_tablet.dart';
import 'package:geo_monitor/ui/dashboard/dashboard_tablet_portrait.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../library/api/prefs_og.dart';
import '../../library/bloc/connection_check.dart';
import '../../library/bloc/downloader.dart';
import '../../library/bloc/fcm_bloc.dart';
import '../../library/bloc/project_bloc.dart';
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
import '../../library/emojis.dart';
import '../../library/functions.dart';
import '../../library/ui/camera/video_player_tablet.dart';
import '../../library/ui/maps/photo_map_tablet.dart';
import '../../library/ui/maps/project_polygon_map_mobile.dart';
import '../audio/audio_player_page.dart';
import 'dashboard_grid.dart';

class ProjectDashboardTabletPortrait extends StatefulWidget {
  const ProjectDashboardTabletPortrait({
    Key? key,
    required this.project,
  }) : super(key: key);
  final Project project;
  @override
  ProjectDashboardTabletPortraitState createState() =>
      ProjectDashboardTabletPortraitState();
}

class ProjectDashboardTabletPortraitState
    extends State<ProjectDashboardTabletPortrait>
    with TickerProviderStateMixin {
  var busy = false;
  User? user;

  static const mm = '🎽🎽🎽🎽🎽🎽 ProjectDashboardTabletPortrait: 🎽';
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
  late AnimationController _gridViewAnimationController;
  bool networkAvailable = false;
  final dur = 600;
  DataBag? dataBag;
  User? deviceUser;
  var type = '';

  @override
  void initState() {
    _gridViewAnimationController = AnimationController(
        duration: const Duration(milliseconds: 3000),
        reverseDuration: const Duration(milliseconds: 3000),
        vsync: this);
    super.initState();
    _listenForFCM();
    _getData(false);
  }

  void _getData(bool forceRefresh) async {
    pp('$mm ............................................Refreshing data ....');
    deviceUser = await prefsOGx.getUser();
    if (deviceUser != null) {
      if (deviceUser!.userType == UserType.orgAdministrator) {
        type = 'Administrator';
      }
      if (deviceUser!.userType == UserType.orgExecutive) {
        type = 'Executive';
      }
      if (deviceUser!.userType == UserType.fieldMonitor) {
        type = 'Field Monitor';
      }
    } else {
      throw Exception('No user cached on device');
    }

    _gridViewAnimationController.reverse().then((value) async {
      if (mounted) {
        setState(() {
          busy = true;
        });
        await _doTheWork(forceRefresh);
        _gridViewAnimationController.forward();
      }
    });
  }

  Future<void> _doTheWork(bool forceRefresh) async {
    try {
      if (deviceUser == null) {
        throw Exception("Tax man is fucked! User is not found");
      }
      await _getProjectData(widget.project.projectId!, forceRefresh);
      setState(() {});
      _gridViewAnimationController.forward();
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

  Future _getProjectData(String projectId, bool forceRefresh) async {
    dataBag = await projectBloc.getProjectData(
        projectId: projectId, forceRefresh: forceRefresh);
  }

  void _listenForFCM() async {
    var android = UniversalPlatform.isAndroid;
    var ios = UniversalPlatform.isIOS;
    if (android || ios) {
      pp('$mm 🍎 🍎 _listen to FCM message streams ... 🍎 🍎');
      pp('$mm ... _listenToFCM activityStream ...');

      activitySubscriptionFCM =
          fcmBloc.activityStream.listen((ActivityModel model) {
        pp('\n\n$mm activityStream delivered activity data ... ${model.toJson()}\n\n');
        // if (isActivityValid(model)) {
        //   models.insert(0, model);
        // }
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

  final _key = GlobalKey<ScaffoldState>();

  _navigateToMedia() async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: ProjectMediaListMobile(
              project: widget.project,
            )));
  }

  _navigateToPositionsMap() async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: ProjectMapMobile(
              project: widget.project,
            )));
  }

  _navigateToPolygonsMap() async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: ProjectPolygonMapMobile(
              project: widget.project,
            )));
  }

  Photo? photo;
  Video? video;
  Audio? audio;
  bool _showPhoto = false;
  bool _showVideo = false;
  bool _showAudio = false;
  void showPhoto(Photo photo) {
    this.photo = photo;
    setState(() {
      _showPhoto = true;
      _showVideo = false;
      _showAudio = false;
    });
  }

  void showVideo(Video video) {
    this.video = video;
    setState(() {
      _showPhoto = false;
      _showVideo = true;
      _showAudio = false;
    });
  }

  void showAudio(Audio audio) {
    this.audio = audio;
    setState(() {
      _showPhoto = false;
      _showVideo = false;
      _showAudio = true;
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
              child: PhotoMapTablet(
                photo: photo!,
              )));
    }
  }

  @override
  void dispose() {
    _gridViewAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final width1 = width - 300;
    const width2 = 280.0;
    return SafeArea(
      child: Scaffold(
        key: _key,
        appBar: AppBar(
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(160),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    'Project Dashboard',
                    style: myTextStyleLarge(context),
                  ),
                  const SizedBox(
                    height: 48,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        widget.project.name!,
                        style: GoogleFonts.lato(
                            textStyle: Theme.of(context).textTheme.titleLarge,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).primaryColor),
                      ),
                      // const SizedBox(
                      //   width: 100,
                      // ),
                      IconButton(
                          onPressed: _navigateToPositionsMap,
                          icon: const Icon(
                            Icons.map,
                            size: 28.0,
                          ))
                    ],
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
                    backgroundColor: Colors.pink,
                  ),
                ),
              )
            : Stack(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: width1,
                        child: dataBag == null
                            ? const SizedBox()
                            : DashboardGrid(
                                topPadding: 48,
                                crossAxisCount: 3,
                                gridPadding: 48,
                                elementPadding: 64,
                                dataBag: dataBag!,
                                onTypeTapped: (type) {
                                  switch (type) {
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
                                },
                              ),
                      ),
                      SizedBox(
                        width: width2,
                        child: GeoActivityTablet(
                          width: width2,
                          project: widget.project,
                          thinMode: true,
                          showPhoto: (photo) {
                            showPhoto(photo);
                          },
                          showVideo: (video) {
                            showVideo(video);
                          },
                          showAudio: (audio) {
                            showAudio(audio);
                          },
                          forceRefresh: true,
                        ),
                      )
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
                                child: photo == null
                                    ? const SizedBox()
                                    : PhotoCard(
                                        photo: photo!,
                                        onMapRequested: (photo) {},
                                        onRatingRequested: (photo) {}),
                              ),
                            ),
                          ))
                      : const SizedBox(),
                  _showVideo
                      ? Positioned(
                          left: 20,
                          top: -8,
                          child: SizedBox(
                            width: 360,
                            height: height - 360,
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
