import 'package:flutter/material.dart';

import '../../data/project.dart';

class ProjectEditTablet extends StatefulWidget {
  final Project? project;

  ProjectEditTablet(this.project);

  @override
  ProjectEditTabletState createState() => ProjectEditTabletState();
}

class ProjectEditTabletState extends State<ProjectEditTablet>
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
