import 'package:flutter/material.dart';

import '../../library/data/user.dart';

class IntroTablet extends StatefulWidget {
  final User? user;
  const IntroTablet({Key? key, this.user}) : super(key: key);

  @override
  IntroTabletState createState() => IntroTabletState();
}

class IntroTabletState extends State<IntroTablet>
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
