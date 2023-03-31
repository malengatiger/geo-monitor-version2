import 'package:flutter/material.dart';
import 'package:geo_monitor/library/cache_manager.dart';
import 'package:geo_monitor/library/data/activity_model.dart';
import 'package:geo_monitor/library/functions.dart';
import 'package:geo_monitor/ui/activity/user_profile_card.dart';

import '../../l10n/translation_handler.dart';
import '../../library/api/prefs_og.dart';
import '../../library/data/activity_type_enum.dart';
import '../../library/data/user.dart';
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
    _getUser();
  }

  User? activityUser;
  String? translatedUserType;

  Future _getUser() async {
    if (widget.activityModel.userId != null) {
      activityUser =
      await cacheManager.getUserById(widget.activityModel.userId!);
    }
    if (activityUser != null) {
      translatedUserType = await getTranslatedUserType(activityUser!.userType!);
    }
    setState(() {});
  }

  void _getLocale() async {
    var sett = await prefsOGx.getSettings();
    if (sett != null) {
      locale = sett.locale;
    }
  }

  Widget _getUserAdded(Icon icon, String msg) {
    final dt = getFmtDate(widget.activityModel.date!, widget.locale);

    return activityUser == null
        ? const SizedBox()
        : Card(
            shape: getRoundedBorder(radius: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(
                    height: 4,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 0.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          dt,
                          style: myTextStyleSmallPrimaryColor(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  activityUser!.thumbnailUrl == null
                      ? const CircleAvatar(
                          radius: 16,
                        )
                      : UserProfileCard(
                          userName: widget.activityModel.userName!,
                          padding: 2,
                          elevation: 2,
                          avatarRadius: 20.0,
                          userType: translatedUserType == null
                              ? activityUser!.userType!
                              : translatedUserType!,
                          userThumbUrl: widget.activityModel.userThumbnailUrl,
                          namePictureHorizontal: false),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    msg,
                    style: myTextStyleTiny(context),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                ],
              ),
            ),
          );
  }

  Widget _getGeneric(Icon icon, String msg, double height) {
    return activityUser == null
        ? const SizedBox()
        : ThinCard(
            model: widget.activityModel,
            locale: widget.locale,
            width: 428,
            avatarRadius: 24.0,
            height: height,
            userType: translatedUserType == null
                ? activityUser!.userType!
                : translatedUserType!,
            icon: icon,
            message: msg,
            namePictureHorizontal: true,
          );
  }

  Widget _getShortie(Icon icon, String msg) {
    final dt = getFmtDate(widget.activityModel.date!, widget.locale);
    return Card(
      shape: getRoundedBorder(radius: 16),
      elevation: 4,
      child: SizedBox(
        height: 80,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dt,
                    style: myTextStyleTinyPrimaryColor(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
        return _getGeneric(icon, message, 160.0);

      case ActivityType.videoAdded:
        icon = Icon(Icons.video_camera_front,
            color: Theme.of(context).primaryColorLight);
        message = '${widget.activityModel.projectName}';
        return _getGeneric(icon, message, 160.0);

      case ActivityType.audioAdded:
        icon = Icon(Icons.mic, color: Theme.of(context).primaryColor);
        message = '${widget.activityModel.projectName}';
        return _getGeneric(icon, message, 160.0);

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
        message =
            '${widget.activityStrings.projectLocationAdded}: ${widget.activityModel.projectName}';
        return _getGeneric(icon, message, 160);

      case ActivityType.polygonAdded:
        icon =
            Icon(Icons.circle_outlined, color: Theme.of(context).primaryColor);
        message =
            '${widget.activityStrings.projectAreaAdded} ${widget.activityModel.projectName}';
        return _getGeneric(icon, message, 160);

      case ActivityType.settingsChanged:
        icon = Icon(Icons.settings, color: Theme.of(context).primaryColor);
        message = widget.activityStrings.settingsChanged!;
        return _getShortie(icon, message);

      case ActivityType.geofenceEventAdded:
        icon = Icon(Icons.person_2, color: Theme.of(context).primaryColor);
        message =
            '${widget.activityStrings.arrivedAt} - ${widget.activityModel.geofenceEvent?.projectName!}';
        return _getUserAdded(icon, message);

      case ActivityType.conditionAdded:
        icon = Icon(Icons.access_alarm, color: Theme.of(context).primaryColor);
        message = 'Project Condition added';
        return _getGeneric(icon, message, 120);

      case ActivityType.locationRequest:
        icon = Icon(Icons.location_on, color: Theme.of(context).primaryColor);
        message =
            '${widget.activityStrings.requestMemberLocation} ${widget.activityModel.locationRequest!.userName}';
        return _getGeneric(icon, message, 160);

      case ActivityType.locationResponse:
        icon =
            Icon(Icons.location_history, color: Theme.of(context).primaryColor);
        message =
            '${widget.activityStrings.memberLocationResponse} : ${widget.activityModel.locationResponse!.userName}';
        return _getGeneric(icon, message, 160);

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
      arrivedAt,
      noActivities,
      memberAtProject,
      memberAddedChanged,
      requestMemberLocation,
      tapToRefresh,
      settingsChanged;

  ActivityStrings(
      {required this.projectAdded,
      required this.projectLocationAdded,
      required this.projectAreaAdded,
      required this.at,
      required this.loadingActivities,
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
      final projectAdded = await translator.translate('projectAdded', sett!.locale!);
      final projectLocationAdded =
          await translator.translate('projectLocationAdded', sett.locale!);
      final projectAreaAdded =
          await translator.translate('projectAreaAdded', sett.locale!);
      final memberAtProject =
          await translator.translate('memberAtProject', sett.locale!);
      final settingsChanged =
          await translator.translate('settingsChanged', sett.locale!);
      final memberAddedChanged =
          await translator.translate('memberAddedChanged', sett.locale!);
      final at = await translator.translate('at', sett.locale!);
      final arr = await translator.translate('arrivedAt', sett.locale!);
      final arrivedAt = arr.replaceAll('\$project', '');
      final conditionAdded =
          await translator.translate('conditionAdded', sett.locale!);
      final memberLocationResponse =
          await translator.translate('memberLocationResponse', sett.locale!);
      final requestMemberLocation =
          await translator.translate('requestMemberLocation', sett.locale!);
      final noActivities = await translator.translate('noActivities', sett.locale!);

      final loadingActivities =
          await translator.translate('loadingActivities', sett.locale!);

      final tapToRefresh = await translator.translate('tapToRefresh', sett!.locale!);

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
