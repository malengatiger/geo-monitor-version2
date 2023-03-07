import 'dart:async';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_monitor/library/auth/app_auth.dart';
import 'package:geo_monitor/library/functions.dart';
import 'package:geo_monitor/splash/splash_page.dart';
import 'package:geo_monitor/ui/dashboard/dashboard_main.dart';
import 'package:geo_monitor/ui/intro/intro_main.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_platform/universal_platform.dart';

import 'firebase_options.dart';
import 'library/api/prefs_og.dart';
import 'library/bloc/fcm_bloc.dart';
import 'library/bloc/geo_uploader.dart';
import 'library/bloc/organization_data_refresh.dart';
import 'library/bloc/theme_bloc.dart';
import 'library/cache_manager.dart';
import 'library/emojis.dart';
import 'library/geofence/geofencer_two.dart';
import 'library/ui/camera/video_handler_two.dart';

int themeIndex = 0;
late FirebaseApp firebaseApp;
fb.User? fbAuthedUser;
final mx =
    '${E.heartGreen}${E.heartGreen}${E.heartGreen}${E.heartGreen} main: ';
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  firebaseApp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  pp('$mx main: '
      ' Firebase App has been initialized: ${firebaseApp.name}, checking for authed current user');
  fbAuthedUser = fb.FirebaseAuth.instance.currentUser;
  await GetStorage.init(cacheName);

  /// check user auth status
  if (fbAuthedUser == null) {
    pp('$mx main: fbAuthedUser is NULL ${E.redDot}${E.redDot}${E.redDot} no user signed in.');
  } else {
    pp('$mx main: fbAuthedUser is OK! check whether user exists, '
        'auth could be from old instance of app${E.leaf}${E.leaf}${E.leaf}');
    var user = await prefsOGx.getUser();
    if (user == null) {
      pp('$mx main: 🔴🔴🔴 user is null; cleanup necessary! '
          '🔴fbAuthedUser will be set to null');
      await fb.FirebaseAuth.instance.signOut();
      fbAuthedUser = null;
    }
    cameras = await availableCameras();
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const GeoApp());

}

class GeoApp extends StatelessWidget {
  const GeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        pp('$mx 🌀🌀🌀🌀 Tap detected; should dismiss keyboard ...');
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: StreamBuilder(
          stream: themeBloc.themeStream,
          builder: (_, snapshot) {
            if (snapshot.hasData) {
              pp('\n\n${E.check}${E.check}${E.check}${E.check}${E.check} '
                  'main: theme index has changed to ${snapshot.data}\n\n');
              themeIndex = snapshot.data!;
            }
            return MaterialApp(
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              debugShowCheckedModeBanner: false,
              title: 'GeoMonitor',
              theme: themeBloc.getTheme(themeIndex).darkTheme,
              darkTheme: themeBloc.getTheme(themeIndex).darkTheme,
              themeMode: ThemeMode.dark,
              // home: const VideoHandlerTwo(),
              home: AnimatedSplashScreen(
                duration: 2000,
                splash: const SplashWidget(),
                animationDuration: const Duration(milliseconds: 2000),
                curve: Curves.easeInCirc,
                splashIconSize: 160.0,
                nextScreen: fbAuthedUser == null
                    ? const IntroMain()
                    : const DashboardMain(),
                splashTransition: SplashTransition.fadeTransition,
                pageTransitionType: PageTransitionType.leftToRight,
                backgroundColor: Colors.pink.shade900,
              ),
            );
          }),
    );
  }
}
late StreamSubscription killSubscriptionFCM;

Future<void> initializeGeoMonitor() async {
  pp('$mx _initializeGeoMonitor: ... GET CACHED SETTINGS; set themeIndex .............. ');
  var settings = await prefsOGx.getSettings();
  if (settings != null) {
    themeIndex = settings.themeIndex!;
    themeBloc.themeStreamController.sink.add(settings.themeIndex!);
  }

  if (fbAuthedUser != null) {
    pp('$mx _initializeGeoMonitor: Firebase user is OK, checking cached user ...');
    var user = await prefsOGx.getUser();
    if (user == null) {
      pp('\n\n$mx no cached user found, will set fbAuthedUser to null ...');
      fbAuthedUser = null;
      //await fb.FirebaseAuth.instance.signOut();
    } else {
      pp('$mx _initializeGeoMonitor: GeoMonitor user is OK');
    }
  } else {
    pp('$mx Firebase has no current user!');
  }
  pp('$mx _initializeGeoMonitor: THEME: themeIndex up top is: $themeIndex ');
  //pp('THEME: user up top is: ${user!.name}');
  await dotenv.load(fileName: ".env");
  pp('$mx $heartBlue DotEnv has been loaded');

  await Hive.initFlutter(hiveName);
  await cacheManager.initialize(forceInitialization: false);

  pp('$mx ${E.heartGreen}${E.heartGreen}}${E.heartGreen} '
      '_initializeGeoMonitor: Hive initialized and boxCollection set up');

  //APNS - Key ID:F9S83G3AX4
  FirebaseMessaging.instance.requestPermission();
  await AppAuth.listenToFirebaseAuthentication();

  pp('\n$mx _buildGeofences starting ........................');
  theGreatGeofencer.buildGeofences();

  pp('$mx fcm initialization starting ........................');
  fcmBloc.initialize();

  pp('$mx manageMediaUploads starting ........................');
  geoUploader.manageMediaUploads();

  pp('$mx organizationDataRefresh starting ........................');

  if (settings != null) {
    organizationDataRefresh.startRefresh(settings.numberOfDays!);
    pp('\n\n$mx ${E.heartGreen}${E.heartGreen}}${E.heartGreen} '
        '_initializeGeoMonitor: App Settings are 🍎${settings.toJson()}🍎\n\n');
  }
}


void showKillDialog({required String message, required BuildContext context}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(
        "Critical App Message",
        style: myTextStyleLarge(ctx),
      ),
      content: Text(
        message,
        style: myTextStyleMedium(ctx),
      ),
      shape: getRoundedBorder(radius: 16),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            pp('$mm Navigator popping for the last time, Sucker! 🔵🔵🔵');
            var android = UniversalPlatform.isAndroid;
            var ios = UniversalPlatform.isIOS;
            if (android) {
              SystemNavigator.pop();
            }
            if (ios) {
              Navigator.of(ctx).pop();
              Navigator.of(ctx).pop();
            }
          },
          child: const Text("Exit the App"),
        ),
      ],
    ),
  );
}

StreamSubscription<String> listenForKill({required BuildContext context}) {
  pp('\n$mx Kill message; listen for KILL message ...... 🍎🍎🍎🍎 ......');

  var sub = fcmBloc.killStream.listen((event) {
    pp('$mm Kill message arrived: 🍎🍎🍎🍎 $event 🍎🍎🍎🍎');
    try {
      showKillDialog(message: event, context: context);
    } catch (e) {
      pp(e);
    }
  });

  return sub;
}


