import 'package:flutter/material.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/functions.dart';
import 'package:geo_monitor/ui/dashboard/dashboard_tablet_portrait.dart';
import 'package:geofence_service/geofence_service.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../library/bloc/fcm_bloc.dart';
import '../../library/data/user.dart';
import '../../library/geofence/geofencer_two.dart';
import 'dashboard_portrait.dart';
import 'dashboard_tablet_landscape.dart';

class DashboardMain extends StatefulWidget {
  const DashboardMain({
    Key? key,
  }) : super(key: key);
  @override
  DashboardMainState createState() => DashboardMainState();
}

class DashboardMainState extends State<DashboardMain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  var busy = false;
  User? user;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getUser();
  }

  void _getUser() async {
    user = await prefsOGx.getUser();
    setState(() {});

    fcmBloc.initialize();
    pp('DashboardMain: 🍎🍎🍎🍎 FCM should have started initialization!!  ... 🍎🍎');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return user == null
        ? const SizedBox()
        : WillStartForegroundTask(
            onWillStart: () async {
              pp('\n\n\n 🌎🌎🌎🌎🌎🌎WillStartForegroundTask: onWillStart - what do we do now, Boss? 🌎🌎🌎🌎🌎🌎\n\n');
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
            notificationTitle: 'Geo Service is running',
            notificationText: 'Tap to return to the app',
            foregroundTaskOptions: const ForegroundTaskOptions(),
            child: ScreenTypeLayout(
              mobile: const DashboardPortrait(),
              tablet: OrientationLayoutBuilder(
                portrait: (context) {
                  return DashboardTabletPortrait(
                    user: user!,
                  );
                },
                landscape: (context) {
                  return DashboardTabletLandscape(
                    user: user!,
                  );
                },
              ),
            ),
          );
  }
}
