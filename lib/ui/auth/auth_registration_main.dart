import 'package:flutter/material.dart';
import 'package:geo_monitor/ui/auth/auth_email_registration_tablet_portrait.dart';
import 'package:geo_monitor/ui/auth/auth_phone_registration_mobile.dart';
import 'package:geo_monitor/ui/auth/auth_phone_signin_mobile.dart';
import 'package:geo_monitor/ui/auth/auth_email_signin_tablet_portrait.dart';
import 'package:responsive_builder/responsive_builder.dart';

import 'auth_email_registration_tablet_landscape.dart';

class AuthRegistrationMain extends StatelessWidget {
  const AuthRegistrationMain({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: const AuthPhoneRegistrationMobile(),
      tablet: OrientationLayoutBuilder(
        portrait: (context) {
          return const AuthEmailRegistrationPortrait(amInsideLandscape: false,);
        },
        landscape: (context){
          return const AuthEmailRegistrationLandscape();
        },
      ),
    );
  }
}
