import 'package:flutter/material.dart';
import 'package:geo_monitor/library/users/edit/user_edit_tablet_landscape.dart';
import 'package:geo_monitor/library/users/edit/user_edit_tablet_portrait.dart';

import 'package:responsive_builder/responsive_builder.dart';

import '../../data/user.dart';
import 'user_edit_mobile.dart';

class UserEditMain extends StatelessWidget {
  final User? user;

  const UserEditMain(this.user, {super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: UserEditMobile(user),

      tablet: OrientationLayoutBuilder(
        portrait: (context) {
          return UserEditTabletPortrait(user: user, externalPadding: 72, internalPadding: 48,);
        },
        landscape: (context) {
          return  UserEditTabletLandscape(user: user,);
        },
      ),
    );
  }
}


