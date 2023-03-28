import 'package:flutter/material.dart';
import 'package:geo_monitor/ui/auth/auth_phone_signin.dart';
import 'package:geo_monitor/ui/auth/auth_tablet_signin.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../library/data/user.dart';
import 'auth_email_signin.dart';

class AuthSignIn extends StatelessWidget {
  const AuthSignIn({Key? key}) : super(key: key);

  void _onSignedIn(User user) async {

  }
  void _onError(String message) async {

  }
  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: AuthPhoneSignIn(
        onSignedIn: (user) {},
        onError: (String) {},
      ),
      tablet: const AuthTabletSignIn(),
    );
  }
}
