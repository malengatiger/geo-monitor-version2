import 'dart:async';

import 'package:animations/animations.dart';
import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';
import 'package:focused_menu/modals.dart';
import 'package:geo_monitor/library/cache_manager.dart';
import 'package:geo_monitor/library/ui/maps/project_map_mobile.dart';
import 'package:geo_monitor/library/ui/project_list/project_list_card.dart';
import 'package:geo_monitor/ui/audio/audio_handler.dart';
import 'package:geo_monitor/ui/dashboard/project_dashboard_mobile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:page_transition/page_transition.dart';

import '../../api/prefs_og.dart';
import '../../bloc/admin_bloc.dart';
import '../../bloc/fcm_bloc.dart';
import '../../bloc/organization_bloc.dart';
import '../../bloc/project_bloc.dart';
import '../../data/position.dart';
import '../../data/project.dart';
import '../../data/project_polygon.dart';
import '../../data/project_position.dart';
import '../../data/user.dart';
import '../../data/user.dart' as mon;
import '../../functions.dart';
import '../../snack.dart';
import '../maps/org_map_mobile.dart';
import '../maps/project_map_main.dart';
import '../maps/project_polygon_map_mobile.dart';
import '../media/list/project_media_main.dart';
import '../project_edit/project_edit_main.dart';
import '../project_monitor/project_monitor_main.dart';
import '../project_monitor/project_monitor_mobile.dart';
import '../schedule/project_schedules_mobile.dart';

const goToMedia = 1;
const goToMap = 2;
const stayOnList = 3;
const goToSchedule = 4;

class ProjectListMobile extends StatefulWidget {
  const ProjectListMobile({super.key, this.project, required this.instruction});
  final Project? project;
  final int instruction;
  @override
  ProjectListMobileState createState() => ProjectListMobileState();
}

