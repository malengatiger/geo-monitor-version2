import 'dart:async';

import 'package:dots_indicator/dots_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:geo_monitor/ui/auth/auth_registration_main.dart';
import 'package:geo_monitor/ui/auth/auth_signin_main.dart';
import 'package:geo_monitor/ui/dashboard/dashboard_main.dart';
import 'package:page_transition/page_transition.dart';

import '../../library/api/prefs_og.dart';
import '../../library/cache_manager.dart';
import '../../library/data/user.dart' as ur;
import '../../library/emojis.dart';
import '../../library/functions.dart';
import '../../library/generic_functions.dart';
import '../dashboard/dashboard_mobile.dart';
import '../intro/intro_page_one.dart';

class IntroPageViewerPortrait extends StatefulWidget {
  const IntroPageViewerPortrait({
    Key? key,
  }) : super(key: key);

  @override
  IntroPageViewerPortraitState createState() => IntroPageViewerPortraitState();
}

class IntroPageViewerPortraitState extends State<IntroPageViewerPortrait>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final PageController _pageController = PageController();
  bool authed = false;
  fb.FirebaseAuth firebaseAuth = fb.FirebaseAuth.instance;
  ur.User? user;
  late StreamSubscription<String> killSubscription;

  final mm =
      '${E.pear}${E.pear}${E.pear}${E.pear} IntroPageViewerPortrait: ${E.pear} ';

  @override
  void initState() {
    _animationController = AnimationController(vsync: this);
    super.initState();
    _getAuthenticationStatus();
    killSubscription = listenForKill(context: context);
  }

  void _getAuthenticationStatus() async {
    pp('\n\n$mm _getAuthenticationStatus ....... '
        'check both Firebase user ang Geo user');
    var user = await prefsOGx.getUser();
    var firebaseUser = firebaseAuth.currentUser;

    if (user != null && firebaseUser != null) {
      pp('$mm _getAuthenticationStatus .......  '
          '🥬🥬🥬auth is DEFINITELY authenticated and OK');
      authed = true;
    } else {
      pp('$mm _getAuthenticationStatus ....... NOT AUTHENTICATED! '
          '${E.redDot}${E.redDot}${E.redDot} ... will clean house!!');
      authed = false;
      //todo - ensure that the right thing gets done!
      prefsOGx.deleteUser();
      firebaseAuth.signOut();
      cacheManager.initialize(forceInitialization: true);
      pp('$mm _getAuthenticationStatus .......  '
          '${E.redDot}${E.redDot}${E.redDot}'
          'the device should be ready for sign in or registration');
    }
    pp('$mm ......... _getAuthenticationStatus ....... setting state, authed = $authed ');
    setState(() {});
  }

  void _navigateToDashboard() {
    if (user != null) {
      //Navigator.of(context).pop(user);
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(seconds: 2),
              child: const DashboardMain()));
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
            child: const DashboardPortrait()));
  }

  Future<void> _navigateToSignIn() async {
    pp('$mm _navigateToSignIn ....... ');

    await Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: const AuthSignInMain()));

    pp('$mm _navigateToSignIn ....... back from PhoneLogin with maybe a user ..');
    user = await prefsOGx.getUser();
    pp('\n\n$mm 😡😡Returned from sign in, checking if login succeeded 😡');

    if (user != null) {
      pp('$mm _navigateToSignIn: 👌👌👌 Returned from sign in; '
          'will navigate to Dashboard :  👌👌👌 ${user!.toJson()}');
      setState(() {});
      _navigateToDashboard();
    } else {
      pp('$mm 😡😡 Returned from sign in; cached user not found. '
          '${E.redDot}${E.redDot} NOT GOOD! ${E.redDot}');
      if (mounted) {
        showToast(
            message: 'Phone Sign In Failed',
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
            child: const AuthRegistrationMain()));

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
          'Geo Information',
          style: myTextStyleLarge(context),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(authed ? 4 : 48),
          child: authed
              ? const SizedBox()
              : Card(
                  elevation: 4,
                  color: Colors.black26,
                  // shape: getRoundedBorder(radius: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                          onPressed: onSignIn, child: const Text('Sign In')),
                      TextButton(
                          onPressed: onRegistration,
                          child: const Text('Register Organization')),
                    ],
                  ),
                ),
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
                text:
                    'Thank you for even getting to this point. Your time and effort is much appreciated and we hope you enjoy your journeys with this app!',
              ),
            ],
          ),
          Positioned(
            bottom: 2,
            left: 48,
            right: 40,
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
        ],
      ),
    ));
  }
}
