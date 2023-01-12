import 'package:flutter/material.dart';
import '../../data/user.dart';

class UserEditTablet extends StatefulWidget {
  final User? user;

  const UserEditTablet(this.user, {super.key});

  @override
  UserEditTabletState createState() => UserEditTabletState();
}

class UserEditTabletState extends State<UserEditTablet>
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
