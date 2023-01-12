import 'package:flutter/material.dart';
import '../../data/project.dart';
class ProjectLocationDesktop extends StatefulWidget {
  final Project project;

  const ProjectLocationDesktop(this.project, {super.key});

  @override
  ProjectLocationDesktopState createState() => ProjectLocationDesktopState();
}

class ProjectLocationDesktopState extends State<ProjectLocationDesktop>
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
