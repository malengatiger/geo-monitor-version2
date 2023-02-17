import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';
import 'package:geo_monitor/library/ui/camera/video_player_tablet.dart';
import 'package:geo_monitor/library/ui/media/list/project_media_main.dart';
import 'package:geo_monitor/library/ui/settings/settings_main.dart';
import 'package:geo_monitor/ui/activity/geo_activity_tablet.dart';
import 'package:geo_monitor/ui/dashboard/dashboard_grid.dart';
import 'package:geo_monitor/ui/intro/intro_main.dart';
import 'package:page_transition/page_transition.dart';

import '../../library/api/prefs_og.dart';
import '../../library/bloc/downloader.dart';
import '../../library/data/audio.dart';
import '../../library/data/data_bag.dart';
import '../../library/data/photo.dart';
import '../../library/data/project.dart';
import '../../library/data/user.dart';
import '../../library/data/video.dart';
import '../../library/functions.dart';
import '../../library/generic_functions.dart';
import '../../library/ui/maps/photo_map_tablet.dart';
import '../../library/ui/maps/project_map_main.dart';
import '../../library/ui/project_list/project_chooser.dart';
import '../../library/ui/project_list/project_list_main.dart';
import '../../library/users/full_user_photo.dart';
import '../../library/users/list/user_list_main.dart';
import '../audio/audio_player_page.dart';

class DashboardTabletLandscape extends StatefulWidget {
  const DashboardTabletLandscape({Key? key, required this.user})
      : super(key: key);

  final User user;
  @override
  State<DashboardTabletLandscape> createState() =>
      _DashboardTabletLandscapeState();
}

class _DashboardTabletLandscapeState extends State<DashboardTabletLandscape> {
  final mm = '🍎🍎🍎🍎DashboardTabletLandscape: ';
  var users = <User>[];
  User? user;
  DataBag? dataBag;
  bool busy = false;

  @override
  void initState() {
    super.initState();
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
    pp('$mm .................. _navigateToIntro to Intro ....');
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

  Project? selectedProject;
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
    var size = MediaQuery.of(context).size;
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Geo Dashboard'),
        actions: [
          IconButton(
              icon: Icon(
                Icons.info_outline,
                size: 24,
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
      ),
      body: Stack(
        children: [
          Row(
            children: [
              SizedBox(
                width: (size.width / 2) + 60,
                child: dataBag == null
                    ? const SizedBox()
                    : DashboardGrid(
                        dataBag: dataBag!,
                        topPadding: 24,
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
                            case typeSchedules:
                              _showProjectDialog(typeSchedules);
                              break;
                          }
                        },
                      ),
              ),
              GeoActivityTablet(
                width: (size.width / 2) - 100,
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
              ),
            ],
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
                  left: 0,
                  top: 0,
                  child: SizedBox(
                    width: 420,
                    height: 640,
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
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 12,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${photo!.projectName}',
                                      style: myTextStyleMediumPrimaryColor(
                                          context),
                                    ),
                                    IconButton(
                                        onPressed: () {
                                          pp('$mm .... put photo on a map!');
                                          _navigateToPhotoMap();
                                        },
                                        icon: Icon(
                                          Icons.location_on,
                                          color: Theme.of(context).primaryColor,
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
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 2.0, vertical: 2.0),
                                  child: InteractiveViewer(
                                      child: CachedNetworkImage(
                                          fit: BoxFit.cover,
                                          progressIndicatorBuilder: (context,
                                                  url, downloadProgress) =>
                                              Center(
                                                  child: SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child: CircularProgressIndicator(
                                                          backgroundColor:
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                          value: downloadProgress
                                                              .progress))),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                          fadeInDuration: const Duration(
                                              milliseconds: 1500),
                                          fadeInCurve: Curves.easeInOutCirc,
                                          placeholderFadeInDuration:
                                              const Duration(milliseconds: 1500),
                                          imageUrl: photo!.url!)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ))
              : const SizedBox(),
          _showVideo
              ? Positioned(
                  left: 300,
                  right: 300,
                  top: 12,
                  child: VideoPlayerTabletPage(
                    video: video!,
                    onCloseRequested: () {
                      setState(() {
                        _showVideo = false;
                      });
                    },
                  ))
              : const SizedBox(),
          _showAudio
              ? Positioned(
                  left: 100,
                  right: 100,
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
        ],
      ),
    ));
  }
}
