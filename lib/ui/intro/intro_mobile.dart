
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geo_monitor/library/users/org_registration.dart';
import 'package:geo_monitor/library/users/phone_login.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:introduction_screen/introduction_screen.dart';

import 'package:page_transition/page_transition.dart';

import '../../library/api/sharedprefs.dart';
import '../../library/data/user.dart' as ur;
import '../../library/functions.dart';
import '../../library/ui/signin.dart';
import '../dashboard/dashboard_main.dart';

class IntroMobile extends StatefulWidget {

  const IntroMobile({Key? key, }) : super(key: key);
  @override
  IntroMobileState createState() => IntroMobileState();
}

class IntroMobileState extends State<IntroMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  ur.User? user;
  var lorem =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ac sagittis lectus. Aliquam dictum elementum massa, '
      'eget mollis elit rhoncus ut.';
  bool authed = false;
  fb.FirebaseAuth firebaseAuth = fb.FirebaseAuth.instance;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getAuthenticationStatus();

  }
  void _getAuthenticationStatus() async {
      var cUser = firebaseAuth.currentUser;
      if (cUser != null) {
        setState(() {
          authed = true;
        });
      }

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        key: _key,
        appBar: AppBar(
          leading: user == null? IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () {
            Navigator.pop(context);
          },) : Container(),
          title: Text(
            'The Digital Monitor',
            style: GoogleFonts.lato(
              textStyle: Theme.of(context).textTheme.bodyMedium,
              fontWeight: FontWeight.w900,),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Column(
              children: [
                // user == null
                     authed? const SizedBox(): Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const SizedBox(
                            width: 12,
                          ),
                          TextButton(
                            onPressed: _navigateToSignIn,
                            child:
                                Text('Sign In', style: myTextStyleSmall(context),),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          TextButton(
                            onPressed: _navigateToOrgRegistration,
                            child:
                            Text('Register Organization', style: myTextStyleSmall(context),),
                          ),
                          const SizedBox(
                            width: 24,
                          ),
                        ],
                      ),
                const SizedBox(
                  height: 24,
                )
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            IntroductionScreen(
              pages: [
                PageViewModel(
                  titleWidget: Text(
                    "Welcome to The Digital Monitor",
                    style: GoogleFonts.lato(
                      textStyle: Theme.of(context).textTheme.bodyLarge,
                      fontWeight: FontWeight.w900,),
                  ),
                  bodyWidget: Text(
                    lorem,
                    style: GoogleFonts.lato(
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                      fontWeight: FontWeight.normal,),
                  ),
                  image: Image.asset(
                    "assets/intro/img4.jpeg",
                    fit: BoxFit.cover, width: 500, height: 600,
                  ),
                ),
                PageViewModel(
                  titleWidget: Text(
                    "Field Monitors are people too",
                    style: GoogleFonts.lato(
                      textStyle: Theme.of(context).textTheme.bodyLarge,
                      fontWeight: FontWeight.w900,),
                  ),
                  bodyWidget: Text(
                    lorem,
                    style: GoogleFonts.lato(
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                      fontWeight: FontWeight.normal,),
                  ),
                  image: Image.asset("assets/intro/img5.jpeg", fit: BoxFit.cover,width: 500, height: 600,),
                ),
                PageViewModel(
                  titleWidget: Text(
                    "Start using The Digital Monitor",
                    style: GoogleFonts.lato(
                      textStyle: Theme.of(context).textTheme.bodyLarge,
                      fontWeight: FontWeight.w900,),
                  ),
                  bodyWidget: Text(
                    lorem,
                    style: GoogleFonts.lato(
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                      fontWeight: FontWeight.normal,),
                  ),
                  image: Image.asset("assets/intro/img6.jpeg", fit: BoxFit.cover, width: 500, height: 600,),
                ),
              ],
              onDone: () {
                _navigateToDashboard();
              },
              showSkipButton: false,
              skip: const Icon(Icons.skip_next),
              next: const Icon(Icons.arrow_forward),
              done: user == null
                  ? Container()
                  : Text("Done",
                      style: GoogleFonts.lato(
                        textStyle: Theme.of(context).textTheme.bodyMedium,
                        fontWeight: FontWeight.w900,),
              ),
              dotsDecorator: DotsDecorator(
                size: const Size.square(10.0),
                activeSize: const Size(20.0, 10.0),
                activeColor: Theme.of(context).primaryColor,
                spacing: const EdgeInsets.symmetric(horizontal: 3.0),
                activeShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDashboard() {
    if (user != null) {
      Navigator.pop(context);
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(seconds: 1),
              child: const DashboardMain()));
    } else {
      pp('User is null,  🔆 🔆 🔆 🔆 cannot navigate to Dashboard');
    }
  }

  Future<void> _navigateToSignIn() async {
    var result = await Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: const PhoneLogin()));

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

  Future<void> _navigateToOrgRegistration() async {
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

  final _key = GlobalKey<ScaffoldState>();

}
