import 'package:flutter/material.dart';
import 'package:geo_monitor/library/data/activity_model.dart';
import 'package:geo_monitor/library/functions.dart';

import '../../l10n/translation_handler.dart';
import '../../library/api/prefs_og.dart';
import '../../library/data/activity_type_enum.dart';
import 'activity_cards.dart';

/// This widget manages the display of an ActivityModel
/// and handles the text translation of needed strings
class ActivityStreamCard extends StatefulWidget {
  const ActivityStreamCard(
      {Key? key,
      required this.activityModel,
      required this.frontPadding,
      required this.thinMode,
      required this.width,
      required this.activityStrings,
      required this.locale})
      : super(key: key);

  final ActivityModel activityModel;
  final double frontPadding;
  final bool thinMode;
  final double width;
  final ActivityStrings activityStrings;
  final String locale;

  @override
  ActivityStreamCardState createState() => ActivityStreamCardState();
}

class ActivityStreamCardState extends State<ActivityStreamCard> {
  int count = 0;

  static const mm = '🌿🌿🌿🌿🌿🌿 ActivityStreamCard: 🌿 ';
 String? locale;
  @override
  void initState() {
    super.initState();
    _getLocale();
  }

  void _getLocale() async {
    var sett = await prefsOGx.getSettings();
    if (sett != null) {
      locale = sett.locale;
    }
  }

