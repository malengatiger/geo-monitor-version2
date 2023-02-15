import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geo_monitor/library/data/activity_model.dart';
import 'package:geo_monitor/library/data/geofence_event.dart';
import 'package:geo_monitor/ui/activity/activity_list_mobile.dart';
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

class GeoActivityMobile extends StatefulWidget {
  const GeoActivityMobile({
    Key? key,
    required this.showPhoto,
    required this.showVideo,
    required this.showAudio,
  }) : super(key: key);

  final Function(Photo) showPhoto;
  final Function(Video) showVideo;
  final Function(Audio) showAudio;

  @override
  GeoActivityMobileState createState() => GeoActivityMobileState();
}

class GeoActivityMobileState extends State<GeoActivityMobile>
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

  final mm = '❇️❇️❇️❇️❇️ GeoActivityMobile: ';

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
    final width = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Project Activity',
            style: myTextStyleLargePrimaryColor(context),
          ),
        ),
        body: ActivityListMobile(
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
      ),
    );
  }
}
