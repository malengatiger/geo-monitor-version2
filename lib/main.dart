import 'dart:async';
import 'dart:io';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_monitor/l10n/translation_handler.dart';
import 'package:geo_monitor/library/data/settings_model.dart';
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
import 'library/bloc/theme_bloc.dart';
import 'library/cache_manager.dart';
import 'library/emojis.dart';

int themeIndex = 0;
var locale = const Locale('fr');
SettingsModel? settings;
late FirebaseApp firebaseApp;
fb.User? fbAuthedUser;
final mx =
    '${E.heartGreen}${E.heartGreen}${E.heartGreen}${E.heartGreen} main: ';
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  firebaseApp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  pp('$mx main: '
      ' Firebase App has been initialized: ${firebaseApp.name}, checking for authed current user');
  fbAuthedUser = fb.FirebaseAuth.instance.currentUser;


  settings = await prefsOGx.getSettings();
  if (settings != null) {
    locale = Locale(settings!.locale!);
  }
  pp('$mx main: locale set up ...');
  await GetStorage.init(cacheName);

  // final prefs = await SharedPreferences.getInstance();
  // pp('$mx main: SharedPreferences.getInstance: $prefs ');
  //
  try {
    await EasyLocalization.ensureInitialized();
    pp('$mx ..... EasyLocalization.ensureInitialized OK!');
  } catch (e) {
    pp('$mx EasyLocalization.ensureInitialized failed: $e');
  }


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
    //cameras = await availableCameras();
  }
  await dotenv.load(fileName: ".env");
  pp('$mx $heartBlue DotEnv has been loaded');

  await Hive.initFlutter(hiveName);

  mTx.initialize();
  pp('$mx $heartBlue translation service initialization started!');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final android = Platform.isAndroid;
  if (android) {
     runApp(EasyLocalization(
         path: 'assets/l10n',
         supportedLocales: const [
           Locale('en'),
           Locale('af'),
           Locale('es'),
           Locale('fr'),
           Locale('ig'),
           Locale('pt'),
           Locale('sn'),
           Locale('st'),
           Locale('sw'),
           Locale('ts'),
           Locale('xh'),
           Locale('yo'),
           Locale('zu'),
         ],
         child: const GeoAndroidApp()));
  } else {
    runApp(const GeoApp());
  }
}
class GeoApp extends StatelessWidget {
  const GeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Locale myLocale = Localizations.localeOf(context);
    // pp('$mx 🌀🌀🌀🌀 Current Locale: $myLocale ...');
    return GestureDetector(
      onTap: () {
        pp('$mx 🌀🌀🌀🌀 Tap detected; should dismiss keyboard ...');
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: StreamBuilder<LocaleAndTheme>(
          stream: themeBloc.localeAndThemeStream,
          builder: (_, snapshot) {
            if (snapshot.hasData) {
              pp('${E.check}${E.check}${E.check}${E.check}${E.check} '
                  'main: theme index has changed to ${snapshot.data!.themeIndex}'
                  '  and locale is ${snapshot.data!.locale.toString()}');
              themeIndex = snapshot.data!.themeIndex;
              locale = snapshot.data!.locale;
              pp('${E.check}${E.check}${E.check} locale object received: $locale}');
            }
            return MaterialApp(
              // localizationsDelegates: context.localizationDelegates,
              // supportedLocales: context.supportedLocales,
              locale: locale,
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

class GeoAndroidApp extends StatelessWidget {
  const GeoAndroidApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Locale myLocale = Localizations.localeOf(context);
    // pp('$mx 🌀🌀🌀🌀 Current Locale: $myLocale ...');
    return GestureDetector(
      onTap: () {
        pp('$mx 🌀🌀🌀🌀 Tap detected; should dismiss keyboard ...');
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: StreamBuilder<LocaleAndTheme>(
          stream: themeBloc.localeAndThemeStream,
          builder: (_, snapshot) {
            if (snapshot.hasData) {
              pp('${E.check}${E.check}${E.check}${E.check}${E.check} '
                  'main: theme index has changed to ${snapshot.data!.themeIndex}'
                  '  and locale is ${snapshot.data!.locale.toString()}');
              themeIndex = snapshot.data!.themeIndex;
              locale = snapshot.data!.locale;
              pp('${E.check}${E.check}${E.check} locale object received: $locale}');
            }
            return MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: locale,
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              debugShowCheckedModeBanner: false,
              title: 'Geo',
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
