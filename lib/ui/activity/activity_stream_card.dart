import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';
import 'package:geo_monitor/library/data/activity_model.dart';
import 'package:geo_monitor/library/data/settings_model.dart';
import 'package:geo_monitor/library/functions.dart';

import '../../l10n/translation_handler.dart';
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
      required this.settings})
      : super(key: key);

  final ActivityModel activityModel;
  final double frontPadding;
  final bool thinMode;
  final double width;
  final SettingsModel settings;

  @override
  ActivityStreamCardState createState() => ActivityStreamCardState();
}

class ActivityStreamCardState extends State<ActivityStreamCard> {
  String? projectAdded,
      projectLocationAdded,
      projectAreaAdded,
      at,
      memberLocationResponse,
      conditionAdded,
      arrivedAt,
      memberAtProject,
      memberAddedChanged,
      requestMemberLocation,
      settingsChanged;

  int count = 0;

  static const mm = '🌿🌿🌿🌿🌿🌿 ActivityStreamCard: 🌿 ';
  late StreamSubscription<SettingsModel> settingsSubscription;

  @override
  void initState() {
    super.initState();
    _listen();
    _setTexts();
  }

  void _listen() async {
    settingsSubscription = organizationBloc.settingsStream.listen((event) {
      pp('\n$mm settingsSubscription delivered settings object, 🍎🍎🍎 will update translations');
      _setTexts();
    });
  }

  void _setTexts() async {
    projectAdded = await mTx.translate('projectAdded', widget.settings.locale!);
    projectLocationAdded =
        await mTx.translate('projectLocationAdded', widget.settings.locale!);
    projectAreaAdded =
        await mTx.translate('projectAreaAdded', widget.settings.locale!);
    memberAtProject = await mTx.translate('memberAtProject', widget.settings.locale!);
    settingsChanged = await mTx.translate('settingsChanged', widget.settings.locale!);
    memberAddedChanged =
        await mTx.translate('memberAddedChanged', widget.settings.locale!);
    at = await mTx.translate('at', widget.settings.locale!);
    var arr = await mTx.translate('arrivedAt', widget.settings.locale!);
    if (widget.activityModel.projectName != null) {
      arrivedAt =
          arr.replaceAll('\$project', widget.activityModel.projectName!);
    }
    conditionAdded = await mTx.translate('conditionAdded', widget.settings.locale!);
    memberLocationResponse =
        await mTx.translate('memberLocationResponse', widget.settings.locale!);
  }

  Widget _getUserAdded(Icon icon, String msg) {
    final localDate =
        DateTime.parse(widget.activityModel.date!).toLocal().toIso8601String();
    final dt = getFormattedDateHourMinuteSecond(
        date: DateTime.parse(localDate), context: context);
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
                            getFormattedDateShortWithTime(
                                widget.activityModel.date!, context),
                            style: myTextStyleTiny(context),
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
            width: 428,
            height: height,
            icon: icon,
            message: msg)
        : WideCard(
            model: widget.activityModel,
            width: 600,
            height: height,
            icon: icon,
            message: msg);
  }

  @override
  Widget build(BuildContext context) {
    count++;
    late Icon icon;
    late String message;

    switch (widget.activityModel.activityType!) {
      case ActivityType.projectAdded:
        icon = Icon(Icons.access_time, color: Theme.of(context).primaryColor);
        message = projectAdded == null
            ? 'Project added: ${widget.activityModel.projectName}'
            : '$projectAdded: ${widget.activityModel.projectName}';
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
        message = memberAddedChanged == null
            ? 'Added, modified or signed in'
            : memberAddedChanged!;
        return _getUserAdded(icon, message);

      case ActivityType.positionAdded:
        icon = Icon(Icons.home, color: Theme.of(context).primaryColor);
        message = projectLocationAdded == null
            ? 'Location added: ${widget.activityModel.projectName}'
            : '$projectLocationAdded: ${widget.activityModel.projectName}';
        return _getGeneric(icon, message, 140);

      case ActivityType.polygonAdded:
        icon =
            Icon(Icons.circle_outlined, color: Theme.of(context).primaryColor);
        message = projectAreaAdded == null
            ? 'Area added: ${widget.activityModel.projectName}'
            : '$projectAreaAdded ${widget.activityModel.projectName}';
        return _getGeneric(icon, message, 100);

      case ActivityType.settingsChanged:
        icon = Icon(Icons.settings, color: Theme.of(context).primaryColor);
        message = settingsChanged == null
            ? 'Settings changed or added'
            : settingsChanged!;
        return _getGeneric(icon, message, 80);

      case ActivityType.geofenceEventAdded:
        icon = Icon(Icons.person_2, color: Theme.of(context).primaryColor);
        message = arrivedAt == null
            ? 'at: ${widget.activityModel.geofenceEvent!.projectName!}'
            : '$arrivedAt';
        return _getUserAdded(icon, message);

      case ActivityType.conditionAdded:
        icon = Icon(Icons.access_alarm, color: Theme.of(context).primaryColor);
        message = 'Project Condition added';
        return _getGeneric(icon, message, 120);

      case ActivityType.locationRequest:
        icon = Icon(Icons.location_on, color: Theme.of(context).primaryColor);
        message = requestMemberLocation == null
            ? 'Location requested from ${widget.activityModel.locationRequest!.userName}'
            : '$requestMemberLocation ${widget.activityModel.locationRequest!.userName}';
        return _getGeneric(icon, message, 120);

      case ActivityType.locationResponse:
        icon =
            Icon(Icons.location_history, color: Theme.of(context).primaryColor);
        message = memberLocationResponse == null
            ? 'Location request responded to by ${widget.activityModel.locationResponse!.userName}'
            : '$memberLocationResponse : ${widget.activityModel.locationResponse!.userName}';
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
