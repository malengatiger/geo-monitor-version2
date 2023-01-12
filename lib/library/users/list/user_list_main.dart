import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../../api/sharedprefs.dart';
import '../../data/user.dart';
import 'user_list_desktop.dart';
import 'user_list_mobile.dart';
import 'user_list_tablet.dart';

class UserListMain extends StatefulWidget {
  const UserListMain({Key? key}) : super(key: key);

  @override
  UserListMainState createState() => UserListMainState();
}

class UserListMainState extends State<UserListMain> {
  User? _user;
  bool isBusy = false;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  void _getUser() async {
    setState(() {
      isBusy = true;
    });
    _user = await Prefs.getUser();
    setState(() {
      isBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isBusy
        ? SafeArea(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Organization Users Loading'),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(100),
                  child: Column(),
                ),
              ),
              body: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 8,
                ),
              ),
            ),
          )
        : ScreenTypeLayout(
            mobile: UserListMobile(_user!),
            tablet: UserListTablet(_user!),
            desktop: UserListDesktop(_user!),
          );
  }
}