  Widget _getUserAdded(Icon icon, String msg) {
    final dt = getFmtDate(widget.activityModel.date!, widget.locale);

    return widget.thinMode
        ? Card(
            shape: getRoundedBorder(radius: 16),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(
                    height: 8,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 0.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          dt,
                          style: myTextStyleSmallBoldPrimaryColor(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  widget.activityModel.userThumbnailUrl == null
                      ? const CircleAvatar(
                          radius: 16,
                        )
                      : CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(
                              widget.activityModel.userThumbnailUrl!),
                        ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    widget.activityModel.userName!,
                    style: myTextStyleTiny(context),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 14.0),
                    child: Text(
                      msg,
                      style: myTextStyleTiny(context),
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                ],
              ),
            ),
          )
        : Card(
            shape: getRoundedBorder(radius: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 120,
                child: Column(
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          icon,
                          const SizedBox(
                            width: 8,
                          ),
                          Flexible(
                            child: Text(
                              msg,
                              style: myTextStyleSmall(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: widget.frontPadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          widget.activityModel.userThumbnailUrl == null
                              ? const CircleAvatar(
                                  radius: 16,
                                )
                              : CircleAvatar(
                                  radius: 16,
                                  backgroundImage: NetworkImage(
                                      widget.activityModel.userThumbnailUrl!),
                                ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            widget.activityModel.userName!,
                            style: myTextStyleSmall(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: widget.frontPadding),
                      child: Row(
                        children: [
                          Text(
                            getFmtDate(
                                widget.activityModel.date!, widget.locale),
                            style: myTextStyleTinyBoldPrimaryColor(context),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  Widget _getGeneric(Icon icon, String msg, double height) {
    return widget.thinMode
        ? ThinCard(
            model: widget.activityModel,
            locale: widget.locale,
            width: 428,
            height: height,
            icon: icon,
            message: msg)
        : WideCard(
            model: widget.activityModel,
            width: 600,
            locale: widget.locale,
            height: height,
            icon: icon,
            message: msg);
  }

  @override
  Widget build(BuildContext context) {
    late Icon icon;
    late String message;

    switch (widget.activityModel.activityType!) {
      case ActivityType.projectAdded:
        icon = Icon(Icons.access_time, color: Theme.of(context).primaryColor);
        message = widget.activityStrings.projectAdded == null
            ? '${widget.activityStrings.projectAdded}: ${widget.activityModel.projectName}'
            : '${widget.activityStrings.projectAdded}: ${widget.activityModel.projectName}';
        return _getGeneric(icon, message, 80.0);

      case ActivityType.photoAdded:
        icon = Icon(Icons.camera_alt, color: Theme.of(context).primaryColor);
        message = '${widget.activityModel.projectName}';
        return _getGeneric(icon, message, 132.0);

      case ActivityType.videoAdded:
        icon = Icon(Icons.video_camera_front,
            color: Theme.of(context).primaryColorLight);
        message = '${widget.activityModel.projectName}';
        return _getGeneric(icon, message, 132.0);

      case ActivityType.audioAdded:
        icon = Icon(Icons.mic, color: Theme.of(context).primaryColor);
        message = '${widget.activityModel.projectName}';
        return _getGeneric(icon, message, 132.0);

      case ActivityType.messageAdded:
        icon = Icon(Icons.message, color: Theme.of(context).primaryColor);
        message = 'Message added';
        return _getGeneric(icon, message, 100);

      case ActivityType.userAddedOrModified:
        icon = Icon(Icons.person, color: Theme.of(context).primaryColor);
        message = '${widget.activityStrings.memberAddedChanged}';

        return _getUserAdded(icon, message);

      case ActivityType.positionAdded:
        icon = Icon(Icons.home, color: Theme.of(context).primaryColor);
        message = '${widget.activityStrings.projectLocationAdded}: ${widget.activityModel.projectName}';
        return _getGeneric(icon, message, 140);

      case ActivityType.polygonAdded:
        icon =
            Icon(Icons.circle_outlined, color: Theme.of(context).primaryColor);
        message =  '${widget.activityStrings.projectAreaAdded} ${widget.activityModel.projectName}';
        return _getGeneric(icon, message, 140);

      case ActivityType.settingsChanged:
        icon = Icon(Icons.settings, color: Theme.of(context).primaryColor);
        message =  widget.activityStrings.settingsChanged!;
        return _getGeneric(icon, message, 80);

      case ActivityType.geofenceEventAdded:
        icon = Icon(Icons.person_2, color: Theme.of(context).primaryColor);
        message = '${widget.activityStrings.arrivedAt} - ${widget.activityModel.geofenceEvent?.projectName!}';
        return _getUserAdded(icon, message);

      case ActivityType.conditionAdded:
        icon = Icon(Icons.access_alarm, color: Theme.of(context).primaryColor);
        message = 'Project Condition added';
        return _getGeneric(icon, message, 120);

      case ActivityType.locationRequest:
        icon = Icon(Icons.location_on, color: Theme.of(context).primaryColor);
        message = '${widget.activityStrings.requestMemberLocation} ${widget.activityModel.locationRequest!.userName}';
        return _getGeneric(icon, message, 120);

      case ActivityType.locationResponse:
        icon =
            Icon(Icons.location_history, color: Theme.of(context).primaryColor);
        message =  '${widget.activityStrings.memberLocationResponse} : ${widget.activityModel.locationResponse!.userName}';
        return _getGeneric(icon, message, 140);

      case ActivityType.kill:
        icon = Icon(Icons.cancel, color: Theme.of(context).primaryColor);
        message =
            'User KILL request made, cancel ${widget.activityModel.userName}';
        return _getGeneric(icon, message, 120);

      default:
        return const SizedBox(
          width: 300,
          child: Text('We got a Big Problem, Senor!'),
        );
    }
  }
}

class ActivityStrings {
  late String? projectAdded,
      projectLocationAdded,
      projectAreaAdded,
      at,
      loadingActivities,
      memberLocationResponse,
      conditionAdded,
      arrivedAt, noActivities,
      memberAtProject,
      memberAddedChanged,
      requestMemberLocation, tapToRefresh,
      settingsChanged;

  ActivityStrings(
      {required this.projectAdded,
      required this.projectLocationAdded,
      required this.projectAreaAdded,
      required this.at, required this.loadingActivities,
        required this.noActivities,
        required this.tapToRefresh,
      required this.memberLocationResponse,
      required this.conditionAdded,
      required this.arrivedAt,
      required this.memberAtProject,
      required this.memberAddedChanged,
      required this.requestMemberLocation,
      required this.settingsChanged});

  static Future<ActivityStrings?> getTranslated() async {
    var sett = await prefsOGx.getSettings();
    if (sett != null) {
      final projectAdded = await mTx.translate('projectAdded', sett!.locale!);
      final projectLocationAdded =
          await mTx.translate('projectLocationAdded', sett!.locale!);
      final projectAreaAdded =
          await mTx.translate('projectAreaAdded', sett!.locale!);
      final memberAtProject =
          await mTx.translate('memberAtProject', sett!.locale!);
      final settingsChanged =
          await mTx.translate('settingsChanged', sett!.locale!);
      final memberAddedChanged =
          await mTx.translate('memberAddedChanged', sett!.locale!);
      final at = await mTx.translate('at', sett!.locale!);
      final arr = await mTx.translate('arrivedAt', sett!.locale!);
      final arrivedAt = arr.replaceAll('\$project', '');
      final conditionAdded =
          await mTx.translate('conditionAdded', sett!.locale!);
      final memberLocationResponse =
          await mTx.translate('memberLocationResponse', sett!.locale!);
      final requestMemberLocation =
          await mTx.translate('requestMemberLocation', sett!.locale!);
      final noActivities =
      await mTx.translate('noActivities', sett!.locale!);

      final loadingActivities =
      await mTx.translate('loadingActivities', sett!.locale!);

      final tapToRefresh =
      await mTx.translate('tapToRefresh', sett!.locale!);

      var activityStrings = ActivityStrings(
          tapToRefresh: tapToRefresh,
          projectAdded: projectAdded,
          projectLocationAdded: projectLocationAdded,
          projectAreaAdded: projectAreaAdded,
          at: at,
          loadingActivities: loadingActivities,
          noActivities: noActivities,
          memberLocationResponse: memberLocationResponse,
          conditionAdded: conditionAdded,
          arrivedAt: arrivedAt,
          memberAtProject: memberAtProject,
          memberAddedChanged: memberAddedChanged,
          requestMemberLocation: requestMemberLocation,
          settingsChanged: settingsChanged);

      return activityStrings;
    }
    return null;
  }
}
