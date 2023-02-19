import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';

import '../../data/project.dart';
import '../../data/user.dart';
import '../../functions.dart';

class ProjectListCard extends StatelessWidget {
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
      required this.horizontalPadding})
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

  @override
  Widget build(BuildContext context) {
    List<FocusedMenuItem> getPopUpMenuItems(Project project) {
      List<FocusedMenuItem> menuItems = [];
      menuItems.add(
        FocusedMenuItem(
            // backgroundColor: Theme.of(context).primaryColor,
            title: Text('Project Dashboard',
                style: myTextStyleSmallBlack(context)),
            trailingIcon: Icon(
              Icons.dashboard,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              navigateToProjectDashboard(project);
            }),
      );
      menuItems.add(
        FocusedMenuItem(
            // backgroundColor: Theme.of(context).primaryColor,
            title: Text(
              'Project Directions',
              style: myTextStyleSmallBlack(context),
            ),
            trailingIcon: Icon(
              Icons.directions,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              //startDirections(project);
            }),
      );
      menuItems.add(
        FocusedMenuItem(
            // backgroundColor: Theme.of(context).primaryColor,
            title: Text(
              'Project Locations Map',
              style: myTextStyleSmallBlack(context),
            ),
            trailingIcon: Icon(
              Icons.map,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              navigateToProjectMap(project);
            }),
      );

      menuItems.add(
        FocusedMenuItem(
            // backgroundColor: Theme.of(context).primaryColor,
            title: Text('Photos & Video & Audio',
                style: myTextStyleSmallBlack(context)),
            trailingIcon: Icon(
              Icons.camera,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              pp('...... going to ProjectMedia ...');
              navigateToProjectMedia(project);
            }),
      );
      menuItems.add(
        FocusedMenuItem(
            // backgroundColor: Theme.of(context).primaryColor,
            title: Text('Create Audio', style: myTextStyleSmallBlack(context)),
            trailingIcon: Icon(
              Icons.mic,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              pp('...... going to ProjectAudio ...');
              navigateToProjectMedia(project);
            }),
      );

      if (user.userType == UserType.orgAdministrator ||
          user.userType == UserType.orgExecutive) {
        menuItems.add(FocusedMenuItem(
            // backgroundColor: Theme.of(context).primaryColor,
            title: Text('Add Project Location',
                style: myTextStyleSmallBlack(context)),
            trailingIcon: Icon(
              Icons.location_pin,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              navigateToProjectLocation(project);
            }));
        menuItems.add(
          FocusedMenuItem(
              // backgroundColor: Theme.of(context).primaryColor,
              title: Text(
                'Create Project Areas',
                style: myTextStyleSmallBlack(context),
              ),
              trailingIcon: Icon(
                Icons.map,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                navigateToProjectPolygonMap(project);
              }),
        );
        menuItems.add(FocusedMenuItem(
            // backgroundColor: Theme.of(context).primaryColor,
            title: Text('Edit Project', style: myTextStyleSmallBlack(context)),
            trailingIcon: Icon(
              Icons.create,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              navigateToDetail(project);
            }));
      }

      return menuItems;
    }

    return SizedBox(
      width: width,
      child: ListView.builder(
        itemCount: projects.length,
        itemBuilder: (BuildContext context, int index) {
          var mProject = projects.elementAt(index);

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
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
