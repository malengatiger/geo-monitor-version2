import 'package:geo_monitor/library/data/questionnaire.dart';
import 'package:geo_monitor/library/ui/settings.dart';
import 'package:get_storage/get_storage.dart';
import 'package:localstorage/localstorage.dart';

import '../data/country.dart';
import '../data/settings_model.dart';
import '../data/user.dart';
import '../emojis.dart';
import '../functions.dart';

final PrefsOGx prefsOGx = PrefsOGx();

class PrefsOGx {
  static const mm = '🔵🔵🔵🔵🔵🔵 PrefsOGx 🔵🔵🔵 : ',
      bb = '🦠🦠🦠🦠🦠🦠🦠 PrefsOGx  🦠: ';

  final box = GetStorage("GeoPreferences");

  Future saveUser(User user) async {
    await box.write('user', user.toJson());
    pp("\n\n$mm saveUser SAVED: 🌽 ${user.toJson()}\n");
    return null;
  }

  Future<User?> getUser() async {
    pp('\n$mm ......... getting user from cache! ...');
    User? user;
    var mJson = await box.read('user');
    if (mJson == null) {
      pp('$mm User does not exist in Prefs, '
          'one time ok, 🍎🍎🍎 next time not so much!');
      return null;
    } else {
      user = User.fromJson(mJson);
      pp("$mm getUser 🧩 🧩 🧩 🧩 🧩 retrieved: ${user.toJson()}  🔴🔴");
      return user;
    }

  }

   Future setThemeIndex(int index) async {
     var oldIndex = await getThemeIndex();
    pp('$bb setting theme index to $index , old index is: $oldIndex');
    await box.write('themeIndex', index);
    pp('$mm theme index set to: $index 🍎🍎');

    var result = await getThemeIndex();
    pp('$mm theme index after being set: $result 🍎🍎');
  }

   Future<int> getThemeIndex() async {
    var index = await box.read('themeIndex');
    if (index == null) {
      pp('$mm theme index does not exist. defaulting to zero index ${E.redDot} ${E.redDot} ');
      return 0;
    } else {
      pp('$bb returning theme index 🧩 🧩 🧩 🧩 🧩 $index  🍎 to app');
      return index;
    }
  }

   Future saveSettings(SettingsModel settings) async {
    await box.write('settings', settings.toJson());
    pp("\n\n$mm settings SAVED: 🌽 ${settings.toJson()}\n");
    return null;
  }

   Future<SettingsModel> getSettings() async {
    pp('\n$mm ......... getting settings from cache! ...');
    SettingsModel? settings;
    var mJson = await box.read('settings');
    if (mJson == null) {
      pp('$mm SettingsModel does not exist in Prefs, '
          'one time ok, 🍎🍎🍎 returning default settings');
      var model = SettingsModel(distanceFromProject: 100,
          photoSize: 0, maxVideoLengthInMinutes: 2, maxAudioLengthInMinutes: 30, themeIndex: 0,
          settingsId: '', created: '', organizationId: '', projectId: '');
      await saveSettings(model);
      return model;
    } else {
      settings = SettingsModel.fromJson(mJson);
      pp("$mm getSettings 🧩 🧩 🧩 🧩 🧩 retrieved: ${settings.toJson()}  🔴🔴");
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
      pp("$mm getCountry 🧩  ${country!.name} retrieved");
    }

    return country;
  }
   Future saveQuestionnaire(Questionnaire q) async {
    box.write('questionnaire', q);
    pp("$mm saveQuestionnaire  SAVED: 🌽 ${q.toJson()}");
    return null;
  }
   Future getQuestionnaire() async {
    var q =box.read('questionnaire');
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