import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/fcm_bloc.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';
import 'package:geo_monitor/library/data/location_request.dart';
import 'package:geo_monitor/library/data/location_response.dart';
import 'package:geo_monitor/library/ui/media/list/project_videos_page.dart';
import 'package:geo_monitor/ui/activity/activity_header.dart';
import 'package:geo_monitor/ui/activity/activity_stream_card.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../l10n/translation_handler.dart';
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

class ActivityList extends StatefulWidget {
  const ActivityList({
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
    required this.user,
    required this.project,
    required this.onLocationResponse,
    required this.onLocationRequest,
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
  final Function(LocationResponse) onLocationResponse;
  final Function(LocationRequest) onLocationRequest;

  final User? user;
  final Project? project;

  @override
  State<ActivityList> createState() => ActivityListState();
}

class ActivityListState extends State<ActivityList>
    with SingleTickerProviderStateMixin {
  final ScrollController listScrollController = ScrollController();
  SettingsModel? settings;
  var models = <ActivityModel>[];
  late StreamSubscription<ActivityModel> subscription;
  late StreamSubscription<SettingsModel> settingsSubscriptionFCM;

  static const userActive = 0, projectActive = 1, orgActive = 2;
  late int activeType;
  User? user;
  bool busy = true;
  String? prefix,
      suffix,
      name,
      noActivities,
      title,
      loadingActivities,
      tapToRefresh;
  final mm = '😎😎😎😎😎😎 ActivityList: 😎';
  String? locale;
  ActivityStrings? activityStrings;
  bool sortedByDateAscending = false;
  bool sortedAscending = false;

  @override
  void initState() {
    super.initState();
    _setTexts();
    _getData(true);
    _listenToFCM();
  }

  @override
  void dispose() {
    settingsSubscriptionFCM.cancel();
    subscription.cancel();
    super.dispose();
  }

  Future _setTexts() async {
    user = await prefsOGx.getUser();
    settings = await prefsOGx.getSettings();
    locale = settings!.locale;
    if (widget.project != null) {
      title = await translator.translate('projectActivity', settings!.locale!);
      name = widget.project!.name!;
    } else if (widget.user != null) {
      title = await translator.translate('memberActivity', settings!.locale!);
      name = widget.user!.name;
    } else {
      title =
          await translator.translate('organizationActivity', settings!.locale!);
      name = user!.organizationName;
    }
    activityStrings = await ActivityStrings.getTranslated();
    loadingActivities =
        await translator.translate('loadingActivities', settings!.locale!);

    var sub = await translator.translate('activityTitle', settings!.locale!);
    int index = sub.indexOf('\$');
    prefix = sub.substring(0, index);
    suffix = sub.substring(index + 6);
    setState(() {});
  }

  Future _getData(bool forceRefresh) async {
    pp('$mm ... getting activity data ... forceRefresh: $forceRefresh');
    setState(() {
      busy = true;
    });
    pp('$mm ... getting activity data ... forceRefresh: $forceRefresh');
    try {
      settings = await prefsOGx.getSettings();
      var hours = 12;
      if (settings != null) {
        hours = settings!.activityStreamHours!;
      }
      pp('$mm ... get Activity (n hours) ... : $hours');
      if (widget.project != null) {
        activeType = projectActive;
        await _getProjectData(forceRefresh, hours);
      } else if (widget.user != null) {
        activeType = userActive;
        await _getUserData(forceRefresh, hours);
      } else {
        activeType = orgActive;
        await _getOrganizationData(forceRefresh, hours);
      }
      sortActivitiesDescending(models);
    } catch (e) {
      pp(e);
      if (mounted) {
        setState(() {
          busy = false;
        });
        showToast(
            backgroundColor: Theme.of(context).primaryColor,
            textStyle: myTextStyleMedium(context),
            padding: 16,
            duration: const Duration(seconds: 10),
            message: '$e',
            context: context);
      }
    }
    if (mounted) {
      setState(() {
        busy = false;
      });
    }
  }

  Future _getOrganizationData(bool forceRefresh, int hours) async {
    models = await organizationBloc.getCachedOrganizationActivity(
        organizationId: settings!.organizationId!, hours: hours);
    if (models.isNotEmpty) {
      setState(() {});
    }
    models = await organizationBloc.getOrganizationActivity(
        organizationId: settings!.organizationId!,
        hours: hours,
        forceRefresh: forceRefresh);
  }

  Future _getProjectData(bool forceRefresh, int hours) async {
    models = await projectBloc.getProjectActivity(
        projectId: widget.project!.projectId!,
        hours: hours,
        forceRefresh: forceRefresh);
  }

  Future _getUserData(bool forceRefresh, int hours) async {
    models = await userBloc.getUserActivity(
        userId: widget.user!.userId!, hours: hours, forceRefresh: forceRefresh);
  }

  void _listenToFCM() async {
    pp('$mm ... _listenToFCM activityStream ...');

    settingsSubscriptionFCM =
        fcmBloc.settingsStream.listen((SettingsModel event) async {
      if (mounted) {
        await _setTexts();
        _getData(true);
      }
    });

    subscription = fcmBloc.activityStream.listen((ActivityModel model) async {
      pp('$mm activityStream delivered activity data ... ${model.date!}, current models: ${models.length}');
      if (models.isEmpty || models.length == 1) {
        await _getData(true);
      } else {
        await _getData(false);
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

  void _sort() {
    if (sortedAscending) {
      sortActivitiesDescending(models);
      sortedAscending = false;
    } else {
      sortActivitiesAscending(models);
      sortedAscending = true;
    }
    //scroll to top after sort
    if (mounted) {
      setState(() {
        listScrollController.animateTo(
          listScrollController.position.minScrollExtent,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 500),
        );
      });
    }
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
    if (act.projectPosition != null) {
      widget.onProjectPositionTapped(act.projectPosition!);
    }
    if (act.locationRequest != null) {
      widget.onLocationRequest(act.locationRequest!);
    }
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


  @override
  Widget build(BuildContext context) {

    if (models.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(title == null ? 'Org Activity' : title!),
        ),
        body: Center(
          child: InkWell(
            onTap: () {
              _getData(true);
            },
            child: Card(
              shape: getRoundedBorder(radius: 16),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  activityStrings == null
                      ? 'No activities happening yet\n\nTap to Refresh'
                      : '${activityStrings!.noActivities!}\n\n ${activityStrings!.tapToRefresh!}',
                  style: myTextStyleMediumPrimaryColor(context),
                ),
              ),
            ),
          ),
        ),
      );
    }
    sortActivitiesDescending(models);

    return ScreenTypeLayout(
      tablet: OrientationLayoutBuilder(
        landscape: (context) {
          return Stack(
            children: [
              Column(
                children: [
                  InkWell(
                    onTap: () {
                      _getData(true);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: prefix == null
                          ? const SizedBox()
                          : ActivityHeader(
                        prefix: prefix!,
                        suffix: suffix!,
                        onRefreshRequested: () {
                          _getData(true);
                        },
                        hours: settings == null
                            ? 12
                            : settings!.activityStreamHours!,
                        number: models.length,
                        onSortRequested: _sort,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Expanded(
                    child: activityStrings == null
                        ? const SizedBox()
                        : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ActivityListCard(
                          models: models,
                          topPadding: 0.0,
                          onTapped: (act) {
                            _handleTappedActivity(act);
                          },
                          activityStrings: activityStrings!,
                          locale: settings!.locale!),
                    ),
                  ),
                ],
              ),
              Positioned(left: 12, right: 12,
                child: SizedBox(
                  height: 100,
                  child: Card(
                    shape: getRoundedBorder(radius: 12),
                    elevation: 10,
                    child: Center(
                      child:
                      Row(mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                                vertical: 12,
                              ),
                              child: prefix == null
                                  ? const SizedBox()
                                  : ActivityHeader(
                                prefix: prefix!,
                                suffix: suffix!,
                                onRefreshRequested: () {
                                  _getData(true);
                                },
                                hours: settings!.activityStreamHours!,
                                number: models.length,
                                onSortRequested: _sort,
                              ),
                            ),
                          ]),
                    ),
                  ),
                ),
              ),
              busy
                  ? Positioned(
                  bottom: 124,
                  left: 24,
                  child: loadingActivities == null
                      ? const SizedBox()
                      : LoadingCard(
                      loadingActivities: loadingActivities!))
                  : const SizedBox()
            ],
          );
        },
        portrait: (context ) {
        return Stack(
          children: [
            Column(
              children: [
                InkWell(
                  onTap: () {
                    _getData(true);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: prefix == null
                        ? const SizedBox()
                        : ActivityHeader(
                      prefix: prefix!,
                      suffix: suffix!,
                      onRefreshRequested: () {
                        _getData(true);
                      },
                      hours: settings == null
                          ? 12
                          : settings!.activityStreamHours!,
                      number: models.length,
                      onSortRequested: _sort,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Expanded(
                  child: activityStrings == null
                      ? const SizedBox()
                      : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ActivityListCard(
                        models: models,
                        topPadding: 0.0,
                        onTapped: (act) {
                          _handleTappedActivity(act);
                        },
                        activityStrings: activityStrings!,
                        locale: settings!.locale!),
                  ),
                ),
              ],
            ),
            Positioned(left: 12, right: 12,
              child: SizedBox(
                height: 100,
                child: Card(
                  shape: getRoundedBorder(radius: 12),
                  elevation: 8,
                  child: Center(
                    child:
                    Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 12,
                        ),
                        child: prefix == null
                            ? const SizedBox()
                            : ActivityHeader(
                          prefix: prefix!,
                          suffix: suffix!,
                          onRefreshRequested: () {
                            _getData(true);
                          },
                          hours: settings!.activityStreamHours!,
                          number: models.length,
                          onSortRequested: _sort,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
            busy
                ? Positioned(
                bottom: 124,
                left: 24,
                child: loadingActivities == null
                    ? const SizedBox()
                    : LoadingCard(
                    loadingActivities: loadingActivities!))
                : const SizedBox()
          ],
        );
      },),
      mobile: SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: Text(
                title == null ? 'Activity' : title!,
                style: myTextStyleMediumBold(context),
              ),
              actions: [
                IconButton(
                    onPressed: () {
                      _getData(true);
                    },
                    icon: Icon(
                      Icons.refresh,
                      color: Theme.of(context).primaryColor,
                    )),
              ],
              bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name == null ? 'Name' : name!,
                            style: myTextStyleLargePrimaryColor(context),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 24,
                      )
                    ],
                  )),
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        _getData(true);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: prefix == null
                            ? const SizedBox()
                            : ActivityHeader(
                                prefix: prefix!,
                                suffix: suffix!,
                                onRefreshRequested: () {
                                  _getData(true);
                                },
                                hours: settings == null
                                    ? 12
                                    : settings!.activityStreamHours!,
                                number: models.length,
                                onSortRequested: _sort,
                              ),
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Expanded(
                      child: activityStrings == null
                          ? const SizedBox()
                          : Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ActivityListCard(
                                  models: models,
                                  topPadding: 0.0,
                                  onTapped: (act) {
                                    _handleTappedActivity(act);
                                  },
                                  activityStrings: activityStrings!,
                                  locale: settings!.locale!),
                            ),
                    ),
                  ],
                ),
                busy
                    ? Positioned(
                        bottom: 124,
                        left: 24,
                        child: loadingActivities == null
                            ? const SizedBox()
                            : LoadingCard(
                                loadingActivities: loadingActivities!))
                    : const SizedBox()
              ],
            ),
        ),
      ),
    );
  }

}
/// holds and manages activity list
class ActivityListCard extends StatelessWidget {
  const ActivityListCard(
      {Key? key,
      required this.models,
      required this.onTapped,
      required this.activityStrings,
      required this.locale,
      this.topPadding})
      : super(key: key);

  final List<ActivityModel> models;
  final Function(ActivityModel) onTapped;
  final ActivityStrings activityStrings;
  final String locale;
  final double? topPadding;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: topPadding == null ? 100 : topPadding!,
      ),
      Expanded(
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: models.length,
            // controller: listScrollController,
            itemBuilder: (_, index) {
              var act = models.elementAt(index);
              return GestureDetector(
                onTap: () {
                  onTapped(act);
                },
                child: ActivityStreamCard(
                  locale: locale,
                  activityStrings: activityStrings!,
                  activityModel: act,
                  frontPadding: 36,
                  thinMode: true,
                  width: 300,
                ),
              );
            }),
      ),
    ]);
  }
}
