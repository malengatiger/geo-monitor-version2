import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';

import '../../library/functions.dart';

class ActivityHeader extends StatelessWidget {
  const ActivityHeader(
      {Key? key,
      required this.onRefreshRequested,
      required this.hours,
      required this.number, required this.prefix, required this.suffix, required this.onSortRequested})
      : super(key: key);

  final Function() onRefreshRequested;
  final Function() onSortRequested;
  final int hours;
  final int number;
  final String prefix, suffix;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
          onPressed: () {
            onRefreshRequested();
          },
          child: Row(
            children: [
              SizedBox(width: 132,
                child: Text(prefix,
                  style: myTextStyleSmall(context),
                ),
              ),
              const SizedBox(
                width: 4,
              ),
              Text(
                '$hours',
                style: myTextStyleSmallBoldPrimaryColor(context),
              ),
              const SizedBox(
                width: 4,
              ),
              Text(
                suffix,
                style: myTextStyleSmall(context),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: 4,
        ),
        GestureDetector(
          onTap: () {
            onSortRequested();
          },
          child: bd.Badge(
            badgeContent: Text(
              '$number',
              style: myTextStyleSmallBold(context),
            ),
            badgeStyle: bd.BadgeStyle(
                elevation: 8,
                badgeColor: getRandomColor(),
                padding: const EdgeInsets.all(16.0)),
          ),
        ),
      ],
    );
  }
}
