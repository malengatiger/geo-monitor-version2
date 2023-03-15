import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/fcm_bloc.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';
import 'package:geo_monitor/library/data/location_request.dart';

import '../../l10n/translation_handler.dart';
import '../../library/api/prefs_og.dart';
import '../../library/bloc/project_bloc.dart';
import '../../library/bloc/user_bloc.dart';
import '../../library/data/activity_model.dart';
import '../../library/data/audio.dart';
import '../../library/data/geofence_event.dart';
import '../../library/data/location_response.dart';
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
import 'activity_header.dart';
import 'activity_stream_card.dart';

class ActivityListTablet extends StatefulWidget {
  const ActivityListTablet(
      {Key? key,
      required this.width,
      required this.onPhotoTapped,
      required this.onVideoTapped,
      required this.onAudioTapped,
      required this.onUserTapped,
      required this.onProjectTapped,
      required this.onProjectPositionTapped,
      required this.onPolygonTapped,
      required this.onGeofenceEventTapped,
      required this.onOrgMessage,
      required this.thinMode,
      this.user,
      this.project,
      required this.onLocationResponse,
      required this.onLocationRequest, required this.settings})
      : super(key: key);
  final double width;
  final bool thinMode;
  final SettingsModel settings;
  final Function(Photo) onPhotoTapped;
  final Function(Video) onVideoTapped;
  final Function(Audio) onAudioTapped;
  final Function(User) onUserTapped;
  final Function(Project) onProjectTapped;
  final Function(ProjectPosition) onProjectPositionTapped;
  final Function(ProjectPolygon) onPolygonTapped;
  final Function(GeofenceEvent) onGeofenceEventTapped;
  final Function(OrgMessage) onOrgMessage;
  final Function(LocationResponse) onLocationResponse;
  final Function(LocationRequest) onLocationRequest;

  final User? user;
  final Project? project;

  @override
  State<ActivityListTablet> createState() => _ActivityListTabletState();
}

