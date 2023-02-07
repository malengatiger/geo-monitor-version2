import 'package:flutter/material.dart';

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/data/country.dart';
import 'package:geo_monitor/library/data/organization.dart';
import 'package:geo_monitor/library/data/organization_registration_bag.dart';
import 'package:geo_monitor/library/data/settings_model.dart';
import 'package:geo_monitor/library/hive_util.dart';
import 'package:geo_monitor/library/location/loc_bloc.dart';
import 'package:geo_monitor/library/users/edit/user_edit_main.dart';
import 'package:geo_monitor/ui/intro/intro_page_one_landscape.dart';
import 'package:geo_monitor/ui/intro/intro_page_viewer_portrait.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:uuid/uuid.dart';

import '../../library/api/data_api.dart';
import '../../library/data/user.dart' as ur;
import '../../library/functions.dart';
import '../../library/generic_functions.dart';
import 'auth_email_registration_tablet_portrait.dart';

////
class AuthEmailRegistrationLandscape extends StatefulWidget {
  const AuthEmailRegistrationLandscape({Key? key}) : super(key: key);

  @override
  State<AuthEmailRegistrationLandscape> createState() =>
      _AuthEmailRegistrationLandscapeState();
}

class _AuthEmailRegistrationLandscapeState
    extends State<AuthEmailRegistrationLandscape> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Geo Organization Registration'),
      ),
      body: Stack(
        children: [
          Row(
            children:  [
              const AuthEmailRegistrationPortrait(),
              const SizedBox(
                width: 0,
              ),
              Card(
                shape: getRoundedBorder(radius: 16),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28.0),
                  child: IntroPageLandscape(
                    title: 'GeoMonitor',
                    assetPath: 'assets/intro/pic2.jpg',
                    text: lorem,
                    width: 400,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    ));
  }
}
