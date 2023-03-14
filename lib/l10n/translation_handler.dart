import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:geo_monitor/l10n/my_keys.dart';

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

  Future<String> tx(String key, String locale) async {
      if (localeMap.isEmpty || currentLocale == null) {
        await _loadFile(locale, localeMap);
      } else {
        if (locale != currentLocale) {
          await _loadFile(locale, localeMap);
        }
      }
      pp('$mm translate key: $key from localeMap with '
          '${localeMap.length} strings');
      final value = localeMap[key];
      if (value == null) {
        return 'UNAVAILABLE KEY: $key';
      }
      return value;
  }


  _loadFile(String locale,HashMap<String,String> hashMap) async {
    pp('$mm loading locale strings for $locale');
    var start = DateTime.now();
    var s = await getStringFromAssets(locale);
    var mJson = jsonDecode(s);
    final map = MyKeys.getKeys();

    map.forEach((key, value) {
      hashMap[key] = mJson[key];
    });
    currentLocale = locale;
    pp('$mm LOCALE MAP built .....');
    // hashMap.forEach((key, value) {
    //   pp('$mm $key : 🍎 $value');
    // });
    var end = DateTime.now();
    pp('$mm currentLocale $currentLocale '
        'has ${hashMap.length} translation strings; 🔵 '
        'time elapsed: ${end.difference(start).inMilliseconds} milliseconds');
  }
}