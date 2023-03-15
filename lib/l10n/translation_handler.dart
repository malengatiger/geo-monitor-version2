import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:geo_monitor/l10n/my_keys.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';

import '../library/functions.dart';

final TranslationHandler mTx = TranslationHandler._instance;

class TranslationHandler {
  static final TranslationHandler _instance = TranslationHandler._internal();

  factory TranslationHandler() {
    return _instance;
  }

  TranslationHandler._internal() {
    // initialization logic
  }
  final android = Platform.isAndroid;
  var localeMap = HashMap<String,String>();
  static const mm = '🌎🔵 mtX: ';
  String? currentLocale;

  void initialize({String? locale}) async {
    localeMap.clear();
    if (locale != null) {
       await translate('settings', locale);
       return;
    }
    var sett = await prefsOGx.getSettings();
    if (sett != null) {
      await translate('settings', sett.locale!);
    } else {
      await translate('settings', 'en');
    }
  }

  Future<String> translate(String key, String locale) async {
      if (localeMap.isEmpty || currentLocale == null) {
        await _loadFile(locale, localeMap);
      } else {
        if (locale != currentLocale) {
          await _loadFile(locale, localeMap);
        }
      }
      final value = localeMap[key];
      if (value == null) {
        return 'UNAVAILABLE KEY: $key';
      }
      return value;
  }


  _loadFile(String locale,HashMap<String,String> hashMap) async {
    pp('$mm loading locale strings for $locale, will clear current locale strings');
    hashMap.clear();
    var start = DateTime.now();
    var s = await getStringFromAssets(locale);
    var mJson = jsonDecode(s);
    pp(mJson);
    final map = MyKeys.getKeys();

    map.forEach((key, value) {
      try {
        hashMap[key] = mJson[key];
      } catch (e) {
        pp('$mm $e key: $key');
      }
    });
    currentLocale = locale;
    pp('$mm LOCALE MAP built ..... from file contents: ${s.length} bytes');
    var end = DateTime.now();
    pp('$mm currentLocale $currentLocale '
        'has ${hashMap.length} translation strings; 🔵 '
        'time elapsed: ${end.difference(start).inMilliseconds} milliseconds');
  }
}