import 'package:flutter/material.dart';
import 'package:geo_monitor/library/ui/project_edit/project_edit_tablet_landscape.dart';
import 'package:geo_monitor/library/ui/project_edit/project_edit_tablet_portrait.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../data/project.dart';
import 'project_edit_mobile.dart';

class ProjectEditMain extends StatelessWidget {
  final Project? project;

  const ProjectEditMain(this.project, {super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: ProjectEditMobile(project),
      tablet: OrientationLayoutBuilder(
        portrait: (context) {
          return ProjectEditTabletPortrait(project: project);
        },
        landscape: (context) {
          return ProjectEditTabletLandscape(project: project);
        },
      ),
    );
  }
}
