import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dot;
import 'package:geo_monitor/library/hive_util.dart';

import '../api/data_api.dart';
import '../api/prefs_og.dart';
import '../data/country.dart';
import '../functions.dart';
import '../data/user.dart' as mon;

class AppAuth {
  static FirebaseAuth? _auth;

  static Future<String?> getAuthToken() async {
    _auth = FirebaseAuth.instance;
    String? token;
    if (_auth!.currentUser != null) {
      token = await _auth!.currentUser!.getIdToken();
    }
    if (token != null) {
      ('$locks getAuthToken has a 🌸🌸 GOOD 🌸🌸 Firebase id token 🍎');
    }
    return token;
  }

  static final firebaseAuth = FirebaseAuth.instance;

  static Future listenToFirebaseAuthentication() async {
    pp('$locks listen to Firebase Authentication events .....: 🍎');
    firebaseAuth.authStateChanges().listen((user) {
      pp('$locks firebaseAuth.authStateChanges: 🍎 $user');
    });
    firebaseAuth.idTokenChanges().listen((event) async {
      pp('$locks token changes from Firebase. will update the user ...');
      var token = await event?.getIdToken();
      await _checkUser(token);
    }).onError((err, stackTrace){

    });
    firebaseAuth.userChanges().listen((event) async {
      pp('$locks user changes from Firebase. will need to update the user, maybe ...');
      var token = await event?.getIdToken();
      await _checkUser(token);
    });
  }

  static Future<void> _checkUser(String? token) async {
    pp('$locks _checkUser token changes ...');
    if (token != null) {
      var user = await prefsOGx.getUser();
      if (user != null) {
        if (user.fcmRegistration != token) {
          pp('\n\n$locks token has changed; different from cached token.  🥬🥬🥬 will update the user ...');

          user.fcmRegistration = token;

          var pswd = user.password;
          user.password = null;
          await DataAPI.updateUser(user);
          user.password = pswd;

          await prefsOGx.saveUser(user);
          await cacheManager.addUser(user: user);

          pp('$locks token has changed; 🥬🥬🥬 have updated the user ...');

        } else {
          pp('$locks No token changes from Firebase. 🔵🔵🔵 '
              'No need to update the user ...');
        }
      }
    }
  }

  static const locks = '🔐🔐🔐🔐🔐🔐🔐🔐 AppAuth: ';

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
    await prefsOGx.saveUser(user);
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


    } else {
      pp('👿👿 Countries not found');
    }
    return user;
  }

  static Future getCountry() async {}

}
