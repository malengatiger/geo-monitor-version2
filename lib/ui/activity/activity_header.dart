import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';

import '../../library/functions.dart';

class ActivityHeader extends StatelessWidget {
  const ActivityHeader(
      {Key? key,
      required this.onRefreshRequested,
      required this.hours,
      required this.number})
      : super(key: key);

  final Function() onRefreshRequested;
  final int hours;
  final int number;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {
            onRefreshRequested();
          },
          child: Row(
            children: [
              Text(
                'Activity Last',
                style: myTextStyleSmallBold(context),
              ),
              const SizedBox(
                width: 8,
              ),
              Text(
                '$hours',
                style: myTextStyleSmallBoldPrimaryColor(context),
              ),
              const SizedBox(
                width: 8,
              ),
              Text(
                'Hours',
                style: myTextStyleSmallBold(context),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: 32,
        ),
        GestureDetector(
          onTap: () {
            onRefreshRequested();
          },
          child: bd.Badge(
            badgeContent: Text(
              '$number',
              style: myTextStyleSmallBold(context),
            ),
            badgeStyle: bd.BadgeStyle(
                elevation: 8,
                badgeColor: getRandomColor(),
                padding: const EdgeInsets.all(8.0)),
          ),
        ),
      ],
    );
  }
}
