import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geo_monitor/library/data/activity_model.dart';
import 'package:geo_monitor/library/data/activity_type_enum.dart';
import 'package:geo_monitor/library/hive_util.dart';
import 'package:geo_monitor/library/ui/maps/photo_map_tablet.dart';
import 'package:page_transition/page_transition.dart';
import 'package:photo_view/photo_view.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:universal_platform/universal_platform.dart';

import '../bloc/fcm_bloc.dart';
import '../data/audio.dart';
import '../data/photo.dart';
import '../data/project.dart';
import '../data/project_polygon.dart';
import '../data/project_position.dart';
import '../data/settings_model.dart';
import '../data/user.dart';
import '../data/video.dart';
import '../functions.dart';
import 'camera/chewie_video_player.dart';
import 'maps/project_map_main.dart';

class GeoActivity extends StatefulWidget {
  const GeoActivity({
    Key? key,
    required this.width,
  }) : super(key: key);
  final double width;
  @override
  GeoActivityState createState() => GeoActivityState();
}

class GeoActivityState extends State<GeoActivity>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late StreamSubscription<Photo> photoSubscriptionFCM;
  late StreamSubscription<Video> videoSubscriptionFCM;
  late StreamSubscription<Audio> audioSubscriptionFCM;
  late StreamSubscription<ProjectPosition> projectPositionSubscriptionFCM;
  late StreamSubscription<ProjectPolygon> projectPolygonSubscriptionFCM;
  late StreamSubscription<Project> projectSubscriptionFCM;
  late StreamSubscription<User> userSubscriptionFCM;
  late StreamSubscription<SettingsModel> settingsSubscriptionFCM;
  late StreamSubscription<ActivityModel> activitySubscriptionFCM;

  ScrollController listScrollController = ScrollController();

  final mm = ' ❇️ ❇️ ❇️ ❇️ ❇️ GeoActivity: ';

  var models = <ActivityModel>[];
  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listenForFCM();
    _getData();
  }

  void _getData() async {
    models = await cacheManager.getActivities();
    setState(() {});
  }

  void _listenForFCM() async {
    var android = UniversalPlatform.isAndroid;
    var ios = UniversalPlatform.isIOS;
    pp('$mm 🍎🍎🍎🍎 _listenForFCM: FCM should be initialized!!  ... 🍎 🍎');
    if (android || ios) {
      pp('$mm 🍎🍎 _listen to FCM message streams ... 🍎🍎');
      activitySubscriptionFCM =
          fcmBloc.activityStream.listen((ActivityModel act) async {
        models.add(act);
        if (mounted) {
          pp('$mm: 🍎🍎 activity arrived: ${act.userName} '
              '- activityType: ${act.activityType}... 🍎🍎');
          setState(() {});
        }
      });
    } else {
      pp('App is running on the Web 👿👿👿firebase messaging is OFF 👿👿👿');
    }
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

  void _navigateToPlayVideo() {
    pp('... play audio from internets');
    // Navigator.push(
    //     context,
    //     PageTransition(
    //         type: PageTransitionType.leftToRightWithFade,
    //         alignment: Alignment.topLeft,
    //         duration: const Duration(milliseconds: 1000),
    //         child: ChewieVideoPlayer(project: widget.project, videoIndex: videoIndex,)));
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: widget.width - 24,
            child: ScreenTypeLayout(
              mobile: ActivityList(
                width: widget.width,
                models: models,
                onPhotoTapped: (photo) {
                  _displayPhoto(photo);
                },
                onVideoTapped: (video) {
                  _displayVideo(video);
                },
                onAudioTapped: (audio) {
                  _displayAudio(audio);
                },
              ),
              tablet: OrientationLayoutBuilder(
                portrait: (context) {
                  return ActivityList(
                    width: widget.width,
                    models: models,
                    onPhotoTapped: (photo) {
                      _displayPhoto(photo);
                    },
                    onVideoTapped: (video) {
                      _displayVideo(video);
                    },
                    onAudioTapped: (audio) {
                      _displayAudio(audio);
                    },
                  );
                },
                landscape: (context) {
                  return ActivityList(
                    width: widget.width,
                    models: models,
                    onPhotoTapped: (photo) {
                      _displayPhoto(photo);
                    },
                    onVideoTapped: (video) {
                      _displayVideo(video);
                    },
                    onAudioTapped: (audio) {
                      _displayAudio(audio);
                    },
                  );
                },
              ),
            ),
          ),
        ),
        _showPhoto
            ? Positioned(
                left: 0,
                top: 60,
                child: SizedBox(
                  width: 400,
                  height: 600,
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
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${photo!.projectName}',
                                    style: myTextStyleLarge(context),
                                  ),
                                  IconButton(onPressed: (){
                                    pp('$mm .... put photo on a map!');
                                    _navigateToPhotoMap();

                                  }, icon:  Icon(Icons.location_on,
                                    color: Theme.of(context).primaryColor,
                                    size: 24,)),
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
                                        progressIndicatorBuilder: (context, url,
                                                downloadProgress) =>
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
                                        fadeInDuration:
                                            const Duration(milliseconds: 1500),
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
                child: Container(
                width: 480,
                height: 640,
                color: Colors.red,
              ))
            : const SizedBox(),
        _showAudio
            ? Positioned(
                child: Container(
                width: 480,
                height: 640,
                color: Colors.green,
              ))
            : const SizedBox(),
      ],
    );
  }
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({Key? key, required this.activityModel}) : super(key: key);
  final ActivityModel activityModel;
  @override
  Widget build(BuildContext context) {
    late Icon icon;
    late String message;
    switch (activityModel.activityType) {
      case ActivityType.photoAdded:
        icon = Icon(Icons.camera_alt, color: Theme.of(context).primaryColor);
        message = 'Photo added: ${activityModel.projectName}';
        break;
      case ActivityType.videoAdded:
        icon = Icon(Icons.video_camera_front,
            color: Theme.of(context).primaryColor);
        message = 'Video added: ${activityModel.projectName}';
        break;
      case ActivityType.audioAdded:
        icon = Icon(Icons.mic, color: Theme.of(context).primaryColor);
        message = 'Audio added: ${activityModel.projectName}';
        break;
      case ActivityType.positionAdded:
        icon = Icon(Icons.home, color: Theme.of(context).primaryColor);
        message = 'Project Position added: ${activityModel.projectName}';
        break;
      case ActivityType.polygonAdded:
        icon =
            Icon(Icons.circle_outlined, color: Theme.of(context).primaryColor);
        message = 'Project Area added: ${activityModel.projectName}';
        break;
      case ActivityType.settingsChanged:
        icon = Icon(Icons.settings, color: Theme.of(context).primaryColor);
        message = 'Settings changed or added';
        break;
      case ActivityType.userAddedOrModified:
        icon = Icon(Icons.person, color: Theme.of(context).primaryColor);
        message = 'User added or modified';
        break;
      case ActivityType.locationRequest:
        icon = Icon(Icons.location_on, color: Theme.of(context).primaryColor);
        message = 'Location requested';
        break;
      case ActivityType.locationResponse:
        icon =
            Icon(Icons.location_history, color: Theme.of(context).primaryColor);
        message = 'Location request responded to';
        break;
      case ActivityType.messageAdded:
        icon = Icon(Icons.message, color: Theme.of(context).primaryColor);
        message = 'Organization message added';
        break;
      case ActivityType.conditionAdded:
        icon = Icon(Icons.access_alarm, color: Theme.of(context).primaryColor);
        message = 'Project Condition added';
        break;
      case ActivityType.geofenceEventAdded:
        icon = Icon(Icons.person_2, color: Theme.of(context).primaryColor);
        message = 'Field worker arrived at Project';
        break;
      case ActivityType.kill:
        icon = Icon(Icons.cancel, color: Theme.of(context).primaryColor);
        message = 'User KILL request made';
        break;
      case ActivityType.projectAdded:
        icon = Icon(Icons.access_time, color: Theme.of(context).primaryColor);
        message = 'Project added: ${activityModel.projectName}';
        break;
      default:
        icon = Icon(
          Icons.ac_unit_rounded,
          color: Theme.of(context).primaryColor,
        );
        message = 'Something happened, Boss! ... but what?';
        break;
    }
    return Card(
      shape: getRoundedBorder(radius: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(
              height: 8,
            ),
            Row(
              children: [
                SizedBox(
                  width: 60,
                  child: icon,
                ),
                Text(
                  message,
                  style: myTextStyleSmall(context),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: ListTile(
                title: Text(
                  '${activityModel.userName}',
                  style: myTextStyleSmall(context),
                ),
                subtitle: Text(
                  getFormattedDateShortWithTime(activityModel.date!, context),
                  style: myTextStyleSmall(context),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ActivityList extends StatefulWidget {
  const ActivityList(
      {Key? key,
      required this.width,
      required this.models,
      required this.onPhotoTapped,
      required this.onVideoTapped,
      required this.onAudioTapped})
      : super(key: key);
  final double width;
  final List<ActivityModel> models;
  final Function(Photo) onPhotoTapped;
  final Function(Video) onVideoTapped;
  final Function(Audio) onAudioTapped;

  @override
  State<ActivityList> createState() => _ActivityListState();
}

class _ActivityListState extends State<ActivityList> {
  final ScrollController listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        listScrollController.animateTo(
            listScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.fastOutSlowIn);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(36.0),
      child: SizedBox(
        width: widget.width,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left:28.0),
                  child: Text('Activity Stream', style: myTextStyleMediumBold(context),),
                ),
                TextButton(
                    onPressed: () {
                      _scrollToBottom();
                    },
                    child: Text(
                      'Scroll to Bottom',
                      style: myTextStyleSmallPrimaryColor(context),
                    )),
              ],
            ),
            const SizedBox(
              height: 0,
            ),
            Expanded(
              child: ListView.builder(
                  itemCount: widget.models.length,
                  controller: listScrollController,
                  itemBuilder: (_, index) {
                    var act = widget.models.elementAt(index);
                    return GestureDetector(
                        onTap: () {
                          _handleTappedActivity(act);
                        },
                        child: ActivityCard(activityModel: act));
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTappedActivity(ActivityModel act) async {
    if (act.activityType == ActivityType.photoAdded) {
      if (act.typeId != null) {
        var photo = await cacheManager.getPhotoById(act.typeId!);
        pp('${photo!.toJson()}');
        widget.onPhotoTapped(photo);
      }
    }
    if (act.activityType == ActivityType.videoAdded) {
      if (act.typeId != null) {
        var video = await cacheManager.getVideoById(act.typeId!);
        pp('${video!.toJson()}');
        widget.onVideoTapped(video);
      }
    }
    if (act.activityType == ActivityType.audioAdded) {
      if (act.typeId != null) {
        var audio = await cacheManager.getAudioById(act.typeId!);
        pp('${audio!.toJson()}');
        widget.onAudioTapped(audio);
      }
    }
    if (act.activityType == ActivityType.positionAdded) {
      pp('position tapped, not implemented yet');
    }
    if (act.activityType == ActivityType.polygonAdded) {
      pp('polygon tapped, not implemented yet');
    }
  }
}
