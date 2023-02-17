import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

import 'firebase_options.dart';
import 'library/api/prefs_og.dart';
import 'library/bloc/theme_bloc.dart';
import 'library/bloc/uploader.dart';
import 'library/cache_manager.dart';
import 'library/emojis.dart';
import 'library/geofence/geofencer_two.dart';

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
  }
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const GeoApp());
  _initializeGeoMonitor();
  _buildGeofences();
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
              home: AnimatedSplashScreen(
                duration: 2000,
                splash: const SplashWidget(),
                animationDuration: const Duration(milliseconds: 2000),
                curve: Curves.easeInCirc,
                splashIconSize: 160.0,
                nextScreen: fbAuthedUser == null
                    ? const IntroMain()
                    : const DashboardMain(),
                // nextScreen: const UserListMain(),
                splashTransition: SplashTransition.fadeTransition,
                pageTransitionType: PageTransitionType.leftToRight,
                backgroundColor: Colors.pink.shade900,
              ),
            );
          }),
    );
  }
}

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

  uploader.startTimer(const Duration(seconds: 20));

  if (settings != null) {
    pp('\n\n$mx ${E.heartGreen}${E.heartGreen}}${E.heartGreen} _initializeGeoMonitor: App Settings are 🍎${settings.toJson()}🍎\n\n');
  }
}

void _buildGeofences() async {
  pp('\n$mx _buildGeofences starting ........................');
  theGreatGeofencer.buildGeofences();
  pp('$mx _buildGeofences should be done and dusted ....');
}

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
