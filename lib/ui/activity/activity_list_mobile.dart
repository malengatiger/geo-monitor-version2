import 'dart:async';

import 'package:animations/animations.dart';
import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/fcm_bloc.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';
import 'package:geo_monitor/ui/activity/activity_header.dart';

import '../../library/api/prefs_og.dart';
import '../../library/bloc/project_bloc.dart';
import '../../library/bloc/user_bloc.dart';
import '../../library/data/activity_model.dart';
import '../../library/data/audio.dart';
import '../../library/data/geofence_event.dart';
import '../../library/data/org_message.dart';
import '../../library/data/photo.dart';
import '../../library/data/project.dart';
import '../../library/data/project_polygon.dart';
import '../../library/data/project_position.dart';
import '../../library/data/settings_model.dart';
import '../../library/data/user.dart';
import '../../library/data/video.dart';
import '../../library/functions.dart';
import '../../library/generic_functions.dart';
import 'activity_stream_card.dart';

class ActivityListMobile extends StatefulWidget {
  const ActivityListMobile({
    Key? key,
    required this.onPhotoTapped,
    required this.onVideoTapped,
    required this.onAudioTapped,
    required this.onUserTapped,
    required this.onProjectTapped,
    required this.onProjectPositionTapped,
    required this.onPolygonTapped,
    required this.onGeofenceEventTapped,
    required this.onOrgMessage,
    this.user,
    this.project,
  }) : super(key: key);

  final Function(Photo) onPhotoTapped;
  final Function(Video) onVideoTapped;
  final Function(Audio) onAudioTapped;
  final Function(User) onUserTapped;
  final Function(Project) onProjectTapped;
  final Function(ProjectPosition) onProjectPositionTapped;
  final Function(ProjectPolygon) onPolygonTapped;
  final Function(GeofenceEvent) onGeofenceEventTapped;
  final Function(OrgMessage) onOrgMessage;

  final User? user;
  final Project? project;

  @override
  State<ActivityListMobile> createState() => _ActivityListMobileState();
}

class _ActivityListMobileState extends State<ActivityListMobile>
    with SingleTickerProviderStateMixin {
  final ScrollController listScrollController = ScrollController();
  SettingsModel? settings;
  var models = <ActivityModel>[];
  late AnimationController _animationController;

  late StreamSubscription<ActivityModel> subscription;
  User? user;
  bool busy = true;
  final mm = '😎😎😎😎😎😎 ActivityListMobile: ';

  @override
  void initState() {
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 2000),
        reverseDuration: const Duration(milliseconds: 1000),
        vsync: this);
    super.initState();

    _getData(true);
    _listenToFCM();
  }

  void _getData(bool forceRefresh) async {
    pp('$mm ... getting activity data ... forceRefresh: $forceRefresh');
    if (models.isNotEmpty) {
      _animationController.reverse().then((value) {
        setState(() {
          busy = true;
        });
      });
    } else {
      setState(() {
        busy = true;
      });
    }
    pp('$mm ... getting activity data ... forceRefresh: $forceRefresh');
    try {
      settings = await prefsOGx.getSettings();
      var hours = 12;
      if (settings != null) {
        hours = settings!.activityStreamHours!;
      }
      pp('$mm ... get Activity (n hours) ... : $hours');
      if (widget.project != null) {
        _getProjectData(forceRefresh, hours);
      } else if (widget.user != null) {
        _getUserData(forceRefresh, hours);
      } else if (widget.project != null) {
        _getProjectData(forceRefresh, hours);
      } else {
        _getOrganizationData(forceRefresh, hours);
      }
      _sortDescending();
      _animationController.reset();
      _animationController.forward();
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

  void _getOrganizationData(bool forceRefresh, int hours) async {
    models = await organizationBloc.getOrganizationActivity(
        organizationId: settings!.organizationId!,
        hours: hours,
        forceRefresh: forceRefresh);
  }

  void _getProjectData(bool forceRefresh, int hours) async {
    models = await projectBloc.getProjectActivity(
        projectId: widget.project!.projectId!,
        hours: hours,
        forceRefresh: forceRefresh);
  }

  void _getUserData(bool forceRefresh, int hours) async {
    models = await userBloc.getUserActivity(
        userId: widget.user!.userId!, hours: hours, forceRefresh: forceRefresh);
  }

  void _listenToFCM() async {
    pp('$mm ... _listenToFCM activityStream ...');

    subscription = fcmBloc.activityStream.listen((ActivityModel model) {
      pp('$mm activityStream delivered activity data ... ${model.date!}');

      if (isActivityValid(model)) {
        models.insert(0, model);
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  bool isActivityValid(ActivityModel m) {
    if (widget.project == null && widget.user == null) {
      return true;
    }
    if (widget.project != null) {
      if (m.projectId == widget.project!.projectId) {
        return true;
      }
    }
    if (widget.user != null) {
      if (m.userId == widget.user!.userId) {
        return true;
      }
    }
    return false;
  }

  bool sortedByDateAscending = false;
  void _sort() {
    if (sortedByDateAscending) {
      _sortDescending();
    } else {
      _sortAscending();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _sortAscending() {
    models.sort((a, b) => a.date!.compareTo(b.date!));
    sortedByDateAscending = true;
  }

  void _sortDescending() {
    models.sort((a, b) => b.date!.compareTo(a.date!));
    sortedByDateAscending = false;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (busy) {
      return Center(
        child: Card(
          shape: getRoundedBorder(radius: 16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              height: 100,
              child: Column(
                children: [
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
                    'Loading activities ...',
                    style: myTextStyleSmall(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (models.isEmpty) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'No activities happening yet',
              style: myTextStyleSmall(context),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              _getData(true);
            },
            child: ActivityHeader(
              onRefreshRequested: () {
                _getData(true);
              },
              hours: settings == null ? 12 : settings!.activityStreamHours!,
              number: models.length,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                _getData(true);
              },
              child: bd.Badge(
                position: bd.BadgePosition.topEnd(end: 12),
                badgeContent: Text(
                  '${models.length}',
                  style: myTextStyleSmall(context),
                ),
                badgeStyle: const bd.BadgeStyle(
                    elevation: 8,
                    badgeColor: Colors.pink,
                    padding: EdgeInsets.all(16.0)),
                child: ListView.builder(
                    itemCount: models.length,
                    controller: listScrollController,
                    itemBuilder: (_, index) {
                      var act = models.elementAt(index);
                      return GestureDetector(
                          onTap: () {
                            _handleTappedActivity(act);
                          },
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (BuildContext context, Widget? child) {
                              return FadeScaleTransition(
                                animation: _animationController,
                                child: child,
                              );
                            },
                            child: ActivityStreamCard(
                              model: act,
                              frontPadding: 36,
                              thinMode: false,
                              width: width,
                            ),
                          ));
                    }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTappedActivity(ActivityModel act) async {
    if (act.photo != null) {
      widget.onPhotoTapped(act.photo!);
    }
    if (act.video != null) {
      widget.onVideoTapped(act.video!);
    }

    if (act.audio != null) {
      widget.onAudioTapped(act.audio!);
    }

    if (act.user != null) {}
    if (act.projectPosition != null) {}
    if (act.locationRequest != null) {}
    if (act.locationResponse != null) {}
    if (act.geofenceEvent != null) {}
    if (act.orgMessage != null) {}
  }
}
