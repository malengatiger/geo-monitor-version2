import 'package:animations/animations.dart';
import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart' as geo;
// import 'package:location/location.dart';
import 'package:page_transition/page_transition.dart';
import 'package:uuid/uuid.dart';

import '../../../device_location/device_location_bloc.dart';
import '../../api/data_api.dart';
import '../../api/prefs_og.dart';
import '../../bloc/organization_bloc.dart';
import '../../bloc/project_bloc.dart';
import '../../data/city.dart';
import '../../data/place_mark.dart';
import '../../data/position.dart' as mon;
import '../../data/project.dart';
import '../../data/project_polygon.dart';
import '../../data/project_position.dart';
import '../../data/user.dart';
import '../../functions.dart';
import '../maps/project_map_mobile.dart';
import '../maps/project_polygon_map_mobile.dart';

class ProjectLocationMobile extends StatefulWidget {
  final Project project;

  const ProjectLocationMobile(this.project, {super.key});

  @override
  ProjectLocationMobileState createState() => ProjectLocationMobileState();
}

class ProjectLocationMobileState extends State<ProjectLocationMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  var busy = false;
  List<ProjectPosition> _projectPositions = [];
  List<ProjectPolygon> _projectPolygons = [];
  final _key = GlobalKey<ScaffoldState>();
  static const mx = '💙💙💙ProjectLocationMobile: 💙 ';
  User? user;

  @override
  void initState() {
    _animationController = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 2000),
        reverseDuration: const Duration(milliseconds: 1000),
        vsync: this);
    super.initState();
    _getProjectPositions(false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _isLocationWithinProjectMonitorDistance() async {
    pp('$mx calculating _isLocationWithinProjectMonitorDistance .... '
        '${widget.project.monitorMaxDistanceInMetres!} metres');

    var map = <double, ProjectPosition>{};
    for (var i = 0; i < _projectPositions.length; i++) {
      var projPos = _projectPositions.elementAt(i);
      var dist = await locationBloc.getDistanceFromCurrentPosition(
          latitude: projPos.position!.coordinates.elementAt(1),
          longitude: projPos.position!.coordinates.elementAt(0));

      map[dist] = projPos;
      pp('$mx Distance: 🌶 $dist metres 🌶 projectId: ${projPos.projectId} 🐊 projectPositionId: ${projPos.projectPositionId}');
    }

    if (map.isNotEmpty) {
      var list = map.keys.toList();
      list.sort();
      pp('$mx Distances in list, length: : ${list.length} $list');
      if (list.elementAt(0) <=
          widget.project.monitorMaxDistanceInMetres!.toInt()) {
        return true;
      }
    }
    var loc = await locationBloc.getLocation();
    if (loc != null) {
      var mOK = checkIfLocationIsWithinPolygons(
          polygons: _projectPolygons,
          latitude: loc.latitude!,
          longitude: loc.longitude!);
      return mOK;
    }
    return false;
  }

  bool isWithin = false;

  Future _getLocation() async {
    try {
      _position = await locationBloc.getLocation();
      if (_position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Current Location not available')));
        }
        return;
      }
    } catch (e) {
      pp(e);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: const Duration(seconds: 5), content: Text('$e')));
    }
  }

  void _getProjectPositions(bool forceRefresh) async {
    pp('$mx _getProjectPositions .... refresh project data ... ');
    setState(() {
      busy = true;
    });

    try {
      user = await prefsOGx.getUser();
      await _getLocation();
      _projectPositions = await projectBloc.getProjectPositions(
          projectId: widget.project.projectId!, forceRefresh: forceRefresh);
      _projectPolygons = await projectBloc.getProjectPolygons(
          projectId: widget.project.projectId!, forceRefresh: forceRefresh);

      pp('$mx _projectPositions found: ${_projectPositions.length}; checking location within project monitorDistance...');
    } catch (e) {
      pp(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            duration: const Duration(seconds: 5),
            content: Text('Data refresh failed: $e')));
      }
    }
    if (mounted) {
      setState(() {
        busy = false;
      });
      _animationController.forward();
    }
  }

  void _submit() async {
    pp('$mx submit new project position .. check first .... ');
    var isOK = await _isLocationWithinProjectMonitorDistance();
    if (isOK) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            duration: const Duration(seconds: 5),
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text(
              'There is a project location here already for ${widget.project.name}',
              style: myTextStyleMedium(context),
            )));
      }
      return;
    }
    setState(() {
      busy = true;
    });

    pp('$mx getting possible place marks  ..........');

    List<Placemark>? placeMarks;
    try {
      placeMarks = await placemarkFromCoordinates(
          _position!.latitude!, _position!.longitude!);
    } catch (e) {
      pp(e);
    }

    try {
      List<City> cities = await DataAPI.findCitiesByLocation(
          latitude: _position!.latitude!,
          longitude: _position!.longitude!,
          radiusInKM: 10.0);
      pp('$mx Cities found for project position: ${cities.length}');
      pp('$mx submitting current position ..........');
      Placemark? pm;
      if (placeMarks != null) {
        if (placeMarks.isNotEmpty) {
          pm = placeMarks.first;
          pp('$mx Placemark for project location: ${pm.toString()}');
        }
      }
      var org = await prefsOGx.getUser();
      var loc = ProjectPosition(
          userId: user!.userId,
          userName: user!.name,
          placemark: pm == null ? null : PlaceMark.getPlaceMark(placemark: pm),
          projectName: widget.project.name,
          caption: 'tbd',
          organizationId: org!.organizationId,
          created: DateTime.now().toUtc().toIso8601String(),
          position: mon.Position(
              type: 'Point',
              coordinates: [_position!.longitude, _position!.latitude]),
          projectId: widget.project.projectId,
          nearestCities: cities,
          projectPositionId: const Uuid().v4());
      try {
        var m = await DataAPI.addProjectPosition(position: loc);
        pp('$mx  _submit: new projectPosition added .........  🍅 ${m.toJson()} 🍅');
        organizationBloc.addProjectPositionToStream(m);
        _getProjectPositions(true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Project Position failed: $e')));
        }
      }

      if (mounted) {
        setState(() {
          busy = false;
        });
        Navigator.pop(context, loc);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  dynamic _position;

  Future<void> _navigateToProjectPolygonMap() async {
    pp('... _navigateToProjectMap: about to navigate ');

    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.leftToRightWithFade,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1000),
              child: ProjectPolygonMapMobile(
                project: widget.project,
              )));
    }
  }

  Future<void> _navigateToProjectPositionMap() async {
    pp('... _navigateToProjectMap: about to navigate ');

    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.leftToRightWithFade,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1000),
              child: ProjectMapMobile(
                project: widget.project,
              )));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _key,
        appBar: AppBar(
          leading: const SizedBox(),
          title: Text(
            'Project Locations',
            style: myTextStyleLarge(context),
          ),
          actions: [
            IconButton(
                onPressed: () async {
                  pp('$mx ........ navigate to map when ready! ');
                  _navigateToProjectPolygonMap();
                },
                icon: Icon(Icons.map,
                    size: 20, color: Theme.of(context).primaryColor)),
            IconButton(
                onPressed: () async {
                  //refresh
                  _animationController.reset();
                  await _getLocation();
                  setState(() {});
                  _animationController.forward();
                },
                icon: Icon(
                  Icons.refresh,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                )),
            const SizedBox(
              width: 20,
            )
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(260),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    '${widget.project.name}',
                    style: myTextStyleLargerPrimaryColor(context),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Text(
                    'Add a Project Location at this location that you are at. '
                    'This location will be enabled for monitoring the project or event.',
                    style: myTextStyleMedium(context),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    'If you want to create a new Project Area tap the map icon at top right '
                    'to go to a map that will help you do that',
                    style: myTextStyleMedium(context),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Row(
                    children: [
                      Text(
                        'Project Locations:',
                        style: myTextStyleSmall(context),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(
                        '${_projectPositions.length + _projectPolygons.length}',
                        style: myNumberStyleMedium(context),
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
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (BuildContext context, Widget? child) {
              return FadeScaleTransition(
                animation: _animationController,
                child: child,
              );
            },
            child: bd.Badge(
              badgeContent:
                  Text('${_projectPositions.length + _projectPolygons.length}'),
              badgeStyle: bd.BadgeStyle(
                badgeColor: Theme.of(context).primaryColor,
                elevation: 8,
                padding: const EdgeInsets.all(8),
              ),
              position: bd.BadgePosition.topEnd(top: -8, end: 16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0)),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 48,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            'Current Location',
                            style: myTextStyleLarge(context),
                          ),
                          const SizedBox(
                            height: 48,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    'Latitude',
                                    style: myTextStyleSmall(context),
                                  ),
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                _position == null
                                    ? const SizedBox()
                                    : Text(
                                        _position!.latitude!.toStringAsFixed(6),
                                        style: myNumberStyleLarge(context),
                                      ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    'Longitude',
                                    style: myTextStyleSmall(context),
                                  ),
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                _position == null
                                    ? const SizedBox()
                                    : Text(
                                        _position!.longitude!
                                            .toStringAsFixed(6),
                                        style: myNumberStyleLarge(context),
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 36,
                    ),
                    busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              backgroundColor: Colors.black,
                            ),
                          )
                        : SizedBox(
                            height: 120,
                            child: Column(
                              children: [
                                ElevatedButton(
                                  onPressed: _submit,
                                  style: ButtonStyle(
                                    shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                        // side: const BorderSide(color: Colors.pink)
                                      ),
                                    ),
                                    elevation:
                                        MaterialStateProperty.all<double>(8.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 20,
                                        right: 20,
                                        top: 12,
                                        bottom: 12),
                                    child: Text(
                                      'Add Project Location',
                                      style: Styles.whiteSmall,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                ElevatedButton(
                                  onPressed: _navigateToProjectPositionMap,
                                  style: ButtonStyle(
                                    shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                        // side: const BorderSide(color: Colors.pink)
                                      ),
                                    ),
                                    elevation:
                                        MaterialStateProperty.all<double>(8.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 20,
                                        right: 20,
                                        top: 12,
                                        bottom: 12),
                                    child: Text(
                                      'Add Location Elsewhere',
                                      style: myTextStyleMedium(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    const SizedBox(
                      height: 16,
                    ),
                    TextButton(
                        onPressed: () {
                          _shutDown();
                        },
                        child: const Text('Cancel')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _shutDown() {
    Navigator.of(context).pop();
  }
}
