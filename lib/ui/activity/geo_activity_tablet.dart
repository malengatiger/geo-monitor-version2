import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geo_monitor/library/data/activity_model.dart';
import 'package:geo_monitor/library/data/geofence_event.dart';
import 'package:geo_monitor/ui/activity/activity_list_mobile.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../library/bloc/fcm_bloc.dart';
import '../../library/data/audio.dart';
import '../../library/data/photo.dart';
import '../../library/data/project.dart';
import '../../library/data/project_polygon.dart';
import '../../library/data/project_position.dart';
import '../../library/data/user.dart';
import '../../library/data/video.dart';
import '../../library/functions.dart';
import '../../library/generic_functions.dart';
import 'activity_list_tablet.dart';

class GeoActivity extends StatefulWidget {
  const GeoActivity({
    Key? key,
    required this.width,
    required this.thinMode,
    required this.showPhoto,
    required this.showVideo,
    required this.showAudio,
    this.user,
    this.project,
    required this.forceRefresh,
  }) : super(key: key);
  final double width;
  final bool thinMode;

  final Function(Photo) showPhoto;
  final Function(Video) showVideo;
  final Function(Audio) showAudio;

  final User? user;
  final Project? project;
  final bool forceRefresh;

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
  late StreamSubscription<GeofenceEvent> geofenceSubscriptionFCM;
  late StreamSubscription<ActivityModel> activitySubscriptionFCM;

  ScrollController listScrollController = ScrollController();

  final mm = '❇️❇️❇️❇️❇️ GeoActivityTablet: ';

  bool busy = false;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listenForFCM();
  }

  int count = 0;

  void _listenForFCM() async {
    var android = UniversalPlatform.isAndroid;
    var ios = UniversalPlatform.isIOS;
    if (android || ios) {
      pp('$mm 🍎🍎 _listen to FCM message streams ... 🍎🍎 '
          'geofence stream via geofenceSubscriptionFCM...');

      activitySubscriptionFCM =
          fcmBloc.activityStream.listen((ActivityModel event) {
        pp('$mm: 🍎activitySubscriptionFCM: 🍎 ActivityModel: '
            ' ${event.toJson()} arrived: ${event.date} ');
        if (mounted) {
          pp('$mm activitySubscriptionFCM: DOING NOTHING!!!!!!!!!!!!!!');
          setState(() {});
        }
      });

      geofenceSubscriptionFCM =
          fcmBloc.geofenceStream.listen((GeofenceEvent event) {
        pp('$mm: 🍎geofenceSubscriptionFCM: 🍎 GeofenceEvent: '
            'user ${event.user!.name} arrived: ${event.projectName} ');
        if (mounted) {
          showToast(
              message: '${event.user!.name!} arrived at ${event.projectName}',
              context: context);
          setState(() {});
        }
      });
    } else {
      pp('App is running on the Web 👿👿👿firebase messaging is OFF 👿👿👿');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: widget.width,
          child: ScreenTypeLayout(
            mobile: ActivityListMobile(
              project: widget.project,
              user: widget.user,
              onPhotoTapped: (photo) {
                widget.showPhoto(photo);
              },
              onVideoTapped: (video) {
                widget.showVideo(video);
              },
              onAudioTapped: (audio) {
                widget.showAudio(audio);
              },
              onUserTapped: (user) {},
              onProjectTapped: (project) {},
              onProjectPositionTapped: (projectPosition) {},
              onPolygonTapped: (projectPolygon) {},
              onGeofenceEventTapped: (geofenceEvent) {},
              onOrgMessage: (orgMessage) {},
            ),
            tablet: OrientationLayoutBuilder(
              portrait: (context) {
                return ActivityListTablet(
                  user: widget.user,
                  project: widget.project,
                  width: widget.width,
                  onPhotoTapped: (photo) {
                    widget.showPhoto(photo);
                  },
                  onVideoTapped: (video) {
                    widget.showVideo(video);
                  },
                  onAudioTapped: (audio) {
                    widget.showAudio(audio);
                  },
                  onUserTapped: (user) {},
                  onProjectTapped: (project) {},
                  onProjectPositionTapped: (projectPosition) {},
                  onPolygonTapped: (projectPolygon) {},
                  onGeofenceEventTapped: (geofenceEvent) {},
                  onOrgMessage: (orgMessage) {},
                  thinMode: widget.thinMode,
                );
              },
              landscape: (context) {
                return ActivityListTablet(
                  width: widget.width,
                  thinMode: widget.thinMode,
                  project: widget.project,
                  onPhotoTapped: (photo) {
                    widget.showPhoto(photo);
                  },
                  onVideoTapped: (video) {
                    widget.showVideo(video);
                  },
                  onAudioTapped: (audio) {
                    widget.showAudio(audio);
                  },
                  onUserTapped: (user) {},
                  onProjectTapped: (project) {},
                  onProjectPositionTapped: (projectPosition) {},
                  onPolygonTapped: (projectPolygon) {},
                  onGeofenceEventTapped: (geofenceEvent) {},
                  onOrgMessage: (orgMessage) {},
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
