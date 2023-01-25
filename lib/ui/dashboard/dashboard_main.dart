import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

import 'dashboard_desktop.dart';
import 'dashboard_mobile.dart';
import 'dashboard_tablet.dart';


class DashboardMain extends StatefulWidget {

  const DashboardMain({Key? key, }) : super(key: key);
  @override
  DashboardMainState createState() => DashboardMainState();
}

class DashboardMainState extends State<DashboardMain>
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
      mobile: const DashboardMobile(
      ),
      tablet: const DashboardTablet(
      ),
      desktop: const DashboardDesktop(
      ),
    );
  }
}
