import 'package:flutter/material.dart';

import '../../library/data/user.dart';
// import 'package:monitorlibrary/data/user.dart';

class DashboardDesktop extends StatefulWidget {
  final User user;
  const DashboardDesktop({Key? key, required this.user}) : super(key: key);
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
