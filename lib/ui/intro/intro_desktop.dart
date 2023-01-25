import 'package:flutter/material.dart';

import '../../library/data/user.dart';

class IntroDesktop extends StatefulWidget {
  final User? user;
  const IntroDesktop({Key? key, this.user}) : super(key: key);
  @override
  IntroDesktopState createState() => IntroDesktopState();
}

class IntroDesktopState extends State<IntroDesktop>
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
