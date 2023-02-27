import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/downloader.dart';
import 'package:geo_monitor/library/bloc/user_bloc.dart';
import 'package:geo_monitor/library/data/activity_model.dart';
import 'package:geo_monitor/library/ui/camera/video_player_tablet.dart';
import 'package:geo_monitor/library/ui/maps/photo_map_tablet.dart';
import 'package:geo_monitor/library/users/full_user_photo.dart';
import 'package:geo_monitor/ui/activity/geo_activity.dart';
import 'package:geo_monitor/ui/audio/audio_player_page.dart';
import 'package:geo_monitor/ui/dashboard/photo_card.dart';
import 'package:page_transition/page_transition.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../library/api/prefs_og.dart';
import '../../library/bloc/fcm_bloc.dart';
import '../../library/bloc/theme_bloc.dart';
import '../../library/cache_manager.dart';
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
import '../../library/functions.dart';
import '../../library/generic_functions.dart';
import '../../library/geofence/geofencer_two.dart';
import '../../library/ui/project_list/project_list_mobile.dart';
import 'user_dashboard_grid.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({
    Key? key,
    required this.user,
  }) : super(key: key);
  final User user;

  @override
  UserDashboardState createState() => UserDashboardState();
}

class UserDashboardState extends State<UserDashboard>
    with TickerProviderStateMixin {
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
  late StreamSubscription<GeofenceEvent> geofenceSubscription;
  late StreamSubscription<ActivityModel> activitySubscription;

  var busy = false;
  User? user;

  static const mm = '🎽🎽🎽🎽🎽🎽 UserDashboard: 🎽';
  bool networkAvailable = false;
  final dur = 3000;
  DataBag? dataBag;
  Photo? photo;
  Video? video;
  Audio? audio;
  bool _showPhoto = false;
  bool _showVideo = false;
  bool _showAudio = false;

  @override
  void initState() {
    _gridViewAnimationController = AnimationController(
        duration: Duration(milliseconds: dur),
        reverseDuration: Duration(milliseconds: dur),
        vsync: this);
    super.initState();
    _setItems();
    _subscribeToGeofenceStream();
    _startTimer();
    _getData(false);
    _listenForFCM();
  }

  void _getData(bool forceRefresh) async {
    if (mounted) {
      setState(() {
        busy = true;
      });
    }
    try {
      user = await prefsOGx.getUser();
      dataBag = await userBloc.getUserData(
          userId: widget.user.userId!, forceRefresh: forceRefresh);
      _filterProjects();
      _gridViewAnimationController.forward();
    } catch (e) {
      pp(e);
      if (mounted) {
        showToast(message: '$e', context: context);
      }
    }
    if (mounted) {
      setState(() {
        busy = false;
      });
    }
  }

  void _filterProjects() async {
    var map = HashMap<String, Project>();
    for (var audio in dataBag!.audios!) {
      if (!map.containsKey(audio.projectId)) {
        var project =
            await cacheManager.getProjectById(projectId: audio.projectId!);
        map[audio.projectId!] = project!;
      }
    }
    for (var video in dataBag!.videos!) {
      if (!map.containsKey(video.projectId)) {
        var project =
            await cacheManager.getProjectById(projectId: video.projectId!);
        map[video.projectId!] = project!;
      }
    }
    for (var photo in dataBag!.photos!) {
      if (!map.containsKey(photo.projectId)) {
        var project =
            await cacheManager.getProjectById(projectId: photo.projectId!);
        map[photo.projectId!] = project!;
      }
    }
    //use filtered list in dataBag
    var list = map.values.toList();
    list.sort((a, b) => a.name!.compareTo(b.name!));
    pp('$mm filtered projects for user: ${list.length}');
    dataBag!.projects = list;
    if (mounted) {
      setState(() {});
    }
  }

  void _listenForFCM() async {
    var android = UniversalPlatform.isAndroid;
    var ios = UniversalPlatform.isIOS;
    if (android || ios) {
      pp('$mm 🍎 🍎 _listen to FCM message streams ... 🍎 🍎');

      activitySubscription =
          fcmBloc.activityStream.listen((ActivityModel model) async {
        _getData(false);
        if (mounted) {
          pp('$mm: 🍎 🍎 activity has arrived: ${model.date} ... 🍎 🍎');
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

  @override
  void dispose() {
    _gridViewAnimationController.dispose();
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

  int instruction = stayOnList;

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

  void _navigateToUserActivity() {
    var deviceType = getDeviceType();
    pp('$mm .................. _navigateToUserActivity .... deviceType: $deviceType');
    if (mounted) {
      if (deviceType == 'phone') {}
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(seconds: 1),
              child: GeoActivity(
                  user: widget.user,
                  width: 400,
                  thinMode: true,
                  showPhoto: _displayPhoto,
                  showVideo: _displayVideo,
                  showAudio: _displayAudio,
                  forceRefresh: true)));
    }
  }

  void _showUserPhotos() {
    pp('$mm ... _showUserPhotos ...');
  }

  void _showUserVideos() {
    pp('$mm ... _showUserVideos ...');
  }

  void _showUserAudios() {
    pp('$mm ... _showUserAudios ...');
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

  String getDeviceType() {
    final data = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
    return data.size.shortestSide < 600 ? 'phone' : 'tablet';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final ori = MediaQuery.of(context).orientation.name;
    var deviceType = getDeviceType();
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Member Dashboard'),
        actions: [
          IconButton(
              icon: Icon(
                Icons.access_alarm,
                size: 24,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: _navigateToUserActivity),
          IconButton(
            icon: Icon(
              Icons.refresh,
              size: 24,
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
                      backgroundColor: Colors.pink,
                    ),
                  ),
                ),
              ),
            )
          : Stack(
              children: [
                dataBag == null
                    ? const SizedBox()
                    :  ScreenTypeLayout(
                  mobile: UserDashboardGrid(user: widget.user,
                    dataBag: dataBag!,
                    width: width,
                    topPadding: 40,
                    gridPadding: 12,
                    crossAxisCount: 2,
                    onTypeTapped: (type) {
                      switch (type) {
                        case typePhotos:
                          _showUserPhotos();
                          break;
                        case typeVideos:
                          _showUserVideos();
                          break;
                        case typeAudios:
                          _showUserAudios();
                          break;
                      }
                    },),
                  tablet: OrientationLayoutBuilder(
                    portrait: (context) {
                      return Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: UserDashboardGrid(
                                user: widget.user,
                                dataBag: dataBag!,
                                width: (width /2),
                                topPadding: 40,
                                onTypeTapped: (type) {
                                  switch (type) {
                                    case typePhotos:
                                      _showUserPhotos();
                                      break;
                                    case typeVideos:
                                      _showUserVideos();
                                      break;
                                    case typeAudios:
                                      _showUserAudios();
                                      break;
                                  }
                                },
                                gridPadding: 16,
                                crossAxisCount: 2,
                                leftPadding: 16),
                          ),
                          const SizedBox(width: 16,),
                          GeoActivity(
                              user: widget.user,
                              width: (width / 2) - 60,
                              thinMode: true,
                              showPhoto: _displayPhoto,
                              showVideo: _displayVideo,
                              showAudio: _displayAudio,
                              forceRefresh: true),
                        ],
                      );
                    },
                    landscape: (context) {
                      return Row(
                        children: [
                          UserDashboardGrid(
                              user: widget.user,
                              dataBag: dataBag!,
                              width: (width /2),
                              topPadding: 28,
                              elementPadding: 48,
                              onTypeTapped: (type) {
                                switch (type) {
                                  case typePhotos:
                                    _showUserPhotos();
                                    break;
                                  case typeVideos:
                                    _showUserVideos();
                                    break;
                                  case typeAudios:
                                    _showUserAudios();
                                    break;
                                }
                              },
                              gridPadding: 32,
                              crossAxisCount: 3,
                              leftPadding: 16),
                          // Container(width: (width/2), color: Colors.deepPurple,),
                          const SizedBox(width: 48,),
                          GeoActivity(
                              width: (width / 2) - 120,
                              thinMode: false,
                              user: widget.user,
                              showPhoto: _displayPhoto,
                              showVideo: _displayVideo,
                              showAudio: _displayAudio,
                              forceRefresh: true),
                        ],
                      );
                    },
                  ),
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
                                  onMapRequested: (mPhoto) {
                                    photo = mPhoto;
                                    _navigateToPhotoMap();
                                  },
                                  onRatingRequested: (photo) {
                                    pp('$mm ... start rating ...');
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
    );
  }
}
