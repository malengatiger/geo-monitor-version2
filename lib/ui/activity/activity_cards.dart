import 'package:flutter/material.dart';
import 'package:geo_monitor/ui/activity/user_profile_card.dart';

import '../../library/data/activity_model.dart';
import '../../library/functions.dart';

class ThinCard extends StatelessWidget {
  const ThinCard(
      {Key? key,
      required this.model,
      required this.icon,
      required this.message,
      required this.width,
      required this.height,
      required this.locale, required this.namePictureHorizontal})
      : super(key: key);
  final ActivityModel model;
  final Icon icon;
  final String message;
  final double width, height;
  final String locale;
  final bool namePictureHorizontal;

  @override
  Widget build(BuildContext context) {
    final localDate = DateTime.parse(model.date!).toLocal().toIso8601String();
    final dt = getFmtDate(localDate, locale);
    return SizedBox(
      width: width,
      child: Card(
        shape: getRoundedBorder(radius: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: height,
            child: Column(
              children: [
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      dt,
                      style: myTextStyleSmallPrimaryColor(context),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
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
                  height: 0,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    model.userName == null
                        ? const SizedBox()
                        : UserProfileCard(
                            namePictureHorizontal: namePictureHorizontal,
                            padding: 0,
                            elevation: 2,
                            userName: model.userName!,
                            textStyle: myTextStyleSmall(context),
                            userThumbUrl: model.userThumbnailUrl,
                          ),
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
  const WideCard(
      {Key? key,
      required this.model,
      required this.icon,
      required this.message,
      required this.width,
      required this.height,
      required this.locale})
      : super(key: key);
  final ActivityModel model;
  final Icon icon;
  final String message;
  final double width, height;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final localDate = DateTime.parse(model.date!).toLocal().toIso8601String();
    final dt = getFmtDate(localDate, locale);

    return SizedBox(
      width: width,
      child: Card(
        shape: getRoundedBorder(radius: 16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            height: height + 20,
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
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    dt,
                    style: myTextStyleSmallPrimaryColor(context),
                  ),
                ),
                Row(
                  children: [
                    model.userName == null
                        ? const SizedBox()
                        : UserProfileCard(
                            namePictureHorizontal: true,
                            userName: model.userName!,
                            userThumbUrl: model.userThumbnailUrl,
                          ),
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
