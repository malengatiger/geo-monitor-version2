import 'dart:async';
import 'dart:math';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';


import '../api/prefs_og.dart';
import '../emojis.dart';
import '../functions.dart';

final ThemeBloc themeBloc = ThemeBloc();

class ThemeBloc {
  ThemeBloc() {
    pp('✈️✈️ ... ThemeBloc initializing ....');
    _initialize();
  }

  final StreamController<int> _themeController = StreamController.broadcast();
  Stream<int> get newThemeStream => _themeController.stream;

  final _rand = Random(DateTime.now().millisecondsSinceEpoch);

  int _themeIndex = 0;

  int get themeIndex => _themeIndex;

  _initialize() async {
    _themeIndex = await prefsOGx.getThemeIndex();
    pp('$mm ThemeBloc: initialize:: adding index to stream ....theme index: $themeIndex');
    _themeController.sink.add(_themeIndex);
  }

  Future start()  async {
    _themeIndex = await prefsOGx.getThemeIndex();
    _themeController.sink.add(_themeIndex);
    pp('$mm theming started ...... _themeIndex: $_themeIndex');
  }

  ThemeBag getTheme(int index) {
    return SchemeUtil.getTheme(themeIndex: index);
  }

  Future<int> changeToRandomTheme() async {
    _themeIndex = _rand.nextInt(SchemeUtil.getThemeCount() - 1);
    pp('\n\n$mm changing to theme index: $_themeIndex');
    pp('$mm _setStream: setting stream .... to theme index: $_themeIndex');
    await prefsOGx.setThemeIndex(_themeIndex);
    var settings = await prefsOGx.getSettings();
    settings.themeIndex = _themeIndex;
    await prefsOGx.saveSettings(settings);
    _themeController.sink.add(_themeIndex);
    return _themeIndex;
  }
  Future<int> changeToTheme(int index) async {
    pp('\n\n$mm changing to theme index: $index');
    pp('$mm _setStream: setting stream .... to theme index: $_themeIndex');
    await prefsOGx.setThemeIndex(index);
    var settings = await prefsOGx.getSettings();
    settings.themeIndex = _themeIndex;
    await prefsOGx.saveSettings(settings);
    _themeController.sink.add(index);
    return index;
  }

  int getThemeCount() {
    return SchemeUtil.getThemeCount();
  }

  closeStream() {
    _themeController.close();
  }

  static final mm = '${E.appleRed}${E.appleRed}${E.appleRed}';
}


/*
theme: FlexThemeData.light(scheme: FlexScheme.mallardGreen),
        // The Mandy red, dark theme.
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.mallardGreen),
        // Use dark or light theme based on system setting.
        themeMode: ThemeMode.system,
 */
class SchemeUtil {
  static final List<ThemeBag> _themeBags = [];
  static final _rand = Random(DateTime.now().millisecondsSinceEpoch);
  static int index = 0;
  static final mm = 'ThemeBloc ${E.diamond}${E.diamond}${E.diamond}';

  static int getThemeCount() {
    _setThemes();
    return _themeBags.length;
  }
  static ThemeBag getTheme({required int themeIndex}) {
    if (_themeBags.isEmpty) {
      _setThemes();
    }
    if (themeIndex >= _themeBags.length) {
      return _themeBags.first;
    }

    return _themeBags.elementAt(themeIndex);
  }

  static ThemeBag getRandomTheme() {
    if (_themeBags.isEmpty) _setThemes();
    var index = _rand.nextInt(_themeBags.length - 1);
    return _themeBags.elementAt(index);
  }

  static ThemeBag getThemeByIndex(int index) {
    if (_themeBags.isEmpty) _setThemes();
    if (index >= _themeBags.length || index < 0) index = 0;
    return _themeBags.elementAt(index);
  }

  static void _setThemes() {
    _themeBags.clear();

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.redWine),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.redWine)));
    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.green),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.green)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.mallardGreen),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.mallardGreen)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.mandyRed),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.mandyRed)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.redWine),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.redWine)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.red),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.red)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.flutterDash),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.flutterDash)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.mango),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.mango)));


    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.indigo),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.indigo)));
    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.deepBlue),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.deepBlue)));
    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.hippieBlue),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.hippieBlue)));
    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.deepPurple),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.deepPurple)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.espresso),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.espresso)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.barossa),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.barossa)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.bigStone),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.bigStone)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.damask),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.damask)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.purpleBrown),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.purpleBrown)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.wasabi),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.wasabi)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.rosewood),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.rosewood)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.sanJuanBlue),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.sanJuanBlue)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.material),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.material)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.mandyRed),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.mandyRed)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.mango),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.mango)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.amber),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.amber)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.dellGenoa),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.dellGenoa)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.gold),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.gold)));
    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.blue),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.blue)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.red),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.red)));
    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.green),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.green)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.blueWhale),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.blueWhale)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.purpleBrown),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.purpleBrown)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.ebonyClay),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.ebonyClay)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.money),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.money)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.aquaBlue),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.aquaBlue)));

    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.blumineBlue),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.blumineBlue)));
    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.barossa),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.barossa)));
    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.green),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.green)));
    _themeBags.add(ThemeBag(
        lightTheme: FlexThemeData.light(scheme: FlexScheme.greyLaw),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.greyLaw)));



  }
}

class ThemeBag {
  late final ThemeData lightTheme;
  late final ThemeData darkTheme;

  ThemeBag({required this.lightTheme, required this.darkTheme});
}
