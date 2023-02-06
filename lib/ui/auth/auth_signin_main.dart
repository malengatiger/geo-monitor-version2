import 'package:flutter/material.dart';
import 'package:geo_monitor/ui/auth/auth_phone_signin_mobile.dart';
import 'package:geo_monitor/ui/auth/auth_email_link_tablet.dart';
import 'package:responsive_builder/responsive_builder.dart';

class AuthSignInMain extends StatelessWidget {
  const AuthSignInMain({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: const AuthPhoneSignInMobile(),
      tablet: OrientationLayoutBuilder(
        portrait: (context) {
          return const AuthEmailLinkSignInTabletPortrait();
        },
        landscape: (context){
          return const AuthEmailLinkSignInTabletLandscape();
        },
      ),
    );
  }
}
