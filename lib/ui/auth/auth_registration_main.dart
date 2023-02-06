import 'package:flutter/material.dart';
import 'package:geo_monitor/ui/auth/auth_email_link_registration_tablet.dart';
import 'package:geo_monitor/ui/auth/auth_phone_registration_mobile.dart';
import 'package:geo_monitor/ui/auth/auth_phone_signin_mobile.dart';
import 'package:geo_monitor/ui/auth/auth_email_link_tablet.dart';
import 'package:responsive_builder/responsive_builder.dart';

class AuthRegistrationMain extends StatelessWidget {
  const AuthRegistrationMain({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: const AuthPhoneRegistrationMobile(),
      tablet: OrientationLayoutBuilder(
        portrait: (context) {
          return const AuthEmailRegistrationPortrait();
        },
        landscape: (context){
          return const AuthEmailRegistrationLandscape();
        },
      ),
    );
  }
}
