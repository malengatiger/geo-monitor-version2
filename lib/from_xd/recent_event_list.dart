import 'package:flutter/material.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';
import 'package:geo_monitor/library/data/activity_model.dart';

import '../library/functions.dart';
import '../library/generic_functions.dart';

class RecentEventList extends StatefulWidget {
  const RecentEventList({Key? key}) : super(key: key);

  @override
  RecentEventListState createState() => RecentEventListState();
}

class RecentEventListState extends State<RecentEventList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  var activities = <ActivityModel>[];
  bool busy = false;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getData();
  }

  void _getData() async {
    setState(() {
      busy = true;
    });
    try {
      final user = await prefsOGx.getUser();
      activities = await organizationBloc.getCachedOrganizationActivity(organizationId: user!.organizationId!, hours: 300);
      setState(() {

      });
      activities = await organizationBloc.getOrganizationActivity(organizationId: user!.organizationId!, hours: 400, forceRefresh: true);
      pp('activities returned: ${activities.length}');
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
          itemCount: activities.length,
          itemBuilder: (_, index){
          final act = activities.elementAt(index);
        return EventView(activity: act, height: 48, width: 168);
      }),
    );
  }
}

class EventView extends StatelessWidget {
  const EventView(
      {Key? key,
        required this.activity,
        required this.height,
        required this.width})
      : super(key: key);
  final ActivityModel activity;
  final double height, width;
  @override
  Widget build(BuildContext context) {
    Icon icon = const Icon(Icons.access_time);
    if (activity.photo != null) {
      icon = const Icon(Icons.camera_alt_outlined);
    }
    if (activity.video != null) {
      icon = const Icon(Icons.video_camera_back_outlined);
    }

    return SizedBox(
      height: height,
      width: width,
      child: Card(
        shape: getRoundedBorder(radius: 10),
        elevation: 4,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  icon,
                  const SizedBox(
                    width: 8,
                  ),
                  Flexible(
                    child: Text(
                      '${activity.projectName}',
                      overflow: TextOverflow.ellipsis,
                      style: myTextStyleSmall(context),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}