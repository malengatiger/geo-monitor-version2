import 'package:flutter/material.dart';


class DashboardDesktop extends StatefulWidget {
  const DashboardDesktop({Key? key, }) : super(key: key);
  @override
  DashboardDesktopState createState() => DashboardDesktopState();
}

class DashboardDesktopState extends State<DashboardDesktop>
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
    return Container();
  }
}
