import 'package:flutter/material.dart';
import 'package:geo_monitor/library/ui/project_list/project_list_tablet_portrait.dart';
import 'package:responsive_builder/responsive_builder.dart';

import 'project_list_mobile.dart';
import 'project_list_tablet_landscape.dart';

class ProjectListMain extends StatelessWidget {
  const ProjectListMain({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: const ProjectListMobile(
        instruction: stayOnList,
      ),
      tablet: OrientationLayoutBuilder(
        portrait: (context) {
          return const ProjectListTabletPortrait(instruction: stayOnList);
        },
        landscape: (context) {
          return const ProjectListTabletLandscape();
        },
      ),
    );
  }
}
