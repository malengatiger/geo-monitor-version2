import 'dart:async';

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
import '../dashboard/dashboard_portrait.dart';
import 'intro_page_one_landscape.dart';

class IntroPageViewerLandscape extends StatefulWidget {
  const IntroPageViewerLandscape({Key? key}) : super(key: key);

  @override
  State<IntroPageViewerLandscape> createState() =>
      _IntroPageViewerLandscapeState();
}

class _IntroPageViewerLandscapeState extends State<IntroPageViewerLandscape>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  fb.FirebaseAuth firebaseAuth = fb.FirebaseAuth.instance;
  ur.User? user;
  bool authed = false;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this);
    super.initState();
    _getAuthenticationStatus();
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
    pp('$mm _getAuthenticationStatus ....... setting state ');
    setState(() {});
  }

  Future<void> _navigateToDashboard() async {
    user = await prefsOGx.getUser();
    if (user != null) {
      if (mounted) {
        Navigator.push(
            context,
            PageTransition(
                type: PageTransitionType.scale,
                alignment: Alignment.topLeft,
                duration: const Duration(milliseconds: 2000),
                child: const DashboardMain()));
      } else {
        pp('$mm User is null,  🔆 🔆 🔆 🔆 cannot navigate to Dashboard');
      }
    }
  }

  Future<void> _navigateToSignIn() async {
    pp('$mm _navigateToSignIn ....... ');
    var result = await Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: const AuthSignInMain()));

    if (result is ur.User) {
      pp('\n\n\n$mm _navigateToSignIn ....... back from AuthSignInMain with a user '
          '... 🔵🔵🔵🔵 ${result.toJson()} ');
    }
    user = await prefsOGx.getUser();
    pp('\n\n$mm 😡😡 Returned from sign in, checking if login succeeded bu getting user from cache 😡');

    if (user != null) {
      pp('$mm _navigateToSignIn: 👌👌👌 Returned from sign in; '
          'will navigate to Dashboard : 👌👌👌 ${user!.toJson()}');
      setState(() {});
      _navigateToDashboard();
    } else {
      pp('$mm 😡😡 Returned from sign in; cached user not found. '
          '${E.redDot}${E.redDot} NOT GOOD! ${E.redDot}');
      if (mounted) {
        showToast(
            message: 'Email Sign In Failed',
            duration: const Duration(seconds: 5),
            backgroundColor: Theme.of(context).primaryColor,
            padding: 12.0,
            context: context);
      }
    }
  }

  Future<void> _navigateToOrgRegistration() async {
    var result = await Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: const AuthRegistrationMain()));

    if (result is ur.User) {
      pp('$mm _navigateToOrgRegistration: 👌👌👌 Returned from Registration; will navigate to Dashboard :  👌👌👌 ${result.toJson()}');
      setState(() {
        user = result;
      });
      _navigateToDashboard();
    } else {
      pp('$mm _navigateToOrgRegistration: 😡😡  Returned from Registration; we do not have a user :  😡 $result');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Geo'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: authed
              ? Row(
                  children: [
                    IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close)),
                  ],
                )
              : Card(
                  elevation: 4,
                  color: Colors.black38,
                  shape: getRoundedBorder(radius: 16),
                  child: authed
                      ? const SizedBox()
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                                onPressed: _navigateToSignIn,
                                child: const Text('Sign In')),
                            const SizedBox(
                              width: 120,
                            ),
                            TextButton(
                                onPressed: _navigateToOrgRegistration,
                                child: const Text('Register Organization')),
                          ],
                        ),
                ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            scrollDirection: Axis.horizontal,
            // itemExtent: ,
            children: const [
              IntroPageLandscape(
                title: 'GeoMonitor',
                assetPath: 'assets/intro/pic2.jpg',
                text: lorem,
                width: 420,
              ),
              IntroPageLandscape(
                title: 'Organizations',
                assetPath: 'assets/intro/pic5.jpg',
                text: lorem,
                width: 420,
              ),
              IntroPageLandscape(
                title: 'Administrators',
                assetPath: 'assets/intro/pic1.jpg',
                text: lorem,
                width: 420,
              ),
              IntroPageLandscape(
                title: 'Field Monitors',
                assetPath: 'assets/intro/pic5.jpg',
                text: lorem,
                width: 420,
              ),
              IntroPageLandscape(
                title: 'Executives',
                assetPath: 'assets/intro/pic3.webp',
                text: lorem,
                width: 420,
              ),
              IntroPageLandscape(
                title: 'How To',
                assetPath: 'assets/intro/pic4.jpg',
                text: lorem,
                width: 420,
              ),
              IntroPageLandscape(
                title: 'Thank You!',
                assetPath: 'assets/intro/thanks.webp',
                width: 420,
                text:
                    'Thank you for even getting to this point. Your time and effort is much appreciated and we hope you enjoy your journeys with this app!',
              ),
            ],
          )
        ],
      ),
    ));
  }
}
