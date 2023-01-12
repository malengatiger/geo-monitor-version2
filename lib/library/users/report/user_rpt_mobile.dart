import 'package:flutter/material.dart';
import '../../api/sharedprefs.dart';
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
    admin = await Prefs.getUser();
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
            'User Editor',
            style: Styles.whiteSmall,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                Text(
                  widget.user == null ? 'New User' : 'Edit User',
                  style: Styles.blackBoldMedium,
                ),
                const SizedBox(
                  height: 40,
                )
              ],
            ),
          ),
        ),
        backgroundColor: Colors.brown[100],
        body: Stack(
          children: [
            Center(
              child: Text(
                'User Report',
                style: Styles.blueBoldLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
