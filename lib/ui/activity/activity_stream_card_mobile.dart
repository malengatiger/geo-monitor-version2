import 'package:flutter/material.dart';
import 'package:geo_monitor/library/cache_manager.dart';
import 'package:geo_monitor/library/data/activity_model.dart';
import 'package:geo_monitor/library/functions.dart';

import '../../library/data/activity_type_enum.dart';
import '../../library/data/user.dart';

class ActivityStreamCardMobile extends StatefulWidget {
  const ActivityStreamCardMobile(
      {Key? key,
      required this.model,
      required this.frontPadding,
      required this.thinMode,
      required this.width})
      : super(key: key);

  final ActivityModel model;
  final double frontPadding;
  final bool thinMode;
  final double width;

  @override
  ActivityStreamCardMobileState createState() =>
      ActivityStreamCardMobileState();
}

class ActivityStreamCardMobileState extends State<ActivityStreamCardMobile> {
  User? user;
  @override
  void initState() {
    super.initState();
    _getUser();
  }

  void _getUser() async {
    if (widget.model.userId != null) {
      user = await cacheManager.getUserById(widget.model.userId!);
    } else if (widget.model.user != null) {
      user = widget.model.user;
    } else if (widget.model.photo != null) {
      user = await cacheManager.getUserById(widget.model.photo!.userId!);
    } else if (widget.model.video != null) {
      user = await cacheManager.getUserById(widget.model.video!.userId!);
    } else if (widget.model.audio != null) {
      user = await cacheManager.getUserById(widget.model.audio!.userId!);
    } else if (widget.model.geofenceEvent != null) {
      user = await cacheManager
          .getUserById(widget.model.geofenceEvent!.user!.userId!);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Widget _getUserAdded(Icon icon, String msg) {
    final localDate =
        DateTime.parse(widget.model.date!).toLocal().toIso8601String();
    final dt = getFormattedDateHourMinuteSecond(
        date: DateTime.parse(localDate), context: context);
    return user == null
        ? Container()
        : widget.thinMode
            ? Card(
                shape: getRoundedBorder(radius: 16),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 8,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
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
                      user!.thumbnailUrl == null
                          ? const CircleAvatar(
                              radius: 24,
                            )
                          : CircleAvatar(
                              radius: 24,
                              backgroundImage:
                                  NetworkImage(user!.thumbnailUrl!),
                            ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        '${user!.name}',
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
                        Row(
                          children: [
                            icon,
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              msg,
                              style: myTextStyleSmall(context),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: widget.frontPadding),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              user!.thumbnailUrl == null
                                  ? const CircleAvatar(
                                      radius: 16,
                                    )
                                  : CircleAvatar(
                                      radius: 16,
                                      backgroundImage:
                                          NetworkImage(user!.thumbnailUrl!),
                                    ),
                              const SizedBox(
                                width: 8,
                              ),
                              Text(
                                '${user!.name}',
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
                                    widget.model.date!, context),
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

  Widget _getGeneric({required Icon icon, required String? msg}) {
    int? duration;
    if (widget.model.audio != null) {
      if (widget.model.audio!.durationInSeconds != null) {
        duration = widget.model.audio!.durationInSeconds!;
      }
    }
    if (widget.model.video != null) {
      if (widget.model.video!.durationInSeconds != null) {
        duration = widget.model.video!.durationInSeconds!;
      }
    }
    var mDuration = '';
    if (duration != null) {
      mDuration = getHourMinuteSecond(Duration(seconds: duration));
    }
    var height = 80;
    if (msg == null) {
      if (mDuration.isEmpty) {
        height = 80;
      } else {
        height = 120;
      }
    } else {
      height = 120;
    }

    return Card(
      shape: getRoundedBorder(radius: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          height: height.toDouble(),
          child: Column(
            children: [
              const SizedBox(
                height: 12,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  icon,
                  const SizedBox(
                    width: 8,
                  ),
                  Text(
                    getFormattedDateShortWithTime(widget.model.date!, context),
                    style: myTextStyleSmall(context),
                  ),
                ],
              ),
              SizedBox(
                height: mDuration.isEmpty ? 0 : 12,
              ),
              mDuration.isNotEmpty
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Duration:',
                          style: myTextStyleTiny(context),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Text(
                          mDuration,
                          style: myNumberStyleMediumPrimaryColor(context),
                        )
                      ],
                    )
                  : const SizedBox(),
              SizedBox(
                height: mDuration.isEmpty ? 8 : 12,
              ),
              msg == null
                  ? const SizedBox()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 28,
                        ),
                        Flexible(
                          child: Text(
                            msg,
                            style: myTextStyleSmall(context),
                          ),
                        ),
                      ],
                    ),
              user == null
                  ? const SizedBox()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${user!.name}',
                          style: myTextStyleSmall(context),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        user!.thumbnailUrl == null
                            ? const CircleAvatar(
                                radius: 14,
                              )
                            : CircleAvatar(
                                backgroundImage:
                                    NetworkImage(user!.thumbnailUrl!),
                                radius: 18,
                              )
                      ],
                    )
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

    switch (widget.model.activityType!) {
      case ActivityType.projectAdded:
        icon = Icon(Icons.access_time, color: Theme.of(context).primaryColor);
        message = 'Project Added: \n${widget.model.projectName}';
        return _getGeneric(icon: icon, msg: message);

      case ActivityType.photoAdded:
        icon = Icon(Icons.camera_alt, color: Theme.of(context).primaryColor);
        return _getGeneric(icon: icon, msg: null);

      case ActivityType.videoAdded:
        icon = Icon(Icons.video_camera_front,
            color: Theme.of(context).primaryColorLight);
        return _getGeneric(icon: icon, msg: null);

      case ActivityType.audioAdded:
        icon = Icon(Icons.mic, color: Theme.of(context).primaryColor);
        return _getGeneric(icon: icon, msg: null);

      case ActivityType.messageAdded:
        icon = Icon(Icons.message, color: Theme.of(context).primaryColor);
        message = 'Message:';
        return _getGeneric(icon: icon, msg: message);

      case ActivityType.userAddedOrModified:
        icon = Icon(Icons.person, color: Theme.of(context).primaryColor);
        message = 'Added, modified or signed in';
        return _getUserAdded(icon, message);

      case ActivityType.positionAdded:
        icon = Icon(Icons.home, color: Theme.of(context).primaryColor);
        message = 'Location added:\n${widget.model.projectName}';
        return _getGeneric(icon: icon, msg: message);

      case ActivityType.polygonAdded:
        icon =
            Icon(Icons.circle_outlined, color: Theme.of(context).primaryColor);
        message = 'Area added: \n${widget.model.projectName}';
        return _getGeneric(icon: icon, msg: message);

      case ActivityType.settingsChanged:
        icon = Icon(Icons.settings, color: Theme.of(context).primaryColor);
        message = 'Settings changed or added';
        return _getGeneric(icon: icon, msg: message);

      case ActivityType.geofenceEventAdded:
        icon = Icon(Icons.person_2, color: Theme.of(context).primaryColor);
        message =
            'Possible Member Arrival: \n${widget.model.geofenceEvent!.projectName!}';
        return _getUserAdded(icon, message);

      case ActivityType.conditionAdded:
        icon = Icon(Icons.access_alarm, color: Theme.of(context).primaryColor);
        message = 'Condition added: ${widget.model.projectName}';
        return _getGeneric(icon: icon, msg: message);

      case ActivityType.locationRequest:
        icon = Icon(Icons.location_on, color: Theme.of(context).primaryColor);
        message =
            'Location requested from ${widget.model.locationRequest!.userName}';
        return _getGeneric(icon: icon, msg: message);

      case ActivityType.locationResponse:
        icon =
            Icon(Icons.location_history, color: Theme.of(context).primaryColor);
        message =
            'Location request responded to by ${widget.model.locationResponse!.userName}';
        return _getGeneric(icon: icon, msg: message);

      case ActivityType.kill:
        icon = Icon(Icons.cancel, color: Theme.of(context).primaryColor);
        message = 'User KILL request made, cancel ${widget.model.userName}';
        return _getGeneric(icon: icon, msg: message);

      default:
        return const SizedBox(
          width: 300,
          child: Text('We got a problem, Senor!'),
        );
    }
  }
}
