import 'package:flutter/material.dart';
import 'package:geo_monitor/ui/auth/auth_phone_signin_mobile.dart';
import 'package:geo_monitor/ui/auth/auth_email_signin_tablet_portrait.dart';
import 'package:responsive_builder/responsive_builder.dart';

class AuthSignInMain extends StatelessWidget {
  const AuthSignInMain({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: const AuthPhoneSignInMobile(),
      tablet: OrientationLayoutBuilder(
        portrait: (context) {
          return const AuthEmailSignInTabletPortrait(showHeader: true,);
        },
        landscape: (context){
          return const AuthEmailLinkSignInTabletLandscape();
        },
      ),
    );
  }
}
