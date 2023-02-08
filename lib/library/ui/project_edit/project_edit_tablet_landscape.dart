import 'package:flutter/material.dart';
import 'package:geo_monitor/library/ui/project_edit/project_edit_card.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:page_transition/page_transition.dart';
import 'package:uuid/uuid.dart';
import '../../api/prefs_og.dart';
import '../../bloc/admin_bloc.dart';
import '../../bloc/organization_bloc.dart';
import '../../data/project.dart';
import '../../data/user.dart';
import '../../functions.dart';
import '../project_location/project_location_main.dart';
class ProjectEditTabletLandscape extends StatefulWidget {
  final Project? project;
  const ProjectEditTabletLandscape({this.project, super.key});

  @override
  ProjectEditTabletLandscapeState createState() => ProjectEditTabletLandscapeState();
}

class ProjectEditTabletLandscapeState extends State<ProjectEditTabletLandscape>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  var nameController = TextEditingController();
  var descController = TextEditingController();
  var maxController = TextEditingController(text: '50.0');
  var isBusy = false;

  User? admin;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _setup();
    _getUser();
  }

  void _getUser() async {
    admin = await prefsOGx.getUser();
    if (admin != null) {
      pp('🎽 🎽 🎽 We have an admin user? 🎽 🎽 🎽 ${admin!.toJson()}');
      setState(() {});
    }
  }

  void _setup() {
    if (widget.project != null) {
      nameController.text = widget.project!.name!;
      descController.text = widget.project!.description!;
      maxController.text = '${widget.project!.monitorMaxDistanceInMetres}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isBusy = true;
      });
      try {
        Project mProject;
        if (widget.project == null) {
          pp('😡 😡 😡 _submit new project ......... ${nameController.text}');
          var uuid = const Uuid();
          mProject = Project(
              name: nameController.text,
              description: descController.text,
              organizationId: admin!.organizationId!,
              organizationName: admin!.organizationName!,
              created: DateTime.now().toUtc().toIso8601String(),
              monitorMaxDistanceInMetres: double.parse(maxController.text),
              photos: [],
              videos: [],
              communities: [],
              monitorReports: [],
              nearestCities: [],
              projectPositions: [], ratings: [],
              projectId: uuid.v4());
          var m = await adminBloc.addProject(mProject);
          pp('🎽 🎽 🎽 _submit: new project added .........  ${m.toJson()}');
        } else {
          pp('😡 😡 😡 _submit existing project for update, soon! 🌸 ......... ');
          widget.project!.name = nameController.text;
          widget.project!.description = descController.text;
          mProject = widget.project!;
          var m = await adminBloc.updateProject(widget.project!);
          pp('🎽 🎽 🎽 _submit: new project updated .........  ${m.toJson()}');
        }
        setState(() {
          isBusy = false;
        });
        organizationBloc.getOrganizationProjects(
            organizationId: mProject.organizationId!, forceRefresh: true);
        _navigateToProjectLocation(mProject);
      } catch (e) {
        setState(() {
          isBusy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));

      }
    }
  }

  void _navigateToProjectLocation(Project mProject) async {

    pp(' 😡 _navigateToProjectLocation  😡 😡 😡 ${mProject.name}');
    await Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomRight,
            duration: const Duration(seconds: 1),
            child: ProjectLocationMain(mProject)));
    if (mounted) {
      Navigator.pop(context);
    }
  }

  final _key = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _key,
        appBar: AppBar(
          title: Text(
            'Project Editor',
            style: Styles.whiteSmall,
          ),
          actions: [
            widget.project == null
                ? Container()
                : IconButton(
                    icon: const Icon(Icons.location_on),
                    onPressed: () {
                      if (widget.project != null) {
                        _navigateToProjectLocation(widget.project!);
                      }
                    },
                  )
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                Text(
                  widget.project == null ? 'New Project' : 'Edit Project',
                  style: Styles.blackBoldMedium,
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  admin == null ? '' : admin!.organizationName!,
                  style: myTextStyleLarge(context),
                ),
                const SizedBox(
                  height: 20,
                )
              ],
            ),
          ),
        ),
        // backgroundColor: Colors.brown[100],
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ProjectEditCard(project: widget.project, width: 600,),
              Container(width: 400, color: Theme.of(context).primaryColor,)
            ],
          ),
        ),
      ),
    );
  }
}
