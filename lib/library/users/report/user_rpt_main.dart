import 'package:flutter/material.dart';

import 'package:responsive_builder/responsive_builder.dart';
import '../../data/user.dart';

import 'user_rpt_desktop.dart';
import 'user_rpt_mobile.dart';
import 'user_rpt_tablet.dart';

class UserReportMain extends StatelessWidget {
  final User user;

  const UserReportMain(this.user, {super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: UserReportMobile(user),
      tablet: UserReportTablet(user),
      desktop: UserReportDesktop(user),
    );
  }
}