class _ActivityListTabletState extends State<ActivityListTablet>
    with SingleTickerProviderStateMixin {
  final ScrollController listScrollController = ScrollController();
  late AnimationController _animationController;

  var models = <ActivityModel>[];

  late StreamSubscription<ActivityModel> subscription;
  late StreamSubscription<SettingsModel> settingsSubscriptionFCM;

  User? me;
  bool busy = true;
  final mm = '😎😎😎😎😎😎 ActivityListTablet: ';

  @override
  void initState() {
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 3000),
        reverseDuration: const Duration(milliseconds: 2000),
        vsync: this);
    super.initState();
    _getData(true);
    _listenToFCM();
  }

  String? title;
  String?  prefix, suffix, loadingActivities, noActivities, tapToRefresh;

  void _getData(bool forceRefresh) async {
    pp('$mm ... getting activity data ... forceRefresh: $forceRefresh');
    loadingActivities =  await mTx.tx('loadingActivities', widget.settings.locale!);
    noActivities =  await mTx.tx('noActivities', widget.settings.locale!);
    tapToRefresh =  await mTx.tx('tapToRefresh', widget.settings.locale!);
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
      me = await prefsOGx.getUser();


      var hours = 12;

        hours = widget.settings.activityStreamHours!;
        var sub = await mTx.tx('activityTitle', widget.settings.locale!);
        int index = sub.indexOf('\$');
        prefix = sub.substring(0, index);
        suffix = sub.substring(index+6);
        pp('$mm prefix: $prefix suffix: $suffix');

        loadingActivities = await mTx.tx('loadingActivities', widget.settings.locale!);


      pp('$mm ... get Activity (n hours) ... : $hours');
      if (widget.project != null) {
        pp('$mm ... widget.project != null, should get project data');
        await _getProjectData(forceRefresh, hours);
      } else if (widget.user != null) {
        pp('$mm ... widget.user != null, should get user data');
        await _getUserData(forceRefresh, hours);
      } else {
        pp('$mm ... widget.project and widget.user == null, should get organization data');
        await _getOrganizationActivity(forceRefresh, hours);
      }
      _sortDescending();
      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      pp(e);
      if (mounted) {
        showToast(
            backgroundColor: Theme.of(context).primaryColor,
            textStyle: myTextStyleSmallBold(context),
            padding: 24,
            duration: const Duration(seconds: 6),
            message: '$e', context: context);
      }
    }
    setState(() {
      busy = false;
    });
  }

  Future _getOrganizationActivity(bool forceRefresh, int hours) async {
    models = await organizationBloc.getOrganizationActivity(
        organizationId: me!.organizationId!,
        hours: hours,
        forceRefresh: forceRefresh);
    pp('$mm org activity models found: ${models.length}');
    _sortDescending();
    setState(() {});
  }

  Future _getProjectData(bool forceRefresh, int hours) async {
    models = await projectBloc.getProjectActivity(
        projectId: widget.project!.projectId!,
        hours: hours,
        forceRefresh: forceRefresh);
    _sortDescending();
    setState(() {});
  }

  Future _getUserData(bool forceRefresh, int hours) async {
    models = await userBloc.getUserActivity(
        userId: widget.user!.userId!, hours: hours, forceRefresh: forceRefresh);
    _sortDescending();
    setState(() {});
  }

  void _listenToFCM() async {
    pp('$mm ... _listenToFCM activityStream ...');

    settingsSubscriptionFCM =
        fcmBloc.settingsStream.listen((SettingsModel event) {
          _getData(false);
          if (mounted) {
            pp('$mm activitySubscriptionFCM: DOING NOTHING!!!!!!!!!!!!!!');
            setState(() {});
          }
        });

    subscription = fcmBloc.activityStream.listen((ActivityModel model) {
      pp('$mm activityStream delivered activity data ... '
          'current models: ${models.length}\n\n');

      if (model.geofenceEvent != null) {
        models.insert(0, model);
        pp('$mm current models after insertion: ${models.length}\n');
        _sortDescending();
        return;
      }

      if (isActivityValid(model)) {
        models.insert(0, model);
        pp('$mm current models after insertion: ${models.length}\n');
        _sortDescending();
      }

      if (mounted) {
        pp('$mm mounted; setting state ...');
        setState(() {});
      }
    });
  }

  bool isActivityValid(ActivityModel m) {
    pp('$mm check validity of incoming activity');
    if (widget.project == null && widget.user == null) {
      pp('$mm  incoming activity is for organization');
      return true;
    }
    if (widget.project != null) {
      if (m.projectId == widget.project!.projectId) {
        pp('$mm  incoming activity is for project');
        return true;
      }
    }
    if (widget.user != null) {
      if (m.userId == widget.user!.userId) {
        pp('$mm  incoming activity is for user');
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
    if (busy) {
      return Center(
        child: Card(
          shape: getRoundedBorder(radius: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                  Text(loadingActivities == null?
                    'Loading activities': loadingActivities!,
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
        child: GestureDetector(
          onTap: (){
            _getData(true);
          },
          child: SizedBox(height: 200,
            child: Card(
              shape: getRoundedBorder(radius: 12),
              elevation: 8,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 32,),
                      Text(noActivities == null?
                        'No activities happening yet': noActivities!,
                        style: myTextStyleSmall(context),
                      ),
                      const SizedBox(height: 16,),
                      Text(tapToRefresh == null?
                        'Tap to refresh': tapToRefresh!,
                        style: myTextStyleSmallBold(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return widget.thinMode
        ? SizedBox(
            width: widget.width,
            child: SingleChildScrollView(
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 4.0, top: 12, bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: prefix == null? const SizedBox():ActivityHeader(
                            prefix: prefix!,
                            suffix: suffix!,
                            onRefreshRequested: () {
                              _getData(true);
                            },
                            hours:  widget.settings.activityStreamHours!,
                            number: models.length,
                          ),
                        ),
                      ),
                    ]),
                const SizedBox(
                  height: 4,
                ),
                ListView.builder(
                    shrinkWrap: true,
                    itemCount: models.length,
                    controller: listScrollController,
                    itemBuilder: (_, index) {
                      var act = models.elementAt(index);
                      return GestureDetector(
                        onTap: () {
                          _handleTappedActivity(act);
                        },
                        child:  ActivityStreamCard(
                          settings: widget.settings,
                          model: act,
                          frontPadding: 36,
                          thinMode: widget.thinMode,
                          width: widget.thinMode ? 320 : widget.width,
                        ),
                      );
                    }),
              ]),
            ),
          )
        : SizedBox(
            width: widget.width,
            child: SingleChildScrollView(
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 12.0, top: 12, bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: prefix == null? const SizedBox(): ActivityHeader(
                            prefix: prefix!,
                            suffix: suffix!,
                            onRefreshRequested: () {
                              _getData(true);
                            },
                            hours:  widget.settings.activityStreamHours!,
                            number: models.length,
                          ),
                        ),
                      ),
                    ]),
                const SizedBox(
                  height: 4,
                ),
                ListView.builder(
                    shrinkWrap: true,
                    itemCount: models.length,
                    controller: listScrollController,
                    itemBuilder: (_, index) {
                      var act = models.elementAt(index);
                      return GestureDetector(
                        onTap: () {
                          _handleTappedActivity(act);
                        },
                        child: ActivityStreamCard(
                          settings: widget.settings,
                          model: act,
                          frontPadding: 16,
                          thinMode: widget.thinMode,
                          width: widget.width,
                        ),
                      );
                    }),
              ]),
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

    if (act.user != null) {
      widget.onUserTapped(act.user!);
    }
    if (act.projectPosition != null) {
      widget.onProjectPositionTapped(act.projectPosition!);
    }
    if (act.locationRequest != null) {}
    if (act.locationResponse != null) {
      widget.onLocationResponse(act.locationResponse!);
    }
    if (act.geofenceEvent != null) {
      widget.onGeofenceEventTapped(act.geofenceEvent!);
    }
    if (act.orgMessage != null) {
      widget.onOrgMessage(act.orgMessage!);
    }
  }
}
