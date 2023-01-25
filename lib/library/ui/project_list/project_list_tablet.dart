import 'package:flutter/material.dart';

import '../../data/user.dart' as mon;
class ProjectListTablet extends StatefulWidget {
  final mon.User user;

  const ProjectListTablet(this.user, {super.key});

  @override
  ProjectListTabletState createState() => ProjectListTabletState();
}

class ProjectListTabletState extends State<ProjectListTablet>
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
