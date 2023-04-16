import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';

import '../library/api/prefs_og.dart';
import '../library/data/project.dart';
import '../library/functions.dart';
import '../library/generic_functions.dart';

class ProjectList extends StatefulWidget {
  const ProjectList({Key? key, required this.onProjectsAcquired, required this.onProjectTapped}) : super(key: key);
  final Function(int) onProjectsAcquired;
  final Function(Project) onProjectTapped;

  @override
  ProjectListState createState() => ProjectListState();
}

class ProjectListState extends State<ProjectList> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool busy = false;
  var projects = <Project>[];

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getData();
  }

  void _getData() async {
    setState(() {
      busy = true;
    });
    try {
      final user = await prefsOGx.getUser();
      final sett = await prefsOGx.getSettings();
      projects = await organizationBloc.getOrganizationProjects(
          organizationId: user!.organizationId!, forceRefresh: true);
      pp('projects found: ${projects.length}');
      widget.onProjectsAcquired(projects.length);
    } catch (e) {
      pp(e);
      if (mounted) {
        showToast(message: '$e', context: context);
      }
    }

    setState(() {
      busy = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 220,
      child: ListView.builder(
          itemCount: projects.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final project = projects.elementAt(index);
            return GestureDetector(
                onTap: (){
                  widget.onProjectTapped(project);
                },
                child: ProjectView(project: project, height: 212, width: 242));
          }),
    );
  }
}

class ProjectView extends StatelessWidget {
  const ProjectView(
      {Key? key,
      required this.project,
      required this.height,
      required this.width})
      : super(key: key);
  final Project project;
  final double height, width;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: Card(
        shape: getRoundedBorder(radius: 10),
        elevation: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 20,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Flexible(
                    child: Text(
                      '${project.name}',
                      overflow: TextOverflow.ellipsis,
                      style: myTextStyleSmallBlackBold(context),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Image.asset(
                'assets/xd1.jpg',
                fit: BoxFit.cover,
                height: height - 48,
              ),
            )
          ],
        ),
      ),
    );
  }
}
