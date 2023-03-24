import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'library/api/prefs_og.dart';
import 'library/auth/app_auth.dart';
import 'library/bloc/data_refresher.dart';
import 'library/bloc/fcm_bloc.dart';
import 'library/bloc/geo_uploader.dart';
import 'library/bloc/theme_bloc.dart';
import 'library/cache_manager.dart';
import 'library/emojis.dart';
import 'library/functions.dart';
import 'library/geofence/geofencer_two.dart';

int themeIndex = 0;
final Initializer initializer = Initializer();

class Initializer {
  final mx =
      '✅✅✅✅✅ Initializer: ✅';

  Future<void> initializeGeo() async {
    pp('$mx initializeGeo: ... GET CACHED SETTINGS; set themeIndex .............. ');
    var settings = await prefsOGx.getSettings();
    if (settings != null) {
      themeIndex = settings.themeIndex!;
      Locale newLocale = Locale(settings!.locale!);
      final m = LocaleAndTheme(themeIndex: settings.themeIndex!,
          locale: newLocale);
      themeBloc.themeStreamController.sink.add(m);
      pp('$mx THEME: themeIndex up top is: $themeIndex locale: ${settings!.locale}');
    }

    await cacheManager.initialize(forceInitialization: false);

    pp('$mx  '
        'initializeGeo: Hive initialized and boxCollection set up');

    FirebaseMessaging.instance.requestPermission();
    await AppAuth.listenToFirebaseAuthentication();

    if (settings != null) {
      heavyLifting(settings.numberOfDays!);
      pp('$mx ${E.heartGreen}${E.heartGreen}}${E.heartGreen} '
          'initializeGeo: App Settings are 🍎${settings.toJson()}🍎');
    }
  }

  void heavyLifting(int numberOfDays) {

    pp('$mx heavyLifting: fcm initialization starting ........................');
    fcmBloc.initialize();

    pp('$mx heavyLifting: manageMediaUploads starting ........................');
    geoUploader.manageMediaUploads();

    pp('$mx heavyLifting: _buildGeofences starting ........................');
    theGreatGeofencer.buildGeofences();

    pp('$mx organizationDataRefresh starting ........................');
    pp('$mx start delay of 30 seconds before data refresh ..............');

    Future.delayed(const Duration(seconds: 30)).then((value) async {
      pp('$mx start data refresh after delaying for 30 seconds');
      var settings = await prefsOGx.getSettings();
      if (settings != null) {
        dataRefresher.manageRefresh(numberOfDays: numberOfDays,
            organizationId: settings.organizationId!,
            projectId: null, userId: null);
      }

    });
  }

}