import 'package:flutter/material.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/functions.dart';
import 'package:page_transition/page_transition.dart';
import 'package:uuid/uuid.dart';

import '../../bloc/admin_bloc.dart';
import '../../bloc/organization_bloc.dart';
import '../../data/project.dart';
import '../../data/user.dart';
import '../project_location/project_location_main.dart';

class ProjectEditCard extends StatefulWidget {
  const ProjectEditCard({Key? key, required this.project, this.width}) : super(key: key);

  final Project? project;
  final double? width;

  @override
  ProjectEditCardState createState() => ProjectEditCardState();
}

class ProjectEditCardState extends State<ProjectEditCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _formKey = GlobalKey<FormState>();
  var nameController = TextEditingController();
  var descController = TextEditingController();
  var maxController = TextEditingController();
  bool busy = false;
  User? admin;


  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getUser();
  }
  void _getUser() async {
    admin = await prefsOGx.getUser();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        busy = true;
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
          busy = false;
        });
        organizationBloc.getOrganizationProjects(
            organizationId: mProject.organizationId!, forceRefresh: true);
        _navigateToProjectLocation(mProject);
      } catch (e) {
        setState(() {
          busy = false;
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


  @override
  Widget build(BuildContext context) {
    return SizedBox(width: widget.width ?? 600,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                children: [
                  const SizedBox(
                    height: 72,
                  ),
                  TextFormField(
                    controller: nameController,
                    keyboardType: TextInputType.text,
                    style: myTextStyleMedium(context),
                    decoration: InputDecoration(
                        icon: Icon(
                          Icons.event,
                          color: Theme.of(context).primaryColor,
                        ),
                        labelText: 'Project Name',
                        hintText: 'Enter Project Name'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter Project name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  TextFormField(
                    controller: descController,
                    keyboardType: TextInputType.multiline,
                    style: myTextStyleMedium(context),
                    minLines: 2, //Normal textInputField will be displayed
                    maxLines:
                    6, // when user presses enter it will adapt to it
                    decoration: InputDecoration(

                        icon: Icon(
                          Icons.info_outline,
                          color: Theme.of(context).primaryColor,
                        ),
                        labelText: 'Description',
                        hintText: 'Enter Description'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter Description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  TextFormField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        icon: Icon(
                          Icons.camera_enhance_outlined,
                          color: Theme.of(context).primaryColor,
                        ),
                        labelText: 'Max Monitor Distance in Metres',
                        hintText:
                        'Enter Maximum Monitor Distance in metres'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter Maximum Monitor Distance in Metres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 48,
                  ),
                  busy
                      ? const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 8,
                      backgroundColor: Colors.black,
                    ),
                  )
                      : Column(
                    children: [
                      widget.project == null
                          ? Container()
                          : SizedBox(
                        width: 220,
                        child: ElevatedButton(

                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              'Add Location',
                              style: Styles.whiteSmall,
                            ),
                          ),
                          onPressed: () {
                            // _navigateToProjectLocation(
                            //     widget.project!);
                          },
                        ),
                      ),
                      widget.project == null
                          ? Container(height: 64,)
                          : const SizedBox(
                        height: 64,
                      ),
                      SizedBox(
                        width: 220,
                        child: ElevatedButton(
                          onPressed: _submit,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              'Submit Project',
                              style: myTextStyleMedium(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


}
