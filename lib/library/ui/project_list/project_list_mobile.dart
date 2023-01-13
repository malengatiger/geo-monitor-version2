import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:geo_monitor/library/ui/maps/project_polygon_map_mobile.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:page_transition/page_transition.dart';
import '../../api/data_api.dart';
import '../../api/sharedprefs.dart';
import '../../bloc/fcm_bloc.dart';
import '../../bloc/organization_bloc.dart';
import '../../bloc/project_bloc.dart';
import '../../bloc/user_bloc.dart';
import '../../data/user.dart';
import '../../functions.dart';
import '../../hive_util.dart';
import '../../snack.dart';
import '../../data/user.dart' as mon;
import '../../data/project.dart';
import '../maps/org_map_mobile.dart';
import '../maps/project_map_mobile.dart';
import '../media/list/project_media_list_mobile.dart';
import '../project_edit/project_edit_main.dart';
import '../project_edit/project_edit_mobile.dart';
import '../project_location/project_location_main.dart';
import '../project_monitor/project_monitor_mobile.dart';

class ProjectListMobile extends StatefulWidget {
  final mon.User user;

  const ProjectListMobile(this.user, {super.key});

  @override
  ProjectListMobileState createState() => ProjectListMobileState();
}

class ProjectListMobileState extends State<ProjectListMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  var projects = <Project>[];
  mon.User? user;
  bool isBusy = false;
  bool isProjectsByLocation = false;
  var userTypeLabel = 'Unknown User Type';

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    user = widget.user;
    if (user == null) {
      _getUser();
    } else {
      _setUserType();
    }
    _listen();
    refreshProjects(false);
  }

  void _listen() {
    fcmBloc.projectStream.listen((Project project) {
      if (mounted) {
        AppSnackbar.showSnackbar(
            scaffoldKey: _key,
            message: 'Project added: ${project.name}',
            textColor: Colors.white,
            backgroundColor: Theme.of(context).primaryColor);
      }
    });
  }

  void _getUser() async {
    setState(() {
      isBusy = true;
    });
    user = await Prefs.getUser();
    _setUserType();
    setState(() {
      isBusy = false;
    });
  }

  void _setUserType() {
    setState(() {
      switch (user!.userType) {
        case FIELD_MONITOR:
          userTypeLabel = 'Field Monitor';
          break;
        case ORG_ADMINISTRATOR:
          userTypeLabel = 'Team Administrator';
          break;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future refreshProjects(bool forceRefresh) async {
    if (isBusy) return;
    pp('$mm ........... refresh projects');
    if (mounted) {
      setState(() {
        isBusy = true;
      });
    }
    try {
      if (isProjectsByLocation) {
        pp('$mm  🥏 🥏 🥏 getProjectsWithinRadius: $sliderValue km  🥏');
        projects = await projectBloc.getProjectsWithinRadius(
            radiusInKM: sliderValue, checkUserOrg: true);
      } else {
        projects = await organizationBloc.getProjects(
            organizationId: user!.organizationId!, forceRefresh: forceRefresh);
      }
      projects.sort((a, b) => a.name!.compareTo(b.name!));
    } catch (e) {
      pp(e);
      AppSnackbar.showErrorSnackbar(
          scaffoldKey: _key, message: 'Data refresh failed: $e');
    }
    if (mounted) {
      setState(() {
        isBusy = false;
      });
    }
  }

  bool openProjectActions = false;
  void _navigateToDetail(Project? p) {
    if (user!.userType == FIELD_MONITOR) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1500),
              child: ProjectEditMobile(p)));
    }
    if (user!.userType! == ORG_ADMINISTRATOR) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1500),
              child: ProjectEditMain(p)));
    }
  }

  void _navigateToProjectLocation(Project p) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(milliseconds: 1500),
            child: ProjectLocationMain(p)));
  }

  void _navigateToMonitorStart(Project p) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(milliseconds: 1500),
            child: ProjectMonitorMobile(project: p)));
  }

  void _navigateToProjectMedia(Project p) {
    if (user!.userType == UserType.fieldMonitor) {}
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(milliseconds: 1500),
            child: ProjectMediaListMobile(project: p)));
  }

  Future<void> _navigateToOrgMap() async {
    pp('_navigateToOrgMap: ');

    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.leftToRightWithFade,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1000),
              child: const OrganizationMapMobile()));
    }
  }

  void _navigateToProjectMap(Project p) async {
    pp('.................. _navigateToProjectMap: ');
    var pos = await hiveUtil.getProjectPositions(p.projectId!);
    if (pos.isEmpty) {
      pos = await DataAPI.getProjectPositions(p.projectId!);
    }
    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1000),
              child: ProjectMapMobile(
                project: p,
                projectPositions: pos,
              )));
    }
  }

  void _navigateToProjectPolygonMap(Project p) async {
    pp('.................. _navigateToProjectPolygonMap: ');

    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1000),
              child: ProjectPolygonMapMobile(
                project: p,
              )));
    }
  }

  List<FocusedMenuItem> getPopUpMenuItems(Project p) {
    List<FocusedMenuItem> menuItems = [];
    menuItems.add(
      FocusedMenuItem(
          title: Text(
            'Project Map',
            style: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.bodyMedium,
                fontWeight: FontWeight.normal,
                color: Colors.black),
          ),
          trailingIcon: Icon(
            Icons.map,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToProjectMap(p);
          }),
    );
    menuItems.add(
      FocusedMenuItem(
          title: Text(
            'Project Areas',
            style: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.bodyMedium,
                fontWeight: FontWeight.normal,
                color: Colors.black),
          ),
          trailingIcon: Icon(
            Icons.map,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToProjectPolygonMap(p);
          }),
    );

    menuItems.add(
      FocusedMenuItem(
          title: Text('Photos & Videos',
              style: GoogleFonts.lato(
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                  fontWeight: FontWeight.normal,
                  color: Colors.black)),
          trailingIcon: Icon(
            Icons.camera,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            pp('...... going to ProjectMedia ...');
            _navigateToProjectMedia(p);
          }),
    );
    menuItems.add(
      FocusedMenuItem(
          title: Text('Start Monitoring',
              style: GoogleFonts.lato(
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                  fontWeight: FontWeight.normal,
                  color: Colors.black)),
          trailingIcon: Icon(
            Icons.lock_clock,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToMonitorStart(p);
          }),
    );
    if (user!.userType == ORG_ADMINISTRATOR) {
      menuItems.add(FocusedMenuItem(
          title: Text('Add Project Location',
              style: GoogleFonts.lato(
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                  fontWeight: FontWeight.normal,
                  color: Colors.black)),
          trailingIcon: Icon(
            Icons.location_pin,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToProjectLocation(p);
          }));
      menuItems.add(FocusedMenuItem(
          title: Text('Edit Project',
              style: GoogleFonts.lato(
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                  fontWeight: FontWeight.normal,
                  color: Colors.black)),
          trailingIcon: Icon(
            Icons.create,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToDetail(p);
          }));
    }

    return menuItems;
  }

  final _key = GlobalKey<ScaffoldState>();
  List<IconButton> _getActions() {
    List<IconButton> list = [];
    list.add(IconButton(
      icon: Icon(
        Icons.refresh_rounded,
        size: 20,
        color: Theme.of(context).primaryColor,
      ),
      onPressed: () {
        refreshProjects(true);
      },
    ));
    list.add(IconButton(
      icon: isProjectsByLocation
          ? Icon(
              Icons.list,
              size: 24,
              color: Theme.of(context).primaryColor,
            )
          : Icon(
              Icons.location_pin,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
      onPressed: () {
        isProjectsByLocation = !isProjectsByLocation;
        refreshProjects(true);
      },
    ));
    if (projects.isNotEmpty) {
      list.add(
        IconButton(
          icon: Icon(
            Icons.map, size: 20,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToOrgMap();
          },
        ),
      );
    }
    if (user!.userType == ORG_ADMINISTRATOR) {
      list.add(
        IconButton(
          icon: Icon(
            Icons.add,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToDetail(null);
          },
        ),
      );
      // list.add(
      //   IconButton(
      //     icon: Icon(
      //       Icons.location_pin,
      //       size: 20,
      //     ),
      //     onPressed: () {
      //       _navigateToDetail(null);
      //     },
      //   ),
      // );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<Project>>(
          stream: organizationBloc.projectStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              projects = snapshot.data!;
            }
            return Scaffold(
                key: _key,
                appBar: AppBar(
                  title: Text('Projects',
                      style: GoogleFonts.lato(
                          textStyle: Theme.of(context).textTheme.bodyMedium,
                          fontWeight: FontWeight.normal)),
                  actions: _getActions(),
                  bottom: PreferredSize(
                    preferredSize:
                        Size.fromHeight(isProjectsByLocation ? 160 : 60),
                    child: Column(
                      children: [
                        Text(
                            user == null
                                ? 'Unknown User'
                                : user!.organizationName!,
                            style: GoogleFonts.lato(
                                textStyle:
                                    Theme.of(context).textTheme.bodyLarge,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(
                          height: 8,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            isProjectsByLocation
                                ? Row(
                                    children: [
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: Colors.pink[700],
                                          inactiveTrackColor: Colors.pink[100],
                                          trackShape:
                                              const RoundedRectSliderTrackShape(),
                                          trackHeight: 4.0,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                  enabledThumbRadius: 12.0),
                                          thumbColor: Colors.pinkAccent,
                                          overlayColor:
                                              Colors.pink.withAlpha(32),
                                          overlayShape:
                                              const RoundSliderOverlayShape(
                                                  overlayRadius: 28.0),
                                          tickMarkShape:
                                              const RoundSliderTickMarkShape(),
                                          activeTickMarkColor: Colors.pink[700],
                                          inactiveTickMarkColor:
                                              Colors.pink[100],
                                          valueIndicatorShape:
                                              const PaddleSliderValueIndicatorShape(),
                                          valueIndicatorColor:
                                              Colors.pinkAccent,
                                          valueIndicatorTextStyle:
                                              const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        child: Slider(
                                          value: sliderValue,
                                          min: 10,
                                          max: 50,
                                          divisions: 5,
                                          label: '$sliderValue',
                                          onChanged: _onSliderChanged,
                                        ),
                                      ),
                                      // SizedBox(
                                      //   width: 8,
                                      // ),
                                      Text(
                                        '$sliderValue',
                                        style: Styles.whiteBoldSmall,
                                      )
                                    ],
                                  )
                                : Container(),
                            const SizedBox(
                              width: 24,
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                // backgroundColor: Colors.brown[100],
                body: isBusy
                    ? Center(
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 100,
                            ),
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                backgroundColor: Colors.pink,
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            Text(isProjectsByLocation
                                ? 'Finding Projects within $sliderValue KM'
                                : 'Finding Organization Projects ...', style: myTextStyleMedium(context),),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: projects.isEmpty
                            ? Center(
                                child: Text('Projects Not Found',
                                    style: GoogleFonts.lato(
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                        fontWeight: FontWeight.w900)),
                              )
                            : Stack(
                                children: [
                                  Badge(
                                    position:
                                        BadgePosition.topEnd(top: -8, end: -2),
                                    badgeContent: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text(
                                        '${projects.length}',
                                        style: myNumberStyleSmall(context)
                                      ),
                                    ),
                                    badgeColor: Theme.of(context).primaryColor,
                                    elevation: 8,
                                    child: ListView.builder(
                                      itemCount: projects.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        var selectedProject =
                                            projects.elementAt(index);

                                        return FocusedMenuHolder(
                                          menuOffset: 20,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          menuItems: getPopUpMenuItems(
                                              selectedProject),
                                          animateMenuItems: true,
                                          openWithTap: true,
                                          onPressed: () {
                                            pp('.... 💛️ 💛️ 💛️ not sure what I pressed ...');
                                          },
                                          child: Card(
                                            elevation: 4,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        16.0)),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(12.0),
                                              child: Column(
                                                children: [
                                                  const SizedBox(
                                                    height: 12,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Opacity(
                                                        opacity: 0.5,
                                                        child: Icon(
                                                          Icons.water_damage,
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 8,
                                                      ),
                                                      Flexible(
                                                        child: Text(selectedProject.name!,
                                                            style: GoogleFonts.lato(
                                                                textStyle: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodySmall,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                      )
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 12,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              )));
          }),
    );
  }

  double sliderValue = 10.0;
  void _onSliderChanged(double value) {
    pp('ProjectListMobile  🥏 🥏 🥏 🥏 🥏 _onSliderChanged: $value');
    setState(() {
      sliderValue = value;
    });

    refreshProjects(true);
  }
}
