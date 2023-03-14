import 'package:flutter/material.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/data/audio.dart';
import 'package:geo_monitor/library/data/photo.dart';
import 'package:geo_monitor/library/data/video.dart';
import 'package:geo_monitor/library/ui/settings/settings_form.dart';
import 'package:geo_monitor/ui/activity/geo_activity.dart';
import 'package:page_transition/page_transition.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../../l10n/translation_handler.dart';
import '../../data/location_response.dart';
import '../maps/location_response_map.dart';

class SettingsTablet extends StatefulWidget {
  const SettingsTablet({Key? key}) : super(key: key);

  @override
  SettingsTabletState createState() => SettingsTabletState();
}

class SettingsTabletState extends State<SettingsTablet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getTitles();
  }
  String? title;
  void _getTitles() async {
    var sett = await prefsOGx.getSettings();
    title = await mTx.tx('settings', sett!.locale!);
    setState(() {

    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    var size = MediaQuery.of(context).size;
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title:   Text(title == null?'Settings': title!),
      ),
      body: OrientationLayoutBuilder(landscape: (ctx) {
        return Padding(
          padding: const EdgeInsets.only(
              left: 28.0, right: 28, top: 56.0, bottom: 28.0),
          child: Row(
            children: [
              SizedBox(
                width: size.width / 2,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: SettingsForm(
                    padding: 32,
                  ),
                ),
              ),
              const SizedBox(
                width: 24.0,
              ),
              GeoActivity(
                  width: (size.width / 2) - 80,
                  thinMode: false,
                  showPhoto: showPhoto,
                  showVideo: showVideo,
                  showAudio: showAudio,
                  showUser: (user) {},
                  showLocationRequest: (req) {},
                  showLocationResponse: (resp) {
                    _navigateToLocationResponseMap(resp);
                  },
                  showGeofenceEvent: (event) {},
                  showProjectPolygon: (polygon) {},
                  showProjectPosition: (position) {},
                  showOrgMessage: (message) {},
                  forceRefresh: false),
            ],
          ),
        );
      }, portrait: (ctx) {
        return Row(
          children: [
            SizedBox(
              width: (size.width / 2) + 64,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: SettingsForm(
                  padding: 24,
                ),
              ),
            ),
            const SizedBox(
              width: 4.0,
            ),
            GeoActivity(
                width: (size.width / 2) - 80,
                thinMode: false,
                showPhoto: showPhoto,
                showVideo: showVideo,
                showAudio: showAudio,
                showUser: (user) {},
                showLocationRequest: (req) {},
                showLocationResponse: (resp) {
                  _navigateToLocationResponseMap(resp);
                },
                showGeofenceEvent: (event) {},
                showProjectPolygon: (polygon) {},
                showProjectPosition: (position) {},
                showOrgMessage: (message) {},
                forceRefresh: false),
          ],
        );
      }),
    ));
  }

  void _navigateToLocationResponseMap(LocationResponse locationResponse) async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: LocationResponseMap(
              locationResponse: locationResponse!,
            )));
  }

  showPhoto(Photo p1) {}

  showVideo(Video p1) {}

  showAudio(Audio p1) {}
}
