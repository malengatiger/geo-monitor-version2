import 'package:flutter/material.dart';
import '../../api/prefs_og.dart';
import '../../data/user.dart';
import '../../functions.dart';


class UserReportMobile extends StatefulWidget {
  final User user;
  const UserReportMobile(this.user, {super.key});

  @override
  UserReportMobileState createState() => UserReportMobileState();
}

class UserReportMobileState extends State<UserReportMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  User? admin;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getAdminUser();
  }

  void _getAdminUser() async {
    admin = await prefsOGx.getUser();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int userType = -1;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'User Report',
            style: myTextStyleMedium(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                Text(
                  '${widget.user.name}',
                  style: myTextStyleLarge(context),
                ),
                const SizedBox(
                  height: 40,
                )
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            Center(
              child: Text(
                'User Report here',
                style: myTextStyleMedium(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
