import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/downloader.dart';
import 'package:geo_monitor/library/data/activity_model.dart';
import 'package:geo_monitor/library/ui/maps/project_map_mobile.dart';
import 'package:geo_monitor/library/ui/maps/project_polygon_map_mobile.dart';
import 'package:geo_monitor/library/ui/media/list/project_media_list_mobile.dart';
import 'package:geo_monitor/ui/dashboard/dashboard_tablet_portrait.dart';
import 'package:geo_monitor/ui/dashboard/project_dashboard_grid.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../library/api/prefs_og.dart';
import '../../library/bloc/connection_check.dart';
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
import '../../library/functions.dart';
import '../../library/ui/camera/video_player_tablet.dart';
import '../../library/ui/maps/photo_map_tablet.dart';
import '../activity/geo_activity_tablet.dart';
import '../audio/audio_player_page.dart';

class ProjectDashboardTabletLandscape extends StatefulWidget {
  const ProjectDashboardTabletLandscape({Key? key, required this.project})
      : super(key: key);

  final Project project;

  @override
  ProjectDashboardTabletLandscapeState createState() =>
      ProjectDashboardTabletLandscapeState();
}

class ProjectDashboardTabletLandscapeState
    extends State<ProjectDashboardTabletLandscape>
    with SingleTickerProviderStateMixin {
  late AnimationController _gridViewAnimationController;
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

  User? deviceUser;
  DataBag? dataBag;
  @override
  void initState() {
    _gridViewAnimationController = AnimationController(vsync: this);
    super.initState();
    _listenForFCM();
    _getData(false);
  }

  var type = '';
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

  @override
  void dispose() {
    _gridViewAnimationController.dispose();
    super.dispose();
  }

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

  bool _showPhoto = false;
  bool _showVideo = false;
  bool _showAudio = false;
  final mm = ' 🍔 🍔 🍔 🍔 🍔 🍔ProjectDashboardTabletLandscape: ';

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
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Project Dashboard',
          style: myTextStyleLarge(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(64),
          child: SizedBox(),
        ),
      ),
      body: Stack(
        children: [
          Row(
            children: [
              SizedBox(
                width: (width / 2),
                // height: 500,
                child: Center(
                  child: ProjectDashboardGrid(
                      topPadding: 32,
                      showProjectName: true,
                      onTypeTapped: onTypeTapped,
                      project: widget.project),
                ),
              ),
              GeoActivityTablet(
                width: (width / 2) - 120,
                forceRefresh: true,
                project: widget.project,
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
                        child: PhotoCard(
                            photo: photo!,
                            onMapRequested: (photo) {
                              _navigateToPhotoMap();
                            },
                            onRatingRequested: (photo) {
                              pp('show rating ui');
                            }),
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
    ));
  }

  onTypeTapped(int p1) {
    switch (p1) {
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
  }
}
