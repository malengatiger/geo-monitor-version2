import 'dart:async';

import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/generic_functions.dart';
import 'package:page_transition/page_transition.dart';


import '../library/emojis.dart';
import '../library/functions.dart';
import '../library/users/org_registration.dart';
import '../library/data/user.dart' as ur;
import '../library/users/phone_login.dart';
import 'dashboard/dashboard_mobile.dart';
import 'intro_page_one.dart';

class IntroPageViewer extends StatefulWidget {
  const IntroPageViewer({Key? key}) : super(key: key);

  @override
  IntroPageViewerState createState() => IntroPageViewerState();
}

class IntroPageViewerState extends State<IntroPageViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final PageController _pageController = PageController();
  bool authed = false;
  fb.FirebaseAuth firebaseAuth = fb.FirebaseAuth.instance;
  ur.User? user;
  late StreamSubscription<String> killSubscription;


  final mm =
      '${E.pear}${E.pear}${E.pear}${E.pear} IntroPageViewer: ';

  @override
  void initState() {
    _animationController = AnimationController(vsync: this);
    super.initState();
    _getAuthenticationStatus();
    killSubscription = listenForKill(context: context);


  }

  void _getAuthenticationStatus() async {
    var cUser = firebaseAuth.currentUser;
    if (cUser != null) {
      setState(() {
        authed = true;
      });
    }
  }

  void _navigateToDashboard() {

    if (user != null) {
      Navigator.of(context).pop();
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(seconds: 2),
              child: DashboardMobile(user: user!,)));
    } else {
      pp('User is null,  🔆 🔆 🔆 🔆 cannot navigate to Dashboard');
    }
  }
  void _navigateToDashboardWithoutUser() {

      Navigator.of(context).pop();
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(seconds: 2),
              child: const DashboardMobile()));

  }

  Future<void> _navigateToSignIn() async {
    var result = await Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: const PhoneLogin()));

    var user = await prefsOGx.getUser();
    if (user != null) {
      pp('$mm 👌👌👌 Returned from sign in; will navigate to Dashboard :  👌👌👌 ${result.toJson()}');
      setState(() {
        user = result;
      });
      _navigateToDashboard();
    } else {
      pp('$mm 😡😡Returned from sign in; cached user not found. NOT GOOD! 😡');
      if (mounted) {
        showToast(message: 'Phone Sign In Failed',
            duration: const Duration(seconds: 5),
            backgroundColor: Theme.of(context).primaryColor,
            padding: 12.0,
            context: context);
      }
    }
  }

  Future<void> _navigateToOrgRegistration() async {
    //mainSetup();
    var result = await Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: const OrgRegistrationPage()));

    if (result is ur.User) {
      pp(' 👌👌👌 Returned from sign in; will navigate to Dashboard :  👌👌👌 ${result.toJson()}');
      setState(() {
        user = result;
      });
      _navigateToDashboard();
    } else {
      pp(' 😡  😡  Returned from sign in is NOT a user :  😡 $result');
    }
  }
  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    killSubscription.cancel();
    super.dispose();
  }

  double currentIndexPage = 0.0;
  int pageIndex = 0;
  void _onPageChanged(int value) {
    if (mounted) {
      setState(() {
        currentIndexPage = value.toDouble();
      });
    }
  }
  void onSignIn() {
    pp('$mm onSignIn ...');
    _navigateToSignIn();
  }

  void onRegistration() {
    pp('$mm onRegistration ...');
    _navigateToOrgRegistration();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          'GeoMonitor',
          style: myTextStyleLarge(context),
        ),
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: const [
              IntroPage(
                title: 'GeoMonitor',
                assetPath: 'assets/intro/pic2.jpg',
                text: lorem,
              ),
              IntroPage(
                title: 'Organizations',
                assetPath: 'assets/intro/pic5.jpg',
                text: lorem,
              ),
              IntroPage(
                title: 'Administrators',
                assetPath: 'assets/intro/pic1.jpg',
                text: lorem,
              ),
              IntroPage(
                title: 'Field Monitors',
                assetPath: 'assets/intro/pic5.jpg',
                text: lorem,
              ),
              IntroPage(
                title: 'Executives',
                assetPath: 'assets/intro/pic3.webp',
                text: lorem,
              ),
              IntroPage(
                title: 'How To',
                assetPath: 'assets/intro/pic4.jpg',
                text: lorem,
              ),
              IntroPage(
                title: 'Thank You!',
                assetPath: 'assets/intro/thanks.webp',
                text: 'Thank you for even getting to this point. Your time and effort is much appreciated and we hope you enjoy your journeys with this app!',
              ),
            ],
          ),
          Positioned(
            bottom: 2,
            left: 48, right: 40,
            child: SizedBox(
              width: 200,
              height: 48,
              child: Card(
                color: Colors.black12,
                shape: getRoundedBorder(radius: 8),
                child: DotsIndicator(
                  dotsCount: 7,
                  position: currentIndexPage,
                  decorator: const DotsDecorator(
                    colors: [
                      Colors.grey,
                      Colors.grey,
                      Colors.grey,
                      Colors.grey,
                      Colors.grey,
                      Colors.grey,
                      Colors.grey,
                    ], // Inactive dot colors
                    activeColors: [
                      Colors.red,
                      Colors.blue,
                      Colors.teal,
                      Colors.indigo,
                      Colors.green,
                      Colors.pink,
                      Colors.deepOrangeAccent,
                    ], // Àctive dot colors
                  ),
                ),
              ),
            ),
          ),
          authed?  Positioned(
              right: 12,
              child: SizedBox(width: 48, height: 48,
          child: Card(
            shape: getRoundedBorder(radius: 48),
            child: IconButton(onPressed: (){
              //Navigator.of(context).pop();
              _navigateToDashboardWithoutUser();
            }, icon:  Icon(Icons.close, size: 18, color: Theme.of(context).primaryColor,)),
          ),)): Positioned(
            left: 16, right: 16,
            child: SizedBox(width: 300, height: 60, child: Card(
              elevation: 4, color: Colors.black12,
              shape: getRoundedBorder(radius: 16),
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(onPressed: onSignIn, child:  Text('Sign In', style: myTextStyleSmall(context),)),
                  const SizedBox(width: 48,),
                  TextButton(onPressed: onRegistration, child: Text('Register Organization', style: myTextStyleSmall(context),)),
                ],
              ),
            ),),
          )
        ],
      ),
    ));
  }
}
