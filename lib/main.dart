// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'library/api/sharedprefs.dart';
import 'library/bloc/theme_bloc.dart';
import 'library/bloc/write_failed_media.dart';
import 'library/emojis.dart';
import 'library/functions.dart';
import 'library/generic_functions.dart';
import 'library/hive_util.dart';
import 'ui/intro/intro_main.dart';

int themeIndex = 0;
late FirebaseApp firebaseApp;

void main() async {
  await _setup();
 runApp(const MyApp());
}

Future<void> _setup() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode) exit(1);
  };

  themeIndex = await Prefs.getThemeIndex();
  try {
    firebaseApp = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    p('${Emoji.heartGreen}${Emoji.heartGreen} Firebase App has been initialized: ${firebaseApp.name}');

    // Prefs.deleteUser();
    await Hive.initFlutter();
    hiveUtil.initialize();
    p('${Emoji.heartGreen}${Emoji.heartGreen} Hive initialized');

    writeFailedMedia.startTimer();
    p('${Emoji.heartGreen}${Emoji.heartGreen} writeFailedMedia timer started ...');

  } catch (e) {
    p('$redDot problem with Firebase? or Hive? : $e');
  }

  await dotenv.load(fileName: ".env");
  p('$heartBlue DotEnv has been loaded');

  // setup();
  p('${Emoji.brocolli} Checking for current user : FirebaseAuth');
  var user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    p('${Emoji.redDot}${Emoji.redDot} Ding Dong! new Firebase user, sign in! - check that we dont create user every time $appleGreen  $appleGreen');
    //await DataService.signInAnonymously();
  } else {
    p('${Emoji.blueDot}${Emoji.blueDot} User already exists. $blueDot Cool!');
    try {
      // FirebaseAuth.instance.signOut();
      var token = await user.getIdToken();
      pp(token);
    } catch (e) {
      pp('${Emoji.redDot}Problem with Firebase Auth: $e 🎽 🎽 🎽');
      pp(e);
    }

  }
}

/// The main app.
class MyApp extends StatelessWidget {
  /// Constructs a [MyApp]
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    themeBloc.start();
    return GestureDetector(
      onTap: () {

      },
      child: StreamBuilder(
        stream: themeBloc.newThemeStream,
        initialData: themeIndex,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              themeIndex = snapshot.data;
            }
          return MaterialApp(
            // routerConfig: _router,
            debugShowCheckedModeBanner: false,
            title: 'GeoMonitor',
            theme: themeBloc.getTheme(themeIndex).darkTheme,
            darkTheme: themeBloc.getTheme(themeIndex).darkTheme,
            themeMode: ThemeMode.system,
            home: const IntroMain(),
          );
        },
      ),
    );
  }
}
