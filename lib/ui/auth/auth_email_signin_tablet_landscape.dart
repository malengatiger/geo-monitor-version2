import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geo_monitor/library/api/data_api.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';
import 'package:geo_monitor/library/functions.dart';
import 'package:geo_monitor/ui/intro/intro_page_one.dart';

import '../../library/generic_functions.dart';
import 'auth_email_signin_tablet_portrait.dart';


class AuthEmailLinkSignInTabletLandscape extends StatelessWidget {
  const AuthEmailLinkSignInTabletLandscape({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Geo Email Sign In',
          style: myTextStyleLarge(context),
        ),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(
            width: 500,
            child: AuthEmailSignInTabletPortrait(showHeader: false, externalPadding: 24, internalPadding: 24,),
          ),
          SizedBox(
            width: 500,
            child: IntroPage(assetPath: 'assets/intro/pic3.webp', title: 'Geo Monitor', text: lorem),
          ),
        ],
      ),
    ));
  }
}
