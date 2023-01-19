import 'package:animations/animations.dart';
import 'package:badges/badges.dart';
import 'package:flutter/material.dart';

import '../../api/data_api.dart';
import '../../api/sharedprefs.dart';
import '../../data/project.dart';
import '../../functions.dart';
import '../../hive_util.dart';

class ProjectChooser extends StatefulWidget {
  const ProjectChooser({Key? key, required this.onSelected, required this.onClose}) : super(key: key);
  final Function(Project) onSelected;
  final Function onClose;

  @override
  State<ProjectChooser> createState() => ProjectChooserState();
}

class ProjectChooserState extends State<ProjectChooser>
    with SingleTickerProviderStateMixin {
  List<Project> projects = <Project>[];
  bool loading = false;
  late AnimationController _animationController;
  @override
  void initState() {
    _animationController = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 1500),
        reverseDuration: const Duration(milliseconds: 1500),
        vsync: this);
    super.initState();
    _getData();
  }
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _getData() async {
    setState(() {
      loading = true;
    });

    projects = await hiveUtil.getOrganizationProjects();
    if (projects.isEmpty) {
      var user = await Prefs.getUser();
      projects = await DataAPI.getOrganizationProjects(user!.organizationId!);
    }
    projects.sort((a, b) => b.created!.compareTo(a.created!));

    setState(() {
      loading = false;
    });
    _animationController.forward();
  }

  final txtController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                backgroundColor: Colors.pink,
              ),
            ),
          )
        : Stack(
            children: [
              SizedBox(
                height: 360,
                width: 260,
                child: Card(
                  elevation: 4,
                  color: Theme.of(context).primaryColorDark,
                  shape: getRoundedBorder(radius: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 8,
                        ),
                        Row(mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Projects',
                              style: myTextStyleMedium(context),
                            ),
                            const SizedBox(width: 60,),
                            IconButton(onPressed: ((){
                              widget.onClose();
                            }), icon: const Icon(Icons.close, size: 20.0,)),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (BuildContext context, Widget? child) {
                              return FadeScaleTransition(
                                animation: _animationController,
                                child: child,
                              );
                            },
                            child: Badge(
                              badgeContent: Text('${projects.length}',
                                style: myTextStyleSmall(context),),
                              position: BadgePosition.topEnd(top: -12, end: 10),
                              badgeColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.all(8.0),
                              child: ListView.builder(
                                  itemCount: projects.length,
                                  itemBuilder: (_, index) {
                                    var project = projects.elementAt(index);
                                    return GestureDetector(
                                      onTap: () {
                                        widget.onSelected(project);
                                      },
                                      child: Card(
                                        shape: getRoundedBorder(radius: 8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                height: 4,
                                                width: 4,
                                                color: Theme.of(context).primaryColor,
                                              ),
                                              const SizedBox(
                                                width: 12,
                                              ),
                                              Text(
                                                project.name!,
                                                style: myTextStyleSmall(context),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          );
  }
}
