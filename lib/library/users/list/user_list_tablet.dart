import 'package:flutter/material.dart';
import '../../data/user.dart';

class UserListTablet extends StatefulWidget {
  final User user;

  const UserListTablet(this.user, {super.key});

  @override
  UserListTabletState createState() => UserListTabletState();
}

class UserListTabletState extends State<UserListTablet>
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
