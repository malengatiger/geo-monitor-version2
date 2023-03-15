import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';

import '../../../l10n/translation_handler.dart';
import '../../data/project.dart';
import '../../data/user.dart';
import '../../functions.dart';

class ProjectListCard extends StatefulWidget {
  const ProjectListCard(
      {Key? key,
      required this.projects,
      required this.width,
      required this.navigateToDetail,
      required this.navigateToProjectLocation,
      required this.navigateToProjectMedia,
      required this.navigateToProjectMap,
      required this.navigateToProjectPolygonMap,
      required this.navigateToProjectDashboard,
      required this.user,
      required this.horizontalPadding, required this.navigateToProjectDirections})
      : super(key: key);

  final List<Project> projects;
  final User user;
  final double width;
  final double horizontalPadding;

  final Function(Project) navigateToDetail;
  final Function(Project) navigateToProjectLocation;
  final Function(Project) navigateToProjectMedia;
  final Function(Project) navigateToProjectMap;
  final Function(Project) navigateToProjectPolygonMap;
  final Function(Project) navigateToProjectDashboard;
  final Function(Project) navigateToProjectDirections;

  @override
  State<ProjectListCard> createState() => _ProjectListCardState();
}

class _ProjectListCardState extends State<ProjectListCard> {

  String? projectDashboard, directionsToProject, photosVideosAudioClips,
      projectDetails, editProject, projectLocationsMap,
      media, addLocation, addProjectAreas, addProjectLocationHere;
  @override
  void initState() {
    super.initState();
    _setText();
  }
  void _setText() async {
    var sett = await prefsOGx.getSettings();
    if (sett != null) {
      projectDashboard = await mTx.tx('projectDashboard', sett.locale!);
      addProjectAreas = await mTx.tx('addProjectAreas', sett.locale!);
      directionsToProject = await mTx.tx('directionsToProject', sett.locale!);
      addProjectLocationHere = await mTx.tx('addProjectLocationHere', sett.locale!);
      projectDetails = await mTx.tx('projectDetails', sett.locale!);
      editProject = await mTx.tx('editProject', sett.locale!);
      projectLocationsMap = await mTx.tx('projectLocationsMap', sett.locale!);
      photosVideosAudioClips = await mTx.tx('photosVideosAudioClips', sett.locale!);
      setState(() {

      });
    }
  }
  @override
  Widget build(BuildContext context) {
    List<FocusedMenuItem> getPopUpMenuItems(Project project) {
      List<FocusedMenuItem> menuItems = [];
      menuItems.add(
        FocusedMenuItem(
            // backgroundColor: Theme.of(context).primaryColor,
            title: Text(projectDashboard == null?'Project Dashboard':projectDashboard!,
                style: myTextStyleSmallBlack(context)),
            trailingIcon: Icon(
              Icons.dashboard,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              widget.navigateToProjectDashboard(project);
            }),
      );
      menuItems.add(
        FocusedMenuItem(
            // backgroundColor: Theme.of(context).primaryColor,
            title: Text(directionsToProject == null?
              'Project Directions': directionsToProject!,
              style: myTextStyleSmallBlack(context),
            ),
            trailingIcon: Icon(
              Icons.directions,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              widget.navigateToProjectDirections(project);
            }),
      );
      menuItems.add(
        FocusedMenuItem(
            // backgroundColor: Theme.of(context).primaryColor,
            title: Text(projectLocationsMap == null?
              'Project Locations Map': projectLocationsMap!,
              style: myTextStyleSmallBlack(context),
            ),
            trailingIcon: Icon(
              Icons.map,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              widget.navigateToProjectMap(project);
            }),
      );

      menuItems.add(
        FocusedMenuItem(
            // backgroundColor: Theme.of(context).primaryColor,
            title: Text(photosVideosAudioClips == null?
                'Photos & Video & Audio': photosVideosAudioClips!,
                style: myTextStyleSmallBlack(context)),
            trailingIcon: Icon(
              Icons.camera,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              pp('...... going to ProjectMedia ...');
              widget.navigateToProjectMedia(project);
            }),
      );

      if (widget.user.userType == UserType.orgAdministrator ||
          widget.user.userType == UserType.orgExecutive) {
        menuItems.add(FocusedMenuItem(
            // backgroundColor: Theme.of(context).primaryColor,
            title: Text(addProjectLocationHere == null?
                'Add Project Location Here': addProjectLocationHere!,
                style: myTextStyleSmallBlack(context)),
            trailingIcon: Icon(
              Icons.location_pin,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              widget.navigateToProjectLocation(project);
            }));
        menuItems.add(
          FocusedMenuItem(
              // backgroundColor: Theme.of(context).primaryColor,
              title: Text(addProjectAreas == null?
                'Create Project Areas': addProjectAreas!,
                style: myTextStyleSmallBlack(context),
              ),
              trailingIcon: Icon(
                Icons.map,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                widget.navigateToProjectPolygonMap(project);
              }),
        );
        menuItems.add(FocusedMenuItem(
            // backgroundColor: Theme.of(context).primaryColor,
            title: Text(editProject == null?
                'Edit Project': editProject!,
                style: myTextStyleSmallBlack(context)),
            trailingIcon: Icon(
              Icons.create,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              widget.navigateToDetail(project);
            }));
      }

      return menuItems;
    }

    return SizedBox(
      width: widget.width,
      child: ListView.builder(
        itemCount: widget.projects.length,
        itemBuilder: (BuildContext context, int index) {
          var mProject = widget.projects.elementAt(index);

          return FocusedMenuHolder(
            menuOffset: 20,
            duration: const Duration(milliseconds: 300),
            menuItems: getPopUpMenuItems(mProject),
            animateMenuItems: true,
            openWithTap: true,
            onPressed: () {
              pp('💛️💛️💛️ not sure what I pressed ...');
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 8,
                      ),
                      Row(
                        children: [
                          Opacity(
                            opacity: 0.9,
                            child: Icon(
                              Icons.water_damage,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Flexible(
                            child: Text(mProject.name!,
                                style: myTextStyleMedium(context)),
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
