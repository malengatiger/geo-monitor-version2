import 'package:flutter/material.dart';

import 'package:responsive_builder/responsive_builder.dart';

import '../../bloc/project_bloc.dart';
import '../../bloc/user_bloc.dart';
import '../../data/project.dart';
import 'project_location_desktop.dart';
import 'project_location_mobile.dart';
import 'project_location_tablet.dart';

class ProjectLocationMain extends StatefulWidget {
  final Project project;
  const ProjectLocationMain(this.project, {super.key});

  @override
  ProjectLocationMainState createState() => ProjectLocationMainState();
}

class ProjectLocationMainState extends State<ProjectLocationMain> {
  @override
  void initState() {
    super.initState();
    // _getProjectLocations();
  }

  var isBusy = false;

  void _getProjectLocations() async {
    setState(() {
      isBusy = true;
    });
    await projectBloc.getProjectPositions(
        projectId: widget.project.projectId!, forceRefresh: true);
    setState(() {
      isBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isBusy
        ? SafeArea(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Loading Project positions ...'),
              ),
              backgroundColor: Colors.brown[100],
              body: const Center(
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 8,
                    backgroundColor: Colors.black,
                  ),
                ),
              ),
            ),
          )
        : ScreenTypeLayout(
            mobile: ProjectLocationMobile(widget.project),
            tablet: ProjectLocationTablet(widget.project),
            desktop: ProjectLocationDesktop(widget.project),
          );
  }
}