class ProjectListMobileState extends State<ProjectListMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  var projects = <Project>[];
  mon.User? user;
  bool isBusy = false;
  bool isProjectsByLocation = false;
  var userTypeLabel = 'Unknown User Type';
  final mm = '🔵🔵🔵🔵 ProjectListMobile:  ';
  late StreamSubscription<String> killSubscription;
  int numberOfDays = 30;
  bool sortedByName = true;
  bool openProjectActions = false;

  @override
  void initState() {
    _animationController = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 3000),
        reverseDuration: const Duration(milliseconds: 2000),
        vsync: this);
    super.initState();

    _getUser();
    _listen();
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
    adminBloc.projectStream.listen((List<Project> list) {
      projects = list;
      projects.sort((a, b) => a.name!.compareTo(b.name!));

      if (mounted) {
        setState(() {});
      }
    });
  }

  void _sort() {
    if (sortedByName) {
      _sortByDate();
    } else {
      _sortByName();
    }
  }

  void _sortByName() {
    projects.sort((a, b) => a.name!.compareTo(b.name!));
    sortedByName = true;
    if (mounted) {
      setState(() {});
    }
  }

  void _sortByDate() {
    projects.sort((a, b) => b.created!.compareTo(a.created!));
    sortedByName = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _getUser() async {
    setState(() {
      isBusy = true;
    });
    user = await prefsOGx.getUser();
    var settings = await prefsOGx.getSettings();
    if (settings != null) {
      numberOfDays = settings.numberOfDays!;
    }
    if (user != null) {
      pp('$mm user found: ${user!.name!}');
      _setUserType();
      await refreshProjects(false);
    } else {
      pp('$mm user NOT found!!! 🥏 🥏 🥏');

      throw Exception('$mm Fucked! we are! user is null???');
    }
    setState(() {
      isBusy = false;
    });
    switch (widget.instruction) {
      case goToMedia:
        _navigateToProjectMedia(widget.project!);
        break;
      case goToMap:
        _navigateToProjectMap(widget.project!);
        break;
      case goToSchedule:
        _navigateToProjectSchedules(widget.project!);
        break;
    }
  }

  void _setUserType() {
    setState(() {
      switch (user!.userType) {
        case UserType.fieldMonitor:
          userTypeLabel = 'Field Monitor';
          break;
        case UserType.orgAdministrator:
          userTypeLabel = 'Administrator';
          break;
        case UserType.orgExecutive:
          userTypeLabel = 'Executive';
          break;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future refreshProjects(bool forceRefresh) async {
    pp('$mm 🥏 🥏 🥏 .................... refresh projects: forceRefresh: $forceRefresh');
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
        pp('$mm  🥏 🥏 🥏 getOrganizationProjects, orgId: ${user!.organizationId} k 🥏');
        projects = await organizationBloc.getOrganizationProjects(
            organizationId: user!.organizationId!, forceRefresh: forceRefresh);
      }
      projects.sort((a, b) => a.name!.compareTo(b.name!));
    } catch (e) {
      pp(e);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    if (mounted) {
      setState(() {
        isBusy = false;
      });
      _animationController.forward();
    }
  }

  void _navigateToDetail(Project? p) {
    if (user!.userType == UserType.fieldMonitor) {
      pp('$mm Field Monitors not allowed to edit or create a project');
    }
    if (user!.userType! == UserType.orgAdministrator ||
        user!.userType == UserType.orgExecutive) {
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
            child: ProjectMapMobile(project: p,)));
  }

  void _navigateToMonitorStart(Project p) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(milliseconds: 1500),
            child: ProjectMonitorMain(p)));
  }

  void _navigateToProjectMedia(Project p) {
    if (user!.userType == UserType.fieldMonitor) {}
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(milliseconds: 1500),
            child: ProjectMediaMain(project: p)));
  }

  void _navigateToProjectSchedules(Project p) {
    if (user!.userType == UserType.fieldMonitor) {}
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(milliseconds: 1500),
            child: ProjectSchedulesMobile(project: p)));
  }

  void _navigateToProjectAudio(Project p) {
    if (user!.userType == UserType.fieldMonitor) {}
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(milliseconds: 1500),
            child: AudioHandler(project: p, onClose: (){
              Navigator.of(context).pop();
            },)));
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
    // var positions = await projectBloc.getProjectPositions(
    //     projectId: p.projectId!, forceRefresh: false);
    // var polygons = await projectBloc.getProjectPolygons(
    //     projectId: p.projectId!, forceRefresh: false);
    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1000),
              child: ProjectMapMain(
                project: p,
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

  void _navigateToProjectDashboard(Project p) async {
    pp('.................. _navigateToProjectDashboard: ');

    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1000),
              child: ProjectDashboardMobile(
                project: p,
              )));
    }
  }

  bool _showPositionChooser = false;

  void _navigateToDirections(
      {required double latitude, required double longitude}) async {
    pp('$mm 🍎 🍎 🍎 start Google Maps Directions .....');

    final availableMaps = await MapLauncher.installedMaps;
    pp('$mm 🍎 🍎 🍎 availableMaps: $availableMaps'); // [AvailableMap { mapName: Google Maps, mapType: google }, ...]

    var coordinates = Coords(latitude, longitude);
    await availableMaps.first.showDirections(destination: coordinates);
  }

  _onPositionSelected(Position p1) {
    setState(() {
      _showPositionChooser = false;
    });
    _navigateToDirections(
        latitude: p1.coordinates[1], longitude: p1.coordinates[0]);
  }

  _onClose() {
    setState(() {
      _showPositionChooser = false;
    });
  }

  var positions = <ProjectPosition>[];
  var polygons = <ProjectPolygon>[];

  void _startDirections(Project project) async {
    setState(() {
      isBusy = true;
    });
    try {
      var map = await getStartEndDates();
      final startDate = map['startDate'];
      final endDate = map['endDate'];
      positions = await projectBloc.getProjectPositions(
          projectId: project.projectId!, forceRefresh: false, startDate: startDate!, endDate: endDate!);
      polygons = await projectBloc.getProjectPolygons(
          projectId: project.projectId!, forceRefresh: false);
      if (positions.length == 1 && polygons.isEmpty) {
        _onPositionSelected(positions.first.position!);
        setState(() {
          isBusy = false;
          _showPositionChooser = false;
        });
        return;
      }
    } catch (e) {
      pp(e);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: const Duration(seconds: 10), content: Text('$e')));
    }
    setState(() {
      isBusy = false;
      _showPositionChooser = true;
    });
    _animationController.forward();
  }

  List<FocusedMenuItem> getPopUpMenuItems(Project project) {
    List<FocusedMenuItem> menuItems = [];
    menuItems.add(
      FocusedMenuItem(
          backgroundColor: Theme.of(context).primaryColor,
          title:
              Text('Project Dashboard', style: myTextStyleSmallBlack(context)),
          trailingIcon: Icon(
            Icons.dashboard,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToProjectDashboard(project);
          }),
    );
    menuItems.add(
      FocusedMenuItem(
          backgroundColor: Theme.of(context).primaryColor,
          title: Text(
            'Project Directions',
            style: myTextStyleSmallBlack(context),
          ),
          trailingIcon: Icon(
            Icons.directions,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _startDirections(project);
          }),
    );
    menuItems.add(
      FocusedMenuItem(
          backgroundColor: Theme.of(context).primaryColor,
          title: Text(
            'Project Locations Map',
            style: myTextStyleSmallBlack(context),
          ),
          trailingIcon: Icon(
            Icons.map,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToProjectMap(project);
          }),
    );

    menuItems.add(
      FocusedMenuItem(
          backgroundColor: Theme.of(context).primaryColor,
          title: Text('Photos & Video & Audio',
              style: myTextStyleSmallBlack(context)),
          trailingIcon: Icon(
            Icons.camera,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            pp('...... going to ProjectMedia ...');
            _navigateToProjectMedia(project);
          }),
    );
    menuItems.add(
      FocusedMenuItem(
          backgroundColor: Theme.of(context).primaryColor,
          title: Text('Create Audio', style: myTextStyleSmallBlack(context)),
          trailingIcon: Icon(
            Icons.camera,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            pp('...... going to ProjectAudio ...');
            _navigateToProjectAudio(project);
          }),
    );
    // menuItems.add(
    //   FocusedMenuItem(
    //       backgroundColor: Theme.of(context).primaryColor,
    //
    //       title: Text('Start Monitoring',
    //           style: myTextStyleSmallBlack(context)),
    //       trailingIcon: Icon(
    //         Icons.lock_clock,
    //         color: Theme.of(context).primaryColor,
    //       ),
    //       onPressed: () {
    //         _navigateToMonitorStart(project);
    //       }),
    // );
    if (user!.userType == UserType.orgAdministrator) {
      menuItems.add(FocusedMenuItem(
          backgroundColor: Theme.of(context).primaryColor,
          title: Text('Add Project Location',
              style: myTextStyleSmallBlack(context)),
          trailingIcon: Icon(
            Icons.location_pin,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToProjectLocation(project);
          }));
      menuItems.add(
        FocusedMenuItem(
            backgroundColor: Theme.of(context).primaryColor,
            title: Text(
              'Create Project Areas',
              style: myTextStyleSmallBlack(context),
            ),
            trailingIcon: Icon(
              Icons.map,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              _navigateToProjectPolygonMap(project);
            }),
      );
      menuItems.add(FocusedMenuItem(
          backgroundColor: Theme.of(context).primaryColor,
          title: Text('Edit Project', style: myTextStyleSmallBlack(context)),
          trailingIcon: Icon(
            Icons.create,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToDetail(project);
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
            Icons.map,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            _navigateToOrgMap();
          },
        ),
      );
    }
    if (user != null) {
      if (user!.userType == UserType.orgAdministrator) {
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
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SafeArea(
        child: Scaffold(
            key: _key,
            appBar: AppBar(
              actions: _getActions(),
              bottom: PreferredSize(
                preferredSize:
                    Size.fromHeight(isProjectsByLocation ? 200 : 160),
                child: Column(
                  children: [
                    Text(
                        user == null ? 'Unknown User' : user!.organizationName!,
                        style: myTextStyleLargerPrimaryColor(context)),
                    const SizedBox(
                      height: 16,
                    ),
                    Text(
                      'Organization Projects',
                      style: myTextStyleMedium(context),
                    ),
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
                                      activeTrackColor:
                                          Theme.of(context).primaryColor,
                                      inactiveTrackColor: Colors.pink[100],
                                      trackShape:
                                          const RoundedRectSliderTrackShape(),
                                      trackHeight: 2.0,
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 12.0),
                                      thumbColor: Colors.pinkAccent,
                                      overlayColor: Colors.pink.withAlpha(32),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                              overlayRadius: 28.0),
                                      tickMarkShape:
                                          const RoundSliderTickMarkShape(),
                                      activeTickMarkColor: Colors.indigo[700],
                                      inactiveTickMarkColor: Colors.pink[100],
                                      valueIndicatorShape:
                                          const PaddleSliderValueIndicatorShape(),
                                      valueIndicatorColor: Colors.pinkAccent,
                                      valueIndicatorTextStyle:
                                          myTextStyleSmall(context),
                                    ),
                                    child: Slider(
                                      value: sliderValue,
                                      min: 3,
                                      max: 50,
                                      divisions: 5,
                                      label: '$sliderValue',
                                      onChanged: _onSliderChanged,
                                    ),
                                  ),
                                  Text(
                                    '$sliderValue',
                                    style: myNumberStyleMedium(context),
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
                      height: 32,
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
                        Text(
                          isProjectsByLocation
                              ? 'Finding Projects within $sliderValue KM'
                              : 'Finding Organization Projects ...',
                          style: myTextStyleMedium(context),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: projects.isEmpty
                        ? Center(
                            child: Text('Projects Not Found',
                                style: GoogleFonts.lato(
                                    textStyle:
                                        Theme.of(context).textTheme.bodyLarge,
                                    fontWeight: FontWeight.w900)),
                          )
                        : Stack(
                            children: [
                              GestureDetector(
                                  onTap: _sort,
                                  child: bd.Badge(
                                    badgeStyle: bd.BadgeStyle(
                                      badgeColor:
                                          Theme.of(context).primaryColor,
                                      elevation: 8,
                                      padding: const EdgeInsets.all(8),
                                    ),
                                    position: bd.BadgePosition.topEnd(
                                        top: -8, end: -2),
                                    badgeContent: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text('${projects.length}',
                                          style: myNumberStyleSmall(context)),
                                    ),
                                    child: ProjectListCard(
                                        projects: projects,
                                        width: width,
                                        horizontalPadding: 12,
                                        navigateToDetail: _navigateToDetail,
                                        navigateToProjectLocation:
                                            _navigateToProjectLocation,
                                        navigateToProjectMedia:
                                            _navigateToProjectMedia,
                                        navigateToProjectMap:
                                            _navigateToProjectMap,
                                        navigateToProjectPolygonMap:
                                            _navigateToProjectPolygonMap,
                                        navigateToProjectDashboard:
                                            _navigateToProjectDashboard,
                                        user: user!, navigateToProjectDirections: (project ) async {
                                          var poss = await cacheManager.getProjectPositions(project.projectId!);
                                          if (poss.isNotEmpty) {
                                            _navigateToDirections(
                                                latitude: poss.first.position!.coordinates[1],
                                                longitude: poss.first.position!.coordinates[0],);
                                          }
                                    },),
                                  )),
                              _showPositionChooser
                                  ? Positioned(
                                      child: AnimatedBuilder(
                                        animation: _animationController,
                                        builder: (BuildContext context,
                                            Widget? child) {
                                          return FadeScaleTransition(
                                            animation: _animationController,
                                            child: child,
                                          );
                                        },
                                        child: ProjectLocationChooser(
                                          onSelected: _onPositionSelected,
                                          onClose: _onClose,
                                          projectPositions: positions,
                                          polygons: polygons,
                                        ),
                                      ),
                                    )
                                  : const SizedBox(),
                            ],
                          ))));
  }

  double sliderValue = 3.0;
  void _onSliderChanged(double value) {
    pp('ProjectListMobile  🥏 🥏 🥏 🥏 🥏 _onSliderChanged: $value');
    setState(() {
      sliderValue = value;
    });

    refreshProjects(true);
  }
}
