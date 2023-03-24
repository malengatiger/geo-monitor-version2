import 'package:flutter/material.dart';
import 'package:geo_monitor/initializer.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/functions.dart';
import 'package:geofence_service/geofence_service.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../l10n/translation_handler.dart';
import '../../library/data/user.dart';
import '../../library/generic_functions.dart';
import '../../library/geofence/geofencer_two.dart';
import 'dashboard_portrait.dart';
import 'dashboard_tablet.dart';

class DashboardMain extends StatefulWidget {
  const DashboardMain({
    Key? key,
  }) : super(key: key);
  @override
  DashboardMainState createState() => DashboardMainState();
}

class DashboardMainState extends State<DashboardMain>
    with SingleTickerProviderStateMixin {
  User? user;
  static const mm = '🌎🌎🌎🌎🌎🌎DashboardMain: 🔵🔵🔵';
  bool initializing = false;
  String? initializingText;

  @override
  void initState() {
    super.initState();
    _initialize();
    _getUser();
  }

  void _initialize() async {
    setState(() {
      initializing = true;
    });
    try {
      await initializer.initializeGeo();
      final sett = await prefsOGx.getSettings();
      if (sett != null) {
        initializingText = await mTx.translate('initializing', sett.locale!);
      }
    } catch (e) {
      pp(e);
      if (mounted) {
        showToast(message: '$e', context: context);
      }
    }
    setState(() {
      initializing = false;
    });
  }

  void _getUser() async {
    user = await prefsOGx.getUser();
    pp('$mm starting to cook with Gas!');
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    if (initializing) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: SizedBox(width: 400, height: 300,
            child: Card(
              elevation: 8,
              shape: getRoundedBorder(radius: 16),
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 48,),
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(
                      strokeWidth: 4, backgroundColor: Colors.pink,
                    ),),
                    const SizedBox(height: 24,),
                    Text(initializingText == null
                        ? 'Initializing ...'
                        : initializingText!, style: myTextStyleLarge(context),),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return user == null
        ? const SizedBox()
        : WillStartForegroundTask(
            onWillStart: () async {
              pp('\n\n\n$mm WillStartForegroundTask: onWillStart - what do we do now, Boss? 🌎🌎🌎🌎🌎🌎\n\n');
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
                  return DashboardTablet(
                    user: user!,
                  );
                },
                landscape: (context) {
                  return DashboardTablet(
                    user: user!,
                  );
                },
              ),
            ),
          );
  }
}
