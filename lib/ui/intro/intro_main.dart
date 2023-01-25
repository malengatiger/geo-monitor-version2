import 'package:flutter/material.dart';

import 'package:responsive_builder/responsive_builder.dart';

import '../../library/data/user.dart';
import 'intro_desktop.dart';
import 'intro_mobile.dart';
import 'intro_tablet.dart';

class IntroMain extends StatefulWidget {

  const IntroMain({Key? key, }) : super(key: key);

  @override
  IntroMainState createState() => IntroMainState();
}

/// Main Widget that manages a responsive layout for intro pages
class IntroMainState extends State<IntroMain> {
  var isBusy = false;
  User? user;
  @override
  void initState() {
    super.initState();

  }



  @override
  Widget build(BuildContext context) {
    return isBusy
        ? SafeArea(
            child: Scaffold(
              appBar: AppBar(
                title: const Text(('Loading User ..')),
              ),
              body: const Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    strokeWidth: 8,
                    backgroundColor: Colors.deepPurple,
                  ),
                ),
              ),
            ),
          )
        : ScreenTypeLayout(
            mobile: const IntroMobile(),
            tablet: IntroTablet(user: user),
            desktop: IntroDesktop(user: user),
          );
  }
}
