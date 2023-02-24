import 'package:flutter/material.dart';
import 'package:geo_monitor/library/ui/maps/project_map_mobile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:uuid/uuid.dart';

import '../../api/prefs_og.dart';
import '../../bloc/admin_bloc.dart';
import '../../bloc/organization_bloc.dart';
import '../../data/project.dart';
import '../../data/user.dart';
import '../../functions.dart';

class ProjectEditMobile extends StatefulWidget {
  final Project? project;
  const ProjectEditMobile(this.project, {super.key});

  @override
  ProjectEditMobileState createState() => ProjectEditMobileState();
}

class ProjectEditMobileState extends State<ProjectEditMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  var nameController = TextEditingController();
  var descController = TextEditingController();
  var maxController = TextEditingController(text: '200');
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
              projectPositions: [],
              ratings: [],
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
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
            child: ProjectMapMobile(project: mProject)));
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
            style: myTextStyleLarge(context),
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
            preferredSize: const Size.fromHeight(120),
            child: Column(
              children: [
                Text(
                  widget.project == null ? 'New Project' : 'Edit Project',
                  style: myTextStyleMedium(context),
                ),
                const SizedBox(
                  height: 24,
                ),
                Text(
                  admin == null ? '' : admin!.organizationName!,
                  style: myTextStyleLargerPrimaryColor(context),
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
          child: SingleChildScrollView(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 24,
                      ),
                      TextFormField(
                        controller: nameController,
                        keyboardType: TextInputType.text,
                        style: GoogleFonts.lato(
                            textStyle: Theme.of(context).textTheme.bodyMedium,
                            fontWeight: FontWeight.normal),
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
                        height: 16,
                      ),
                      TextFormField(
                        controller: descController,
                        keyboardType: TextInputType.multiline,
                        style: GoogleFonts.lato(
                            textStyle: Theme.of(context).textTheme.bodySmall,
                            fontWeight: FontWeight.normal),
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
                        height: 16,
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
                        height: 60,
                      ),
                      isBusy
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
                                              'Add Project Location',
                                              style: Styles.whiteSmall,
                                            ),
                                          ),
                                          onPressed: () {
                                            _navigateToProjectLocation(
                                                widget.project!);
                                          },
                                        ),
                                      ),
                                widget.project == null
                                    ? Container()
                                    : const SizedBox(
                                        height: 20,
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
        ),
      ),
    );
  }
}
