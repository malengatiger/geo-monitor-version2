import 'package:flutter/material.dart';
import 'package:geo_monitor/library/users/edit/user_edit_tablet_portrait.dart';
import 'package:page_transition/page_transition.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/user.dart';
import '../../functions.dart';
import '../../ui/maps_field_monitor/field_monitor_map_mobile.dart';
import '../../ui/message/message_mobile.dart';
import '../../ui/schedule/scheduler_mobile.dart';
import '../kill_user_page.dart';
import '../report/user_rpt_mobile.dart';
import 'user_edit_main.dart';

class UserEditTabletLandscape extends StatelessWidget {
  const UserEditTabletLandscape({Key? key, this.user}) : super(key: key);
  final User? user;

  @override
  Widget build(BuildContext context) {
    void navigateToUserEdit(User? user) async {
      if (user!.userType == UserType.fieldMonitor) {
        if (user.userId != user.userId!) {

          return;
        }
      }
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(seconds: 1),
              child: UserEditMain(user)));

    }

    void navigateToUserReport(User user) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(seconds: 1),
              child: UserReportMobile(user)));
    }

    void navigateToMessaging(User user) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.bottomLeft,
              duration: const Duration(seconds: 1),
              child: MessageMobile(
                user: user,
              )));
    }

    Future<void> navigateToPhone(User user) async {
      pp('💛️💛️💛 ... starting phone call ....');
      final Uri phoneUri = Uri(
          scheme: "tel",
          path: user.cellphone!
      );
      try {
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
        }
      } catch (error) {
        throw("Cannot dial");
      }
    }

    void navigateToMap(User user) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.bottomLeft,
              duration: const Duration(seconds: 1),
              child: FieldMonitorMapMobile(user)));
    }

    void navigateToScheduler(User user) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.bottomLeft,
              duration: const Duration(seconds: 1),
              child: SchedulerMobile(user)));
    }

    bool sortedByName = false;

    Future<void> navigateToKillPage(User user) async {
      await Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.bottomLeft,
              duration: const Duration(seconds: 1),
              child: KillUserPage(
                user: user,
              )));
      pp('💛️💛️💛 ... back from KillPage; will refresh user list ....');

    }

    return Row(
      children: [
        SizedBox(width: 500, child: UserEditTabletPortrait(user: user, externalPadding: 24, internalPadding: 16,)),
        Container(width:400, color: Colors.yellow),
      ],
    );
  }

}
