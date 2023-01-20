// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dot;
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geo_monitor/library/generic_functions.dart';
import 'package:geo_monitor/library/ui/camera/photo_handler.dart';

import 'package:geo_monitor/ui/dashboard/dashboard_main.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'firebase_options.dart';
import 'library/api/sharedprefs.dart';
import 'library/data/user.dart' as ur;
import 'library/bloc/theme_bloc.dart';
import 'library/bloc/upload_failed_media.dart';
import 'library/bloc/write_failed_media.dart';
import 'library/emojis.dart';
import 'library/functions.dart';
import 'library/hive_util.dart';
import 'ui/intro_page_viewer.dart';

int themeIndex = 0;
late FirebaseApp firebaseApp;
fb.User? user;

Future<void> mainSetup() async {
  try {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (kReleaseMode) exit(1);
    };
    themeIndex = await Prefs.getThemeIndex();
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    pp('${Emoji.heartGreen}${Emoji.heartGreen} FirebaseCrashlytics set up');
    // Prefs.deleteUser();
    await Hive.initFlutter();
    await hiveUtil.initialize(forceInitialization: false);
    pp('${Emoji.heartGreen}${Emoji.heartGreen}}${Emoji.heartGreen} '
        'Hive initialized and boxCollection set up');

    writeFailedMedia.startTimer(const Duration(minutes: 10));
    uploadFailedMedia.startTimer(const Duration(minutes: 15));
    writeFailedMedia.writeFailedPhotos();
    writeFailedMedia.writeFailedVideos();
    pp('${Emoji.heartGreen}${Emoji.heartGreen} writeFailedMedia/uploadFailedMedia '
        'timers started with 🍎 5 minute duration per tick ...');

    await FlutterLibphonenumber().init();
  } catch (e) {
    pp('$redDot problem with Firebase? or Hive? : $e');
  }

  await dotenv.load(fileName: ".env");
  pp('$heartBlue DotEnv has been loaded');

  pp('${Emoji.brocolli} Checking for current user : FirebaseAuth');

  if (user == null) {
    pp('${Emoji.redDot}${Emoji.redDot} Ding Dong! new Firebase user, sign in! - check that we do not create user every time $appleGreen  $appleGreen');
  } else {
    pp('${Emoji.blueDot}${Emoji.blueDot}${Emoji.blueDot}${Emoji.blueDot} User already exists. $blueDot Cool!');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  firebaseApp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  pp('${Emoji.heartGreen}${Emoji.heartGreen} Firebase App has been initialized: ${firebaseApp.name}');

  user = fb.FirebaseAuth.instance.currentUser;
  if (user == null) {
    pp('${Emoji.heartGreen}${Emoji.heartGreen} Ding Dong! Rookie here ...');
  } else {
    pp('${Emoji.redDot}${Emoji.redDot} User already here ...');
  }
  await mainSetup();

  runApp(const MyApp());
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
        pp('🌀🌀🌀🌀 Tap detected; should dismiss keyboard');
        FocusManager.instance.primaryFocus?.unfocus();
      },
      onDoubleTap: () async {
        //todo - REMOVE after testing
        await _sortOutNewHiveArtifacts(context);
      },
      // onLongPress: () {
      //   pp('🌀🌀🌀🌀 Long press detected; throwing fake exception');
      //   throw Exception('Fake Exception to test Crashlytics');
      // },
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
            // home: const PhotoHandler(),
            // home: const OrgRegistrationPage(),
            // home: const IntroMain(),
            // home: user == null? const IntroPageViewer() :const DashboardMain(),
            // home: const PhoneLogin(),
            home: AnimatedSplashScreen(
              duration: 3000,
              splash: const SplashWidget(),
              animationDuration: const Duration(milliseconds: 3000),
              curve: Curves.easeInCirc,
              splashIconSize: 160.0,
              nextScreen: user == null
                  ? const IntroPageViewer()
                  : const DashboardMain(),
              splashTransition: SplashTransition.fadeTransition,
              pageTransitionType: PageTransitionType.topToBottom,
              backgroundColor: Colors.teal.shade900,
            ),
          );
        },
      ),
    );
  }

  Future<void> _sortOutNewHiveArtifacts(BuildContext context) async {
    //todo - REMOVE after testing
    String? status = dot.dotenv.env['CURRENT_STATUS'];
    pp('🐤🐤🐤🐤 DataAPI: getUrl: Status from .env: $status');
    bool? isDevelopmentStatus;
    if (status == 'dev') {
      isDevelopmentStatus = true;
      pp('🌀🌀🌀🌀 Double Tap detected; should sign out of Firebase when status is DEV');
      fb.FirebaseAuth.instance.signOut();
      pp('🌀🌀🌀🌀  🍎 Signed out of Firebase!!! 🍎 ');
      fileCounter = await Prefs.getFileCounter();
      fileCounter++;
      Prefs.setFileCounter(fileCounter);
      Prefs.deleteUser();
      await hiveUtil.initialize(forceInitialization: true);
    } else {
      isDevelopmentStatus = false;
      pp('🐤🐤🐤🐤 of the app is PRODUCTION 🌎 🌎 🌎 ');
      return;
    }
    pp('\n🐤🐤🐤🐤 isDevelopmentStatus: $isDevelopmentStatus');
    pp('🐤🐤🐤🐤 We good and clean now, Senor!');
  }
}

class SplashWidget extends StatelessWidget {
  const SplashWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: AnimatedContainer(
        // width: 300, height: 300,
        curve: Curves.easeInOutCirc,
        // color: Colors.pink,
        duration: const Duration(milliseconds: 2000),
        child: Card(
          elevation: 24.0,
          shape: getRoundedBorder(radius: 16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'GeoMonitor',
                        style: myNumberStyleLarger(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4,),
               Row(mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const FaIcon(FontAwesomeIcons.anchorCircleCheck),
                   const SizedBox(width: 24,),
                   Text('We help you see!', style: myTextStyleMedium(context),),
                   const SizedBox(width: 24,),
                   const Text('🔷🔷'),
                 ],
               ),
              const SizedBox(height: 20,),
            ],
          ),
        ),
      ),
    );
  }
}
