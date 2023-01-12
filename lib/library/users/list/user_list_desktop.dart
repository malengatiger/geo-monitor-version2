import 'package:flutter/material.dart';
import '../../data/user.dart';

class UserListDesktop extends StatefulWidget {
  final User user;

  const UserListDesktop(this.user, {super.key});

  @override
  UserListDesktopState createState() => UserListDesktopState();
}

class UserListDesktopState extends State<UserListDesktop>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
