import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/downloader.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../library/api/prefs_og.dart';
import '../../library/bloc/connection_check.dart';
import '../../library/bloc/fcm_bloc.dart';
import '../../library/bloc/organization_bloc.dart';
import '../../library/bloc/theme_bloc.dart';
import '../../library/data/audio.dart';
import '../../library/data/field_monitor_schedule.dart';
import '../../library/data/photo.dart';
import '../../library/data/project.dart';
import '../../library/data/project_polygon.dart';
import '../../library/data/project_position.dart';
import '../../library/data/settings_model.dart';
import '../../library/data/user.dart';
import '../../library/data/video.dart';
import '../../library/functions.dart';
import 'dashboard_tablet_portrait.dart';

class DashboardGrid extends StatefulWidget {
  const DashboardGrid(
      {Key? key,
      required this.onTypeTapped,
      this.totalHeight,
      this.topPadding})
      : super(key: key);
  final Function(int) onTypeTapped;
  final double? totalHeight;
  final double? topPadding;

  @override
  State<DashboardGrid> createState() => _DashboardGridState();
}

class _DashboardGridState extends State<DashboardGrid>
    with TickerProviderStateMixin {
  // late AnimationController _projectAnimationController;
  // late AnimationController _userAnimationController;
  // late AnimationController _photoAnimationController;
  // late AnimationController _videoAnimationController;
  // late AnimationController _positionAnimationController;
  // late AnimationController _polygonAnimationController;
  // late AnimationController _audioAnimationController;

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

  var busy = false;
  var _projects = <Project>[];
  var _users = <User>[];
  var _photos = <Photo>[];
  var _videos = <Video>[];
  var _projectPositions = <ProjectPosition>[];
  var _projectPolygons = <ProjectPolygon>[];
  var _schedules = <FieldMonitorSchedule>[];
  var _audios = <Audio>[];
  final dur = 2000;
  User? user;
  final mm = '🔵🔵🔵🔵 DashboardGrid:  🍎 ';

  late StreamSubscription<String> killSubscriptionFCM;

  @override
  void initState() {
    //_setAnimationControllers();
    super.initState();
    _setupData(false);
    _listenForFCM();
    _listenToOrgStreams();
  }

  void _setupData(bool forceRefresh) async {
    user = await prefsOGx.getUser();
    pp('$mm ..... getting org data ...');
    setState(() {
      busy = true;
    });
    try {
      var dataBag = await organizationBloc.getOrganizationData(
          organizationId: user!.organizationId!, forceRefresh: forceRefresh);
      _projects = dataBag.projects!;
      _users = dataBag.users!;
      _photos = dataBag.photos!;
      _videos = dataBag.videos!;
      _audios = dataBag.audios!;
      _projectPolygons = dataBag.projectPolygons!;
      _projectPositions = dataBag.projectPositions!;
      _schedules = dataBag.fieldMonitorSchedules!;

      setState(() {});
      // _projectAnimationController.reset();
      // _userAnimationController.reset();
      // _photoAnimationController.reset();
      // _videoAnimationController.reset();
      // _positionAnimationController.reset();
      // _polygonAnimationController.reset();
      // _audioAnimationController.reset();
      //
      // _projectAnimationController.forward().then((value) {
      //   _userAnimationController.forward().then((value) {
      //     _photoAnimationController.forward().then((value) {
      //       _videoAnimationController.forward().then((value) {
      //         _positionAnimationController.forward().then((value) {
      //           _polygonAnimationController.forward().then((value) {
      //             _audioAnimationController.forward();
      //           });
      //         });
      //       });
      //     });
      //   });
      // });
    } catch (e) {
      pp('$mm $e - will show snackbar ..');
      if (mounted) {
        showConnectionProblemSnackBar(
            context: context,
            message: 'Data refresh failed. Possible network problem - $e');
      }
    }
    setState(() {
      busy = false;
    });
  }

  // void _setAnimationControllers() {
  //   _projectAnimationController = AnimationController(
  //       duration: Duration(milliseconds: dur),
  //       reverseDuration: Duration(milliseconds: dur),
  //       vsync: this);
  //   _audioAnimationController = AnimationController(
  //       duration: Duration(milliseconds: dur),
  //       reverseDuration: Duration(milliseconds: dur),
  //       vsync: this);
  //   _userAnimationController = AnimationController(
  //       duration: Duration(milliseconds: dur),
  //       reverseDuration: Duration(milliseconds: dur),
  //       vsync: this);
  //   _photoAnimationController = AnimationController(
  //       duration: Duration(milliseconds: dur),
  //       reverseDuration: Duration(milliseconds: dur),
  //       vsync: this);
  //   _videoAnimationController = AnimationController(
  //       duration: Duration(milliseconds: dur),
  //       reverseDuration: Duration(milliseconds: dur),
  //       vsync: this);
  //   _polygonAnimationController = AnimationController(
  //       duration: Duration(milliseconds: dur),
  //       reverseDuration: Duration(milliseconds: dur),
  //       vsync: this);
  //   _positionAnimationController = AnimationController(
  //       duration: Duration(milliseconds: dur),
  //       reverseDuration: Duration(milliseconds: dur),
  //       vsync: this);
  // }

  void _listenToOrgStreams() async {
    projectSubscription = organizationBloc.projectStream.listen((event) {
      _projects = event;
      pp('$mm attempting to set state after projects delivered by stream: ${_projects.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
        // _projectAnimationController.forward();
      }
    });
    userSubscription = organizationBloc.usersStream.listen((event) {
      _users = event;
      pp('$mm attempting to set state after users delivered by stream: ${_users.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
        // _userAnimationController.forward();
      }
    });
    photoSubscription = organizationBloc.photoStream.listen((event) {
      _photos = event;
      pp('$mm attempting to set state after photos delivered by stream: ${_photos.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
      }
      // _photoAnimationController.forward();
    });

    videoSubscription = organizationBloc.videoStream.listen((event) {
      _videos = event;
      pp('$mm attempting to set state after videos delivered by stream: ${_videos.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
        // _videoAnimationController.forward();
      }
    });
    audioSubscription = organizationBloc.audioStream.listen((event) {
      _audios = event;
      pp('$mm attempting to set state after audios delivered by stream: ${_audios.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
        // _audioAnimationController.forward();
      }
    });
    projectPositionSubscription =
        organizationBloc.projectPositionsStream.listen((event) {
      _projectPositions = event;
      pp('$mm attempting to set state after projectPositions delivered by stream: ${_projectPositions.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
        // _projectAnimationController.forward();
      }
    });
    projectPolygonSubscription =
        organizationBloc.projectPolygonsStream.listen((event) {
      _projectPolygons = event;
      pp('$mm attempting to set state after projectPolygons delivered by stream: ${_projectPolygons.length} ... mounted: $mounted');
      if (mounted) {
        setState(() {});
        // _projectAnimationController.forward();
      }
    });

    schedulesSubscription =
        organizationBloc.fieldMonitorScheduleStream.listen((event) {
      _schedules = event;
      pp('$mm attempting to set state after schedules delivered by stream: ${_schedules.length} ... mounted: $mounted');

      if (mounted) {
        setState(() {});
        // _projectAnimationController.forward();
      }
    });
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
          _audios = await organizationBloc.getAudios(
              organizationId: user!.organizationId!, forceRefresh: false);
        }
      });
      projectPositionSubscriptionFCM =
          fcmBloc.projectPositionStream.listen((ProjectPosition message) async {
        pp('$mm: 🍎 🍎 projectPositionSubscriptionFCM position arrived... 🍎 🍎');
        if (mounted) {
          _projectPositions = await organizationBloc.getProjectPositions(
              organizationId: user!.organizationId!, forceRefresh: false);
        }
      });
      projectPolygonSubscriptionFCM =
          fcmBloc.projectPolygonStream.listen((ProjectPolygon message) async {
        pp('$mm: 🍎 🍎 projectPolygonSubscriptionFCM polygon arrived... 🍎 🍎');
        if (mounted) {
          _projectPolygons = await organizationBloc.getProjectPolygons(
              organizationId: user!.organizationId!, forceRefresh: false);
        }
      });
    } else {
      pp('App is running on the Web 👿👿👿firebase messaging is OFF 👿👿👿');
    }
  }

  @override
  void dispose() {
    // _projectAnimationController.dispose();
    // _photoAnimationController.dispose();
    // _videoAnimationController.dispose();
    // _audioAnimationController.dispose();
    // _positionAnimationController.dispose();
    // _polygonAnimationController.dispose();

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

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: widget.topPadding == null ? 48 : widget.topPadding!,
            ),
            user == null
                ? const SizedBox()
                : SizedBox(height: 100, child: Headline(user: user!)),
            SizedBox(
              height: widget.totalHeight == null ? 900 : widget.totalHeight!,
              child: Padding(
                padding: const EdgeInsets.all(60.0),
                child: GridView.count(
                  crossAxisCount: 3,
                  children: [
                    GestureDetector(
                      onTap: () {
                        pp('$mm widget on tapped: typeProjects $typeProjects ...');
                        widget.onTypeTapped(typeProjects);
                      },
                      child: DashboardElement(
                        title: 'Projects',
                        number: _projects.length,
                        onTapped: () {
                          widget.onTypeTapped(typeProjects);
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        pp('$mm widget on tapped: typeUsers $typeUsers ...');

                        widget.onTypeTapped(typeUsers);
                      },
                      child: DashboardElement(
                        title: 'Members',
                        number: _users.length,
                        onTapped: () {
                          widget.onTypeTapped(typeUsers);
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        pp('$mm widget on tapped: typePhotos $typePhotos ...');

                        widget.onTypeTapped(typePhotos);
                      },
                      child: DashboardElement(
                        title: 'Photos',
                        number: _photos.length,
                        onTapped: () {
                          widget.onTypeTapped(typePhotos);
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        pp('$mm widget on tapped: typeVideos $typeVideos ...');

                        widget.onTypeTapped(typeVideos);
                      },
                      child: DashboardElement(
                        title: 'Videos',
                        number: _videos.length,
                        onTapped: () {
                          widget.onTypeTapped(typeVideos);
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        pp('$mm widget on tapped: typeAudios $typeAudios ...');

                        widget.onTypeTapped(typeAudios);
                      },
                      child: DashboardElement(
                        title: 'Audio Clips',
                        number: _audios.length,
                        onTapped: () {
                          widget.onTypeTapped(typeAudios);
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        pp('$mm widget on tapped: typePositions $typePositions ...');

                        widget.onTypeTapped(typePositions);
                      },
                      child: DashboardElement(
                        title: 'Locations',
                        number: _projectPositions.length,
                        onTapped: () {
                          widget.onTypeTapped(typePositions);
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        pp('$mm widget on tapped: typePolygons $typePolygons ...');

                        widget.onTypeTapped(typePolygons);
                      },
                      child: DashboardElement(
                        title: 'Areas',
                        number: _projectPolygons.length,
                        onTapped: () {
                          widget.onTypeTapped(typePolygons);
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        pp('$mm widget on tapped: typeSchedules $typeSchedules ...');

                        widget.onTypeTapped(typeSchedules);
                      },
                      child: DashboardElement(
                        title: 'Schedules',
                        number: _schedules.length,
                        onTapped: () {
                          widget.onTypeTapped(typeSchedules);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

////
////
class DashboardElement extends StatelessWidget {
  const DashboardElement(
      {Key? key,
      required this.number,
      required this.title,
      this.height,
      this.topPadding,
      this.textStyle,
      this.labelTitleStyle,
      required this.onTapped})
      : super(key: key);
  final int number;
  final String title;
  final double? height, topPadding;
  final TextStyle? textStyle, labelTitleStyle;
  final Function() onTapped;

  @override
  Widget build(BuildContext context) {
    var style = GoogleFonts.secularOne(
        textStyle: Theme.of(context).textTheme.titleLarge,
        fontWeight: FontWeight.w900);
    return GestureDetector(
      onTap: (){
        onTapped();
      },
      child: Card(
        shape: getRoundedBorder(radius: 16),
        child: SizedBox(
          height: height == null ? 240 : height!,
          child: Center(
            child: Column(
              children: [
                SizedBox(
                  height: topPadding == null ? 40 : topPadding!,
                ),
                Text('$number', style: textStyle == null ? style : textStyle!),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  title,
                  style: Styles.greyLabelSmall,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
