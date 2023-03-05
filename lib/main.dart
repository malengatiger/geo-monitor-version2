import 'dart:async';
import 'dart:ui';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_monitor/device_location/device_location_bloc.dart';
import 'package:geo_monitor/library/auth/app_auth.dart';
import 'package:geo_monitor/library/functions.dart';
import 'package:geo_monitor/splash/splash_page.dart';
import 'package:geo_monitor/ui/dashboard/dashboard_main.dart';
import 'package:geo_monitor/ui/intro/intro_main.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:location/location.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_platform/universal_platform.dart';

import 'firebase_options.dart';
import 'library/api/prefs_og.dart';
import 'library/bloc/fcm_bloc.dart';
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
  await _initializeGeoMonitor();

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

Future<void> _initializeGeoMonitor() async {
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
  pp('\n$mx manageMediaUploads starting ........................');
  //geoUploader.manageMediaUploads();

  if (settings != null) {
    pp('\n\n$mx ${E.heartGreen}${E.heartGreen}}${E.heartGreen} _initializeGeoMonitor: App Settings are 🍎${settings.toJson()}🍎\n\n');
  }
  // Future<void> initializeService() async {
  //   final service = FlutterBackgroundService();
  //
  //   /// OPTIONAL, using custom notification channel id
  //   const AndroidNotificationChannel channel = AndroidNotificationChannel(
  //     'my_foreground', // id
  //     'MY FOREGROUND SERVICE', // title
  //     description:
  //     'This channel is used for important notifications.', // description
  //     importance: Importance.low, // importance must be at low or higher level
  //   );
  //
  //   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  //   FlutterLocalNotificationsPlugin();
  //
  //   if (Platform.isIOS) {
  //     await flutterLocalNotificationsPlugin.initialize(
  //       const InitializationSettings(
  //         iOS: IOSInitializationSettings(),
  //       ),
  //     );
  //   }
  //
  //   await flutterLocalNotificationsPlugin
  //       .resolvePlatformSpecificImplementation<
  //       AndroidFlutterLocalNotificationsPlugin>()
  //       ?.createNotificationChannel(channel);
  //
  //   await service.configure(
  //     androidConfiguration: AndroidConfiguration(
  //       // this will be executed when app is in foreground or background in separated isolate
  //       onStart: onStart,
  //
  //       // auto start service
  //       autoStart: true,
  //       isForegroundMode: true,
  //
  //       notificationChannelId: 'my_foreground',
  //       initialNotificationTitle: 'AWESOME SERVICE',
  //       initialNotificationContent: 'Initializing',
  //       foregroundServiceNotificationId: 888,
  //     ),
  //     iosConfiguration: IosConfiguration(
  //       // auto start service
  //       autoStart: true,
  //
  //       // this will be executed when app is in foreground in separated isolate
  //       onForeground: onStart,
  //
  //       // you have to enable background fetch capability on xcode project
  //       onBackground: onIosBackground,
  //     ),
  //   );
  //
  //   service.startService();
  // }

}

// to ensure this is executed
// run app from xcode, then from xcode menu, select Simulate Background Fetch

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // SharedPreferences preferences = await SharedPreferences.getInstance();
  // await preferences.reload();
  // final log = preferences.getStringList('log') ?? <String>[];
  // log.add(DateTime.now().toIso8601String());
  // await preferences.setStringList('log', log);

  return true;
}
//
// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   // Only available for flutter 3.0.0 and later
//   DartPluginRegistrant.ensureInitialized();
//
//   // For flutter prior to version 3.0.0
//   // We have to register the plugin manually
//
//   // SharedPreferences preferences = await SharedPreferences.getInstance();
//   // await preferences.setString("hello", "world");
//
//   /// OPTIONAL when use custom notification
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//   FlutterLocalNotificationsPlugin();
//
//   if (service is AndroidServiceInstance) {
//     service.on('setAsForeground').listen((event) {
//       service.setAsForegroundService();
//     });
//
//     service.on('setAsBackground').listen((event) {
//       service.setAsBackgroundService();
//     });
//   }
//
//   service.on('stopService').listen((event) {
//     service.stopSelf();
//   });
//
//   // bring to foreground
//   Timer.periodic(const Duration(seconds: 1), (timer) async {
//     if (service is AndroidServiceInstance) {
//       if (await service.isForegroundService()) {
//         /// OPTIONAL for use custom notification
//         /// the notification id must be equals with AndroidConfiguration when you call configure() method.
//         flutterLocalNotificationsPlugin.show(
//           888,
//           'COOL SERVICE',
//           'Awesome ${DateTime.now()}',
//           const NotificationDetails(
//             android: AndroidNotificationDetails(
//               'my_foreground',
//               'MY FOREGROUND SERVICE',
//               icon: 'ic_bg_service_small',
//               ongoing: true,
//             ),
//           ),
//         );
//
//         // if you don't using custom notification, uncomment this
//         // service.setForegroundNotificationInfo(
//         //   title: "My App Service",
//         //   content: "Updated at ${DateTime.now()}",
//         // );
//       }
//     }
//
//     /// you can see this log in logcat
//     pp('$mx FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');
//
//     // test using external plugin
//     final deviceInfo = DeviceInfoPlugin();
//     String? device;
//     if (Platform.isAndroid) {
//       final androidInfo = await deviceInfo.androidInfo;
//       device = androidInfo.model;
//     }
//
//     if (Platform.isIOS) {
//       final iosInfo = await deviceInfo.iosInfo;
//       device = iosInfo.model;
//     }
//
//     service.invoke(
//       'update',
//       {
//         "current_date": DateTime.now().toIso8601String(),
//         "device": device,
//       },
//     );
//   });
// }


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  LocationData? data;
  void _incrementCounter() async {
    data = await locationBloc.getLocation();
    debugPrint('😡 😡 😡 😡 😡 location: $data');
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Location',
              style: myTextStyleLargePrimaryColor(context),
            ),
            const SizedBox(
              height: 24,
            ),
            data == null
                ? const SizedBox()
                : Text(
                    '${data!.latitude}',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
            const SizedBox(
              height: 12,
            ),
            data == null
                ? const SizedBox()
                : Text(
                    '${data!.longitude}',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
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


