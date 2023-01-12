import 'package:flutter/material.dart';

import 'package:responsive_builder/responsive_builder.dart';

import '../../data/user.dart' as mon;
import '../../functions.dart';
import 'project_list_desktop.dart';
import 'project_list_mobile.dart';
import 'project_list_tablet.dart';

class ProjectListMain extends StatefulWidget {
  final mon.User user;

  const ProjectListMain(this.user, {super.key});

  @override
  ProjectListMainState createState() => ProjectListMainState();
}

class ProjectListMainState extends State<ProjectListMain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  var isBusy = false;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    // _loadProjects();
  }

  // void _loadProjects() async {
  //   setState(() {
  //     isBusy = true;
  //   });
  //   await monitorBloc.getOrganizationProjects(
  //       organizationId: widget.user.organizationId);
  //
  //   setState(() {
  //     isBusy = false;
  //   });
  // }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isBusy
        ? SafeArea(
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  'Loading projects ...',
                  style: Styles.whiteSmall,
                ),
              ),
              backgroundColor: Colors.brown[100],
              body: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 8,
                  backgroundColor: Colors.black,
                ),
              ),
            ),
          )
        : ScreenTypeLayout(
            mobile: ProjectListMobile(widget.user),
            tablet: ProjectListTablet(widget.user),
            desktop: ProjectListDesktop(widget.user),
          );
  }
}
