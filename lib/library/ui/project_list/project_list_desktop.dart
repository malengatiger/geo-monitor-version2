import 'package:flutter/material.dart';
import '../../data/user.dart' as mon;
class ProjectListDesktop extends StatefulWidget {
  final mon.User user;

  const ProjectListDesktop(this.user, {super.key});

  @override
  ProjectListDesktopState createState() => ProjectListDesktopState();
}

class ProjectListDesktopState extends State<ProjectListDesktop>
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
