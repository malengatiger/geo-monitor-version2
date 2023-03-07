import 'package:flutter/material.dart';
import 'package:geo_monitor/ui/activity/user_profile_card.dart';

import '../../library/data/activity_model.dart';
import '../../library/functions.dart';

class ThinCard extends StatelessWidget {
  const ThinCard({Key? key, required this.model,
    required this.icon, required this.message,
    required this.width, required this.height}) : super(key: key);
  final ActivityModel model;
  final Icon icon;
  final String message;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final localDate =
    DateTime.parse(model.date!).toLocal().toIso8601String();
    final dt = getFormattedDateHourMinuteSecond(
        date: DateTime.parse(localDate), context: context);
    return SizedBox(width: width,
      child: Card(
        shape: getRoundedBorder(radius: 16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            height: height,
            child: Column(
              children: [
                const SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      dt,
                      style: myTextStyleSmallBoldPrimaryColor(context),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon,
                    const SizedBox(
                      width: 12,
                    ),
                    Flexible(
                      child: Text(
                        message,
                        style: myTextStyleTiny(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                Row(mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    model.userName == null? const SizedBox(): UserProfileCard(userName: model.userName!, userThumbUrl: model.userThumbnailUrl,),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WideCard extends StatelessWidget {
  const WideCard({Key? key, required this.model,
    required this.icon, required this.message, required this.width, required this.height}) : super(key: key);
  final ActivityModel model;
  final Icon icon;
  final String message;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final localDate =
    DateTime.parse(model.date!).toLocal().toIso8601String();
    final dt = getFormattedDateHourMinuteSecond(
        date: DateTime.parse(localDate), context: context);
    return SizedBox(width: width,
      child: Card(
        shape: getRoundedBorder(radius: 16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            height: height,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    icon,
                    const SizedBox(
                      width: 8,
                    ),
                    Flexible(
                      child: Text(
                        message,
                        style: myTextStyleSmall(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    children: [
                      Text(dt,
                        style: myNumberStyleMediumPrimaryColor(context),
                      )
                    ],
                  ),
                ),
                Row(
                  children: [
                    model.userName == null? const SizedBox(): UserProfileCard(userName: model.userName!, userThumbUrl: model.userThumbnailUrl,),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
