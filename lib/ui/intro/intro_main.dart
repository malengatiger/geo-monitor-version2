import 'package:flutter/material.dart';
import 'package:geo_monitor/ui/intro/intro_page_viewer.dart';
import 'package:responsive_builder/responsive_builder.dart';

class IntroMain extends StatefulWidget {

  const IntroMain({Key? key, }) : super(key: key);
  @override
  IntroMainState createState() => IntroMainState();
}

class IntroMainState extends State<IntroMain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  var isBusy = false;

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
    return ScreenTypeLayout(
      mobile: const IntroPageViewerPortrait(
      ),
      tablet: OrientationLayoutBuilder(
        portrait: (context) {
          return const IntroPageViewerPortrait();
        },
        landscape: (context){
          return const IntroPageViewerLandscape();
        },
      ),
    );
  }
}
