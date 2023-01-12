import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dot;

import '../api/data_api.dart';
import '../api/sharedprefs.dart';
import '../data/country.dart';
import '../functions.dart';
import '../data/city.dart';
import '../data/community.dart';
import '../data/condition.dart';
import '../data/field_monitor_schedule.dart';
import '../data/monitor_report.dart';
import '../data/org_message.dart';
import '../data/organization.dart';
import '../data/photo.dart';
import '../data/project.dart';
import '../data/project_position.dart';
import '../data/section.dart';
import '../data/user.dart' as mon;
import '../data/video.dart';

class AppAuth {
  static FirebaseAuth? _auth;

  static Future isUserSignedIn() async {
    pp('🥦 🥦  😎😎😎😎 AppAuth: isUserSignedIn :: 😎😎😎 about to initialize Firebase; 😎');
    var app = await Firebase.initializeApp();
    pp('😎😎😎😎 AppAuth: isUserSignedIn :: 😎😎😎 Firebase has been initialized; '
        '😎 or not? 🍀🍀 app: ${app.options.databaseURL}');

    var user = await Prefs.getUser();
    if (user == null) {
      pp('🦠🦠🦠 user is NOT signed in. 🦠 ');
      return null;
    } else {
      pp('🦠🦠🦠 user is signed in. 🦠 .... ${user.toJson()}');
      return user;
    }
  }

  static Future<mon.User> createUser(
      {required mon.User user,
      required String password,
      required bool isLocalAdmin}) async {
    pp('AppAuth: 💜 💜 createUser: auth record to be created ... ${user.toJson()}');

    UserCredential? fbUser = await _auth!
        .createUserWithEmailAndPassword(email: user.email!, password: password)
        .catchError((e) {
      pp('👿👿👿 User create failed : $e');
      throw e;
    });

    mon.User? mUser;

    user.userId = fbUser.user!.uid;
    var fcm = await fbUser.user!.getIdToken();
    user.fcmRegistration = fcm;
    mUser = await DataAPI.addUser(user);
    pp('AppAuth: 💜 💜 createUser: added to database ... 💛️ 💛️ ${mUser.toJson()}');

    String? url;
    var status = dot.dotenv.env['status'];
    if (status == 'dev') {
      url = dot.dotenv.env['devURL'];
    } else {
      url = dot.dotenv.env['prodURL'];
    }
    if (url != null) {
      var suffix = '/verify?userId=${user.userId}';
      var finalUrl = 'https://fieldmonitor3.page.link/fieldmonitor$suffix';
      pp('AppAuth: 💜 💜 createUser: link for user: $finalUrl ');
      await _auth!.sendSignInLinkToEmail(
          email: user.email!,
          actionCodeSettings: ActionCodeSettings(
              androidPackageName: 'com.boha.fieldmonitorb',
              url: finalUrl,
              androidInstallApp: true,
              handleCodeInApp: true));
      pp('AppAuth: 💜 💜 createUser: auth!.sendSignInLinkToEmail has executed ... email link should be sent ??? ');
    }

    if (isLocalAdmin) {
      pp('AppAuth: 💜 💜 createUser: saving user to local cache: '
          '💛️ 💛️ isLocalAdmin: $isLocalAdmin 💛️ 💛️');
      await Prefs.saveUser(mUser);
      var countries = await DataAPI.getCountries();
      if (countries.isNotEmpty) {
        await Prefs.saveCountry(countries.elementAt(0));
      }
    } else {
      pp('AppAuth: 💜 💜 createUser:  '
          '💛️ 💛️ isLocalAdmin: $isLocalAdmin 💛️ 💛️ normal user (non-original user)');
    }

    pp('AppAuth:  💜 💜 💜 💜 createUser, after adding to Mongo database ....... ${mUser.toJson()}');

    return mUser;
  }

  static Future<String?> getAuthToken() async {
    _auth = FirebaseAuth.instance;
    var token = await _auth!.currentUser!.getIdToken();
    // pp('🌸🌸 Current user Firebase token: $token ');
    return token;
  }

  static const locks = '🔐🔐🔐🔐';
  static Future<mon.User?> signIn({required String email, required String password}) async {
    pp('$locks Auth: signing in $email 🌸 $password  $locks');
    //var token = await _getAdminAuthenticationToken();
    _auth = FirebaseAuth.instance;
    var fbUser = await _auth!
        .signInWithEmailAndPassword(email: email, password: password)
        .whenComplete(() => () {
              pp('$locks signInWithEmailAndPassword.whenComplete ..... $locks');
            })
        .catchError((e) {
      pp('👿👿👿 Firebase sign in failed, 👿 message: $e');
      pp(e);
      throw e;
    });
    pp('$locks Firebase auth user to be checked ......... ');

    pp('$locks Auth finding user by email $email $locks ${fbUser.user!.email} -  ${fbUser.user!.displayName} ');
    var user = await DataAPI.findUserByEmail(fbUser.user!.email!);
    if (user == null) {
      pp('👎🏽 👎🏽 👎🏽 User not registered yet 👿');
      throw Exception("User not found on Firebase auth 👿 👿 👿 ");
    } else {
      pp('$locks User found on database. Yeah! 🐤 🐤 🐤 ${user.toJson()}');
    }
    pp('$locks about to cache the user on the device ...');
    await Prefs.saveUser(user);
    var countries = await DataAPI.getCountries();

    if (countries.isNotEmpty) {
      pp("🥏 🥏 🥏 First country found in list: ${countries.elementAt(0).name}");
      Country? c;
      for (var country in countries) {
        if (country.countryId == user.countryId) {
          c = country;
          break;
        }
      }

      if (c != null) {
        await Prefs.saveCountry(c);
      }
    } else {
      pp('👿👿 Countries not found');
    }
    return user;
  }

  static Future getCountry() async {}

  static Future _getAdminAuthenticationToken() async {
    var email = dot.dotenv.env['email'];
    var password = dot.dotenv.env['password'];
    _auth = FirebaseAuth.instance;

    var res = await _auth!
        .signInWithEmailAndPassword(email: email!, password: password!);
    if (res.user != null) {
      return await res.user!.getIdToken();
    } else {
      return null;
    }
  }
}
