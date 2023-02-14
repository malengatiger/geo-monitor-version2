import 'package:flutter/material.dart';
import 'package:geo_monitor/library/users/list/user_list_tablet_portrait.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../../data/user.dart';
import 'user_list_mobile.dart';
import 'user_list_tablet_landscape.dart';

class UserListMain extends StatelessWidget {
  const UserListMain({Key? key, required this.user, required this.users}) : super(key: key);
  final User user;
  final List<User> users;
  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: const UserListMobile(),
      tablet: OrientationLayoutBuilder(
        portrait: (context) {
          return const UserListTabletPortrait(amInLandscape: false,);
        },
        landscape: (context) {
          return  const UserListTabletLandscape();
        },
      ),
    );
  }
}
