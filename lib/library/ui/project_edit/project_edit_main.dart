import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../../data/project.dart';
import 'project_edit_desktop.dart';
import 'project_edit_mobile.dart';
import 'project_edit_tablet.dart';

class ProjectEditMain extends StatelessWidget {
  final Project? project;

  const ProjectEditMain(this.project, {super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: ProjectEditMobile(project),
      tablet: ProjectEditTablet(project),
      desktop: ProjectEditDesktop(project),
    );
  }
}
