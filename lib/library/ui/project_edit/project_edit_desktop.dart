import 'package:flutter/material.dart';
import '../../data/project.dart';
class ProjectEditDesktop extends StatefulWidget {
  final Project? project;

  const ProjectEditDesktop(this.project, {super.key});

  @override
  ProjectEditDesktopState createState() => ProjectEditDesktopState();
}

class ProjectEditDesktopState extends State<ProjectEditDesktop>
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
