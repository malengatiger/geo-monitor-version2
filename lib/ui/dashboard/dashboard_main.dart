import 'package:flutter/material.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/functions.dart';
import 'package:geo_monitor/ui/dashboard/dashboard_tablet_portrait.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../library/data/user.dart';
import 'dashboard_desktop.dart';
import 'dashboard_mobile.dart';
import 'dashboard_tablet.dart';
import 'dashboard_tablet_landscape.dart';


class DashboardMain extends StatefulWidget {

  const DashboardMain({Key? key, }) : super(key: key);
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
    return user == null? const SizedBox() : ScreenTypeLayout(
      mobile: const DashboardPortrait(
      ),
      tablet: OrientationLayoutBuilder(
        portrait: (context) {
          return DashboardTabletPortrait(user: user!,);
        },
        landscape: (context){
          return DashboardTabletLandscape(user: user!,);
        },
      ),
    );
  }
}
