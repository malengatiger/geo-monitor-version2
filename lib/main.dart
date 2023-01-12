// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'library/api/sharedprefs.dart';
import 'library/bloc/theme_bloc.dart';
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

    hiveUtil.initialize();
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

/// The route configuration.
final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) => const IntroMain(),
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const IntroMain(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      routes: <RouteBase>[
        GoRoute(
          path: 'details',
          builder: (BuildContext context, GoRouterState state) {
            return const DetailsScreen();
          },
        ),
      ],
    ),
  ],
);

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

/// The home screen
class HomeScreen extends StatelessWidget {
  /// Constructs a [HomeScreen]
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => context.go('/details'),
              child: const Text('Go to the Details screen'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The details screen
class DetailsScreen extends StatelessWidget {
  /// Constructs a [DetailsScreen]
  const DetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <ElevatedButton>[
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go back to the Home screen'),
            ),
          ],
        ),
      ),
    );
  }
}