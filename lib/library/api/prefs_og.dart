import 'package:geo_monitor/library/data/questionnaire.dart';
import 'package:get_storage/get_storage.dart';
import 'package:localstorage/localstorage.dart';

import '../data/country.dart';
import '../data/settings_model.dart';
import '../data/user.dart';
import '../functions.dart';

final PrefsOGx prefsOGx = PrefsOGx();
const String cacheName = 'GeoPreferences3';

class PrefsOGx {
  static const mm = '🔵🔵🔵🔵🔵🔵 PrefsOGx 🔵🔵🔵 : ',
      bb = '🦠🦠🦠🦠🦠🦠🦠 PrefsOGx  🦠: ';

  final box = GetStorage(cacheName);

  Future setDateRefreshed(String date) async {
    await box.write('dateRefreshed', date);
    pp("$mm setDateRefreshed SET to $date");
    return null;
  }
  bool shouldRefreshBePerformed() {
    var refreshDate = _getDateRefreshed();
    final rDate = DateTime.parse(refreshDate);
    final now = DateTime.now();
    final delta = now.difference(rDate).inHours;
    if (delta >= 12) {
      return true;
    } else {
      return false;
    }
  }
  String _getDateRefreshed()  {
    pp('$mm ......... getting getDateRefreshed from cache! ...');
    String? date =  box.read('dateRefreshed');
    if (date == null) {
      pp('$mm Date Refreshed does not exist in Prefs, '
          'create date from a year ago, just for kicks! 🍎🍎🍎!');
      date = DateTime.now().subtract(const Duration(days: 365))
          .toIso8601String();
      return date;
    } else {
      pp("$mm _getDateRefreshed: 🧩 🧩 🧩 🧩 🧩 date .. $date 🔴🔴");
      return date;
    }
  }


  Future setFCMSubscriptionFlag() async {
    await box.write('fcm', true);
    pp("\n\n$mm setFCMSubscription SET as true\n");
    return null;
  }
  Future resetFCMSubscriptionFlag() async {
    await box.write('fcm', false);
    pp("\n\n$mm setFCMSubscription RESET to false\n");
    return null;
  }

  Future<bool> getFCMSubscriptionFlag() async {
    pp('\n$mm ......... getting getFCMSubscription from cache! ...');
    bool? isSubscribed =  box.read('fcm');
    if (isSubscribed == null || isSubscribed == false) {
      pp('$mm FCMSubscription flag does not exist in Prefs, '
          'one time isSubscribed, 🍎🍎🍎 next time not so much!');
      return false;
    } else {
      pp("$mm FCMSubscription flag: 🧩 🧩 🧩 🧩 🧩 retrieved .. $isSubscribed 🔴🔴");
      return isSubscribed;
    }
  }
  Future saveUser(User user) async {
    await box.write('user', user.toJson());
    pp("\n\n$mm saveUser SAVED: 🌽 ${user.name}\n");
    return null;
  }

  Future<User?> getUser() async {
    // pp('\n$mm ......... getting user from cache! ...');
    User? user;
    var mJson = await box.read('user');
    if (mJson == null) {
      pp('$mm User does not exist in Prefs, '
          'one time ok, 🍎🍎🍎 next time not so much!');
      return null;
    } else {
      user = User.fromJson(mJson);
      // pp("$mm getUser 🧩🧩🧩🧩🧩 retrieved .. ${user.name}  🔴🔴");
      return user;
    }
  }

  Future saveSettings(SettingsModel settings) async {
    await box.write('settings', settings.toJson());
    pp("\n\n$mm settings SAVED: 🌽 ${settings.toJson()}\n");
    return null;
  }

  Future<SettingsModel?> getSettings() async {
    // pp('\n$mm ......... getting settings from cache! ...');
    SettingsModel? settings;
    var mJson = await box.read('settings');
    if (mJson == null) {
      pp('$mm SettingsModel does not exist in Prefs, '
          'one time ok, 🍎🍎🍎 returning null');
      return null;
    } else {
      settings = SettingsModel.fromJson(mJson);
      // pp("$mm getSettings 🧩 🧩 🧩 🧩 🧩 retrieved: ${settings.toJson()}  🔴🔴");
      return settings;
    }
  }

  void deleteUser() async {
    await box.remove("user");
    pp("$mm  ... user deleted  🔴🔴");
  }

  Future saveCountry(Country country) async {
    await box.write('country', country);
    pp("$mm saveCountry  SAVED: 🌽 ${country.toJson()}");
    return null;
  }

  Future<Country?> getCountry() async {
    Country? country;
    var entry = box.read('country');
    if (entry != null) {
      country = Country.fromJson(entry);
      pp("$mm getCountry 🧩  ${country.name} retrieved");
    }

    return country;
  }

  Future saveQuestionnaire(Questionnaire q) async {
    box.write('questionnaire', q);
    pp("$mm saveQuestionnaire  SAVED: 🌽 ${q.toJson()}");
    return null;
  }

  Future getQuestionnaire() async {
    var q = box.read('questionnaire');
    pp("$mm getQuestionnaire: 🌽 ${q.toJson()}");
    return q;
  }

  Future removeQuestionnaire() async {
    await box.remove('questionnaire');
    pp("$mm removeQuestionnaire  removed");
  }
}

final LocalStore localStore = LocalStore();

class LocalStore {
  final storage = LocalStorage('Preferences');
  Future setThemeIndex(int index) async {
    if (await storage.ready) {
      storage.setItem('themeIndex', index);
      pp('index $index has been stored');
    }
  }

  Future<int> getThemeIndex() async {
    if (await storage.ready) {
      var index = await storage.getItem('themeIndex');
      pp('index $index has been retrieved');
      return index;
    }
    return 0;
  }
}
