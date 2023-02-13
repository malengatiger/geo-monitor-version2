import 'dart:async';

import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/fcm_bloc.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';

import '../../library/api/prefs_og.dart';
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

class ActivityList extends StatefulWidget {
  const ActivityList(
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
      required this.thinMode})
      : super(key: key);
  final double width;
  final bool thinMode;
  final Function(Photo) onPhotoTapped;
  final Function(Video) onVideoTapped;
  final Function(Audio) onAudioTapped;
  final Function(User) onUserTapped;
  final Function(Project) onProjectTapped;
  final Function(ProjectPosition) onProjectPositionTapped;
  final Function(ProjectPolygon) onPolygonTapped;
  final Function(GeofenceEvent) onGeofenceEventTapped;
  final Function(OrgMessage) onOrgMessage;

  @override
  State<ActivityList> createState() => _ActivityListState();
}

class _ActivityListState extends State<ActivityList> {
  final ScrollController listScrollController = ScrollController();
  SettingsModel? settings;
  var models = <ActivityModel>[];

  late StreamSubscription<ActivityModel> subscription;
  User? user;
  bool busy = true;
  final mm = '😎😎😎😎😎😎 ActivityList: ';

  @override
  void initState() {
    super.initState();
    _getData(true);
    _listenToFCM();
  }

  void _getData(bool forceRefresh) async {
    setState(() {
      busy = true;
    });
    pp('$mm ... getting activity data ... forceRefresh: $forceRefresh');
    try {
      user = await prefsOGx.getUser();
      settings = await prefsOGx.getSettings();
      pp('$mm ... getOrganizationActivity (n hours) ...');
      if (settings != null) {
        models = await organizationBloc.getOrganizationActivity(
            organizationId: settings!.organizationId!,
            hours: settings!.activityStreamHours!,
            forceRefresh: forceRefresh);
        if (count == 0 && !forceRefresh) {
          setState(() {});
          models = await organizationBloc.getOrganizationActivity(
              organizationId: settings!.organizationId!,
              hours: settings!.activityStreamHours!,
              forceRefresh: true);
          count++;
        }
      } else {
        var user = await prefsOGx.getUser();
        models = await organizationBloc.getOrganizationActivity(
            organizationId: user!.organizationId!,
            hours: 8,
            forceRefresh: forceRefresh);
      }
      _sortDescending();
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

  void _listenToFCM() async {
    pp('$mm ... _listenToFCM activityStream ...');

    subscription = fcmBloc.activityStream.listen((ActivityModel model) {
      pp('$mm activityStream delivered activity data ... ${model.date!}');
      models.insert(0, model);
      if (mounted) {
        setState(() {});
      }
    });
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
    return widget.thinMode
        ? SizedBox(
            width: widget.width,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 20.0, top: 12, bottom: 8),
                        child: bd.Badge(
                          badgeContent: Text(
                            '${models.length}',
                            style: myTextStyleSmall(context),
                          ),
                          badgeStyle: const bd.BadgeStyle(
                              elevation: 8,
                              badgeColor: Colors.pink,
                              padding: EdgeInsets.all(12.0)),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: TextButton(
                              onPressed: () {
                                _getData(true);
                              },
                              child: Text(
                                'Activity Last ${settings == null ? 12 : settings!.activityStreamHours!} hours',
                                style: myTextStyleSmallBold(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                            model: act,
                            frontPadding: 36,
                            thinMode: widget.thinMode,
                            width: widget.thinMode ? 160 : widget.width,
                          ),
                        );
                      }),
                ],
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(36.0),
            child: SizedBox(
              width: widget.width,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text(
                          'Activity Stream last ${settings == null ? 12 : settings!.activityStreamHours!} hours',
                          style: myTextStyleMediumBold(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        _getData(true);
                      },
                      child: bd.Badge(
                        position: bd.BadgePosition.topStart(),
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
                                  child: ActivityStreamCard(
                                    model: act,
                                    frontPadding: 36,
                                    thinMode: widget.thinMode,
                                    width: widget.thinMode ? 160 : widget.width,
                                  ));
                            }),
                      ),
                    ),
                  ),
                ],
              ),
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
