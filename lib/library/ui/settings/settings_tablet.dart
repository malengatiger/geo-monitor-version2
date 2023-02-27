import 'package:flutter/material.dart';
import 'package:geo_monitor/library/data/audio.dart';
import 'package:geo_monitor/library/data/photo.dart';
import 'package:geo_monitor/library/data/video.dart';
import 'package:geo_monitor/library/ui/settings/settings_form.dart';
import 'package:geo_monitor/ui/activity/geo_activity.dart';
import 'package:responsive_builder/responsive_builder.dart';

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
        title: const Text('Geo Settings'),
      ),
      body: OrientationLayoutBuilder(landscape: (ctx) {
        return Padding(
          padding: const EdgeInsets.only(left: 28.0, right: 28, top: 28.0, bottom: 28.0),
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
              const SizedBox(width: 24.0,),
              GeoActivity(
                  width: (size.width / 2) - 80,
                  thinMode: false,
                  showPhoto: showPhoto,
                  showVideo: showVideo,
                  showAudio: showAudio,
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
            const SizedBox(width: 4.0,),
            GeoActivity(
                width: (size.width / 2) - 80,
                thinMode: false,
                showPhoto: showPhoto,
                showVideo: showVideo,
                showAudio: showAudio,
                forceRefresh: false),
          ],
        );
      }),
    ));
  }

  showPhoto(Photo p1) {}

  showVideo(Video p1) {}

  showAudio(Audio p1) {}
}
