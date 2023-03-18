import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/data_refresher.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';
import 'package:geo_monitor/library/data/settings_model.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/translation_handler.dart';
import '../../api/data_api.dart';
import '../../api/prefs_og.dart';
import '../../bloc/theme_bloc.dart';
import '../../cache_manager.dart';
import '../../data/project.dart';
import '../../data/user.dart';
import '../../functions.dart';
import '../../generic_functions.dart';

class SettingsForm extends StatefulWidget {
  const SettingsForm(
      {Key? key, required this.padding, required this.onLocaleChanged})
      : super(key: key);
  final double padding;
  final Function(String locale) onLocaleChanged;
  @override
  State<SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  final mm = '🥨🥨🥨🥨🥨SettingsForm: ';
  User? user;
  var orgSettings = <SettingsModel>[];
  Project? selectedProject;
  SettingsModel? settingsModel;
  SettingsModel? oldSettingsModel;

  var distController = TextEditingController(text: '500');
  var videoController = TextEditingController(text: '20');
  var audioController = TextEditingController(text: '60');
  var activityController = TextEditingController(text: '24');
  var daysController = TextEditingController(text: '7');

  int photoSize = 0;
  int currentThemeIndex = 0;
  int groupValue = 0;
  bool busy = false;
  bool busyWritingToDB = false;

  String? currentLocale;

  @override
  void initState() {
    super.initState();
    _getSettings();
  }

  void _getSettings() async {
    pp('$mm 🍎🍎 ............. getting user from prefs ...');
    user = await prefsOGx.getUser();
    settingsModel = await prefsOGx.getSettings();
    oldSettingsModel = await prefsOGx.getSettings();
    if (settingsModel != null) {
      currentLocale = settingsModel!.locale!;
    }
    pp('$mm 🍎🍎 user is here, huh? 🌎 ${user!.name!}');
    _setExistingSettings();
    _setTitles();
  }

  String? fieldMonitorInstruction,
      maximumMonitoringDistance,
      maximumVideoLength,
      maximumAudioLength,
      activityStreamHours,
      numberOfDays,
      pleaseSelectCountry,
      tapForColorScheme,
      settings,
      small,
      medium,
      large,
      numberOfDaysForDashboardData,
      selectLanguage,
      hint;

  void _setTitles() async {
    fieldMonitorInstruction =
        await mTx.translate('fieldMonitorInstruction', settingsModel!.locale!);
    maximumMonitoringDistance = await mTx.translate(
        'maximumMonitoringDistance', settingsModel!.locale!);
    numberOfDaysForDashboardData = await mTx.translate(
        'numberOfDaysForDashboardData', settingsModel!.locale!);
    maximumVideoLength =
        await mTx.translate('maximumVideoLength', settingsModel!.locale!);
    maximumAudioLength =
        await mTx.translate('maximumAudioLength', settingsModel!.locale!);
    activityStreamHours =
        await mTx.translate('activityStreamHours', settingsModel!.locale!);
    selectSizePhotos =
        await mTx.translate('selectSizePhotos', settingsModel!.locale!);
    pleaseSelectCountry =
        await mTx.translate('pleaseSelectCountry', settingsModel!.locale!);
    tapForColorScheme =
        await mTx.translate('tapForColorScheme', settingsModel!.locale!);
    numberOfDays = await mTx.translate('numberOfDays', settingsModel!.locale!);
    settings = await mTx.translate('settings', settingsModel!.locale!);
    small = await mTx.translate('small', settingsModel!.locale!);
    medium = await mTx.translate('medium', settingsModel!.locale!);
    large = await mTx.translate('large', settingsModel!.locale!);
    selectLanguage =
        await mTx.translate('selectLanguage', settingsModel!.locale!);
    hint = await mTx.translate('selectLanguage', settingsModel!.locale!);
    settingsChanged =
        await mTx.translate('settingsChanged', settingsModel!.locale!);

    translatedLanguage =
        await mTx.translate(settingsModel!.locale!, settingsModel!.locale!);

    setState(() {});
  }

  // void _checkLocaleChangeAndExit() async {
  //   pp('$mm if locale changed - display dialog with shutDown button');
  //   var sett = await prefsOGx.getSettings();
  //   String? message, stop;
  //   if (sett != null) {
  //     message = await mTx.translate('stopMessage', sett.locale!);
  //     stop = await mTx.translate('stop', sett.locale!);
  //     if (sett.locale == oldSettingsModel!.locale!) {
  //       if (mounted) {
  //         pp('Pooping out ... will not display dialog');
  //         // Navigator.of(context).pop();
  //       }
  //     } else {
  //       if (mounted) {
  //         pp('$mm is mounted, so show dialog');
  //         showDialog(
  //           context: context,
  //           barrierDismissible: false,
  //           builder: (_) => Padding(
  //             padding: const EdgeInsets.all(16.0),
  //             child: Center(
  //               child: SizedBox(
  //                 width: 400,
  //                 height: 400,
  //                 child: Column(
  //                   children: [
  //                     Text(message == null
  //                         ? 'If you have changed the language of the app please press stop'
  //                             ' and then then restart the app to use the new language'
  //                         : message!),
  //                     const SizedBox(
  //                       height: 64,
  //                     ),
  //                     ElevatedButton(
  //                         onPressed: () {
  //                           SystemChannels.platform
  //                               .invokeMethod('SystemNavigator.pop');
  //                         },
  //                         child: Padding(
  //                           padding: const EdgeInsets.all(8.0),
  //                           child: Text(stop == null ? 'Stop' : stop!),
  //                         )),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //         );
  //       }
  //     }
  //   }
  // }

  void onSelected(Project p1) {
    setState(() {
      selectedProject = p1;
    });
  }

  void _setExistingSettings() async {
    if (settingsModel != null) {
      if (settingsModel!.activityStreamHours == null ||
          settingsModel!.activityStreamHours == 0) {
        settingsModel!.activityStreamHours = 24;
        await prefsOGx.saveSettings(settingsModel!);
      }
    }
    settingsModel ??= SettingsModel(
        distanceFromProject: 500,
        photoSize: 1,
        maxVideoLengthInSeconds: 20,
        maxAudioLengthInMinutes: 30,
        themeIndex: 0,
        settingsId: const Uuid().v4(),
        created: DateTime.now().toUtc().toIso8601String(),
        organizationId: user!.organizationId!,
        projectId: null,
        activityStreamHours: 24,
        numberOfDays: 7,
        locale: 'en');

    currentThemeIndex = settingsModel!.themeIndex!;
    distController.text = '${settingsModel?.distanceFromProject}';
    videoController.text = '${settingsModel?.maxVideoLengthInSeconds}';
    audioController.text = '${settingsModel?.maxAudioLengthInMinutes}';
    activityController.text = '${settingsModel?.activityStreamHours}';
    daysController.text = '${settingsModel?.numberOfDays}';

    if (settingsModel?.locale != null) {
      Locale newLocale = Locale(settingsModel!.locale!);
      selectedLocale = newLocale;
      final m = LocaleAndTheme(
          themeIndex: settingsModel!.themeIndex!, locale: newLocale);
      themeBloc.changeToLocale(m.locale.toString());
    }

    if (settingsModel?.photoSize == 0) {
      photoSize = 0;
      groupValue = 0;
    }
    if (settingsModel?.photoSize == 1) {
      photoSize = 1;
      groupValue = 1;
    }
    if (settingsModel?.photoSize == 2) {
      photoSize = 0;
      groupValue = 2;
    }

    setState(() {});
  }

  void _writeSettingsToDatabase() async {
    if (user == null) {
      pp('\n\n\n\n🌀🌀🌀🌀 user is null, what the fuck?\n');
      return;
    }
    if (_formKey.currentState!.validate()) {
      var date = DateTime.now().toUtc().toIso8601String();
      pp('$mm 🔵🔵🔵 writing settings to remote database ... '
          'currentThemeIndex: $currentThemeIndex 🔆🔆🔆 and date: $date} 🔆 stream hours: ${activityController.value.text}');
      var len = int.parse(videoController.value.text);
      if (len > 20) {
        showToast(
            message: 'The maximum video length should be 20 seconds or less',
            context: context);
        return;
      }
      if (len < 5) {
        showToast(
            message:
                'The minimum video length should not be less than 5 seconds',
            context: context);
        return;
      }
      if (selectedLocale == null) {
        showToast(message: 'Please select language', context: context);
        return;
      }
      settingsModel = SettingsModel(
        locale: selectedLocale.toString(),
        distanceFromProject: int.parse(distController.value.text),
        photoSize: groupValue,
        maxVideoLengthInSeconds: int.parse(videoController.value.text),
        maxAudioLengthInMinutes: int.parse(audioController.value.text),
        numberOfDays: int.parse(daysController.value.text),
        themeIndex: currentThemeIndex,
        settingsId: const Uuid().v4(),
        created: date,
        organizationId: user!.organizationId,
        projectId: selectedProject == null ? null : selectedProject!.projectId,
        activityStreamHours: int.parse(activityController.value.text),
      );

      pp('🌸 🌸 🌸 🌸 🌸 ... about to save settings: ${settingsModel!.toJson()}');

      await prefsOGx.saveSettings(settingsModel!);
      Locale newLocale = Locale(settingsModel!.locale!);
      final m = LocaleAndTheme(
          themeIndex: settingsModel!.themeIndex!, locale: newLocale);
      themeBloc.themeStreamController.sink.add(m);

      await cacheManager.addSettings(settings: settingsModel!);
      await _sendSettings();
    }
    if (mounted) {
      showToast(
          backgroundColor: Theme.of(context).primaryColor,
          message: settingsChanged == null
              ? 'Settings have been saved'
              : settingsChanged!,
          context: context);

      await Future.delayed(const Duration(milliseconds: 10));
      //_checkLocaleChangeAndExit();
    }
  }

  Future _sendSettings() async {
    pp('\n\n$mm sendSettings: 🔵🔵🔵 settings sent to database: ${settingsModel!.toJson()}');
    setState(() {
      busyWritingToDB = true;
    });
    try {
      var s = await DataAPI.addSettings(settingsModel!);
      pp('\n\n🔵🔵🔵 settings sent to database: ${s.toJson()}');

      await prefsOGx.saveSettings(s);
      organizationBloc.settingsController.sink.add(s);
      themeBloc.changeToTheme(s.themeIndex!);
      //todo - do something with new settings ....
      dataRefresher.manageRefresh(
          numberOfDays: null,
          organizationId: s.organizationId,
          projectId: null,
          userId: null);
    } catch (e) {
      pp(e);
      if (mounted) {
        showToast(
            duration: const Duration(seconds: 5),
            message: '$e',
            context: context);
      }
    }

    setState(() {
      busyWritingToDB = false;
    });
  }

  void _handlePhotoSizeValueChange(Object? value) {
    pp('🌸 🌸 🌸 🌸 🌸 _handlePhotoSizeValueChange: 🌸 $value');
    groupValue = value as int;
    setState(() {
      switch (value) {
        case 0:
          photoSize = 0;
          break;
        case 1:
          photoSize = 1;
          break;
        case 2:
          photoSize = 2;
          break;
      }
    });
  }

  Locale? selectedLocale;
  String? selectSizePhotos, settingsChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: getRoundedBorder(radius: 16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.all(widget.padding),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          currentThemeIndex++;
                          if (currentThemeIndex >= themeBloc.getThemeCount()) {
                            currentThemeIndex = 0;
                          }
                          themeBloc.changeToTheme(currentThemeIndex);
                          if (settingsModel != null) {
                            settingsModel!.themeIndex = currentThemeIndex;
                          }
                          setState(() {});
                        },
                        child: Card(
                          elevation: 8,
                          shape: getRoundedBorder(radius: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              height: 48,
                              width: 240,
                              child: Container(
                                color: Theme.of(context).primaryColor,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      tapForColorScheme == null
                                          ? 'Tap Me for Colour Scheme'
                                          : tapForColorScheme!,
                                      style: myTextStyleSmall(context),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      busyWritingToDB
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                backgroundColor: Colors.pink,
                              ),
                            )
                          : const SizedBox(),
                      const SizedBox(
                        width: 24,
                      ),
                      IconButton(
                          onPressed: () {
                            _writeSettingsToDatabase();
                          },
                          icon: Icon(
                            Icons.check,
                            size: 36,
                            color: Theme.of(context).primaryColor,
                          )),
                    ],
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Text(
                    fieldMonitorInstruction == null
                        ? 'instruction'
                        : fieldMonitorInstruction!,
                    style: myTextStyleSmall(context),
                  ),
                  const SizedBox(
                    height: 36,
                  ),
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      controller: distController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return maximumMonitoringDistance == null
                              ? 'Please enter maximum distance from project in metres'
                              : maximumMonitoringDistance!;
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: maximumMonitoringDistance == null
                            ? 'Enter maximum distance from project in metres'
                            : maximumMonitoringDistance!,
                        label: Text(
                          maximumMonitoringDistance == null
                              ? 'sentence'
                              : maximumMonitoringDistance!,
                          style: myTextStyleSmall(context),
                        ),
                        hintStyle: myTextStyleSmall(context),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      controller: videoController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return maximumVideoLength == null
                              ? 'Please enter maximum video length in seconds'
                              : maximumVideoLength!;
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: maximumVideoLength == null
                            ? 'Enter maximum video length in seconds'
                            : maximumVideoLength!,
                        label: Text(
                          maximumVideoLength == null
                              ? 'Maximum Video Length in Seconds'
                              : maximumVideoLength!,
                          style: myTextStyleSmall(context),
                        ),
                        hintStyle: myTextStyleSmall(context),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      controller: audioController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return maximumAudioLength == null
                              ? 'Please enter maximum audio length in minutes'
                              : maximumVideoLength!;
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: maximumAudioLength == null
                            ? 'Enter maximum audio length in minutes'
                            : maximumAudioLength!,
                        label: Text(
                          maximumAudioLength == null
                              ? 'Maximum Audio Length in Minutes'
                              : maximumAudioLength!,
                          style: myTextStyleSmall(context),
                        ),
                        hintStyle: myTextStyleSmall(context),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      controller: activityController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return activityStreamHours == null
                              ? 'Please enter the number of hours your activity stream must show'
                              : activityStreamHours!;
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: activityStreamHours == null
                            ? 'Enter activity stream length in hours'
                            : activityStreamHours!,
                        label: Text(
                          activityStreamHours == null
                              ? 'Activity Stream Audio Length in Hours'
                              : activityStreamHours!,
                          style: myTextStyleSmall(context),
                        ),
                        hintStyle: myTextStyleSmall(context),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      controller: daysController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return numberOfDays == null
                              ? 'Please enter the number of days your dashboard must show'
                              : numberOfDays!;
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Enter the number of days your dashboard must show',
                        label: Text(
                          numberOfDaysForDashboardData == null
                              ? 'Number of Dashboard Days'
                              : numberOfDaysForDashboardData!,
                          style: myTextStyleSmall(context),
                        ),
                        hintStyle: myTextStyleSmall(context),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        selectSizePhotos == null
                            ? 'Select size of photos'
                            : selectSizePhotos!,
                        style: myTextStyleSmall(context),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Radio(
                        value: 0,
                        groupValue: groupValue,
                        onChanged: _handlePhotoSizeValueChange,
                      ),
                      Text(
                        small == null ? 'Small' : small!,
                        style: myTextStyleTiny(context),
                      ),
                      Radio(
                        value: 1,
                        groupValue: groupValue,
                        onChanged: _handlePhotoSizeValueChange,
                      ),
                      Text(medium == null ? 'Medium' : medium!,
                          style: myTextStyleTiny(context)),
                      Radio(
                        value: 2,
                        groupValue: groupValue,
                        onChanged: _handlePhotoSizeValueChange,
                      ),
                      Text(large == null ? 'Large' : large!,
                          style: myTextStyleTiny(context)),
                    ],
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  SizedBox(
                    width: 400,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        LocaleChooser(
                          onSelected: (locale, language) {
                            _handleLocaleChange(locale, language);
                          },
                          hint: hint == null ? 'Select Language' : hint!,
                        ),
                        const SizedBox(
                          width: 32,
                        ),
                        translatedLanguage == null
                            ? const Text('No language')
                            : Text(
                                translatedLanguage!,
                                style:
                                    myTextStyleMediumBoldPrimaryColor(context),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  busyWritingToDB
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            backgroundColor: Colors.pink,
                          ),
                        )
                      : const SizedBox(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? translatedLanguage;
  void _setLanguage() async {
    if (settingsModel != null) {
      translatedLanguage =
          await mTx.translate(settingsModel!.locale!, settingsModel!.locale!);
    }
  }

  void _handleLocaleChange(Locale locale, String translatedLanguage) async {
    pp('$mm onLocaleChange ... going to ${locale.languageCode}');
    mTx.translate('settings', locale.toLanguageTag());
    var settings = await prefsOGx.getSettings();
    if (settings != null) {
      settings.locale = locale.languageCode;
      await prefsOGx.saveSettings(settings);
      organizationBloc.settingsController.sink.add(settings);
      _getSettings();
      themeBloc.changeToLocale(locale.languageCode);
    }
    setState(() {
      selectedLocale = locale;
      this.translatedLanguage = translatedLanguage;
    });
    _setTitles();
    widget.onLocaleChanged(locale.languageCode);
  }
}

class LocaleChooser extends StatefulWidget {
  const LocaleChooser({Key? key, required this.onSelected, required this.hint})
      : super(key: key);

  final Function(Locale, String) onSelected;
  final String hint;

  @override
  State<LocaleChooser> createState() => LocaleChooserState();
}

class LocaleChooserState extends State<LocaleChooser> {
  String? english,
      french,
      portuguese,
      ingala,
      sotho,
      spanish,
      shona,
      swahili,
      tsonga,
      xhosa,
      zulu,
      yoruba,
      afrikaans,
      german,
      chinese;

  SettingsModel? settingsModel;
  @override
  void initState() {
    super.initState();
    setTexts();
  }

  Future setTexts() async {
    settingsModel = await prefsOGx.getSettings();
    if (settingsModel != null) {
      english = await mTx.translate('en', settingsModel!.locale!);
      afrikaans = 'Afrikaans';
      french = await mTx.translate('fr', settingsModel!.locale!);
      portuguese = await mTx.translate('pt', settingsModel!.locale!);
      ingala = await mTx.translate('ig', settingsModel!.locale!);
      sotho = await mTx.translate('st', settingsModel!.locale!);
      spanish = await mTx.translate('es', settingsModel!.locale!);
      swahili = await mTx.translate('sw', settingsModel!.locale!);
      tsonga = await mTx.translate('ts', settingsModel!.locale!);
      xhosa = await mTx.translate('xh', settingsModel!.locale!);
      zulu = await mTx.translate('zu', settingsModel!.locale!);
      yoruba = await mTx.translate('yo', settingsModel!.locale!);

      german = await mTx.translate('de', settingsModel!.locale!);
      chinese = await mTx.translate('zh', settingsModel!.locale!);
      shona = await mTx.translate('sn', settingsModel!.locale!);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Locale>(
        hint: Text(
          widget.hint,
          style: myTextStyleSmall(context),
        ),
        items: [
          DropdownMenuItem(
            value: const Locale('en'),
            child: Text(english == null ? 'English' : english!,
                style: myTextStyleSmall(context)),
          ),
          DropdownMenuItem(
              value: const Locale('zh'),
              child: Text(chinese == null ? 'Chinese' : chinese!,
                  style: myTextStyleSmall(context))),
          DropdownMenuItem(
              value: const Locale('af'),
              child: Text(afrikaans == null ? 'Afrikaans' : afrikaans!,
                  style: myTextStyleSmall(context))),
          DropdownMenuItem(
              value: const Locale('fr'),
              child: Text(french == null ? 'French' : french!,
                  style: myTextStyleSmall(context))),
          DropdownMenuItem(
              value: const Locale('de'),
              child: Text(german == null ? 'German' : german!,
                  style: myTextStyleSmall(context))),
          DropdownMenuItem(
              value: const Locale('pt'),
              child: Text(portuguese == null ? 'Portuguese' : portuguese!,
                  style: myTextStyleSmall(context))),
          DropdownMenuItem(
              value: const Locale('ig'),
              child: Text(ingala == null ? 'Ingala' : ingala!,
                  style: myTextStyleSmall(context))),
          DropdownMenuItem(
              value: const Locale('st'),
              child: Text(sotho == null ? 'Sotho' : sotho!,
                  style: myTextStyleSmall(context))),
          DropdownMenuItem(
              value: const Locale('es'),
              child: Text(spanish == null ? 'Spanish' : spanish!,
                  style: myTextStyleSmall(context))),
          DropdownMenuItem(
              value: const Locale('sn'),
              child: Text(shona == null ? 'Shona' : shona!,
                  style: myTextStyleSmall(context))),
          DropdownMenuItem(
              value: const Locale('sw'),
              child: Text(swahili == null ? 'Swahili' : swahili!,
                  style: myTextStyleSmall(context))),
          DropdownMenuItem(
              value: const Locale('ts'),
              child: Text(tsonga == null ? 'Tsonga' : tsonga!,
                  style: myTextStyleSmall(context))),
          DropdownMenuItem(
              value: const Locale('xh'),
              child: Text(xhosa == null ? 'Xhosa' : xhosa!,
                  style: myTextStyleSmall(context))),
          DropdownMenuItem(
              value: const Locale('yo'),
              child: Text(yoruba == null ? 'Yoruba' : yoruba!,
                  style: myTextStyleSmall(context))),
          DropdownMenuItem(
              value: const Locale('zu'),
              child: Text(zulu == null ? 'Zulu' : zulu!,
                  style: myTextStyleSmall(context))),
        ],
        onChanged: onChanged);
  }

  void onChanged(Locale? locale) async {
    pp('LocaleChooser 🌀🌀🌀🌀:onChanged: selected locale: '
        '${locale.toString()}');
    settingsModel!.locale = locale!.languageCode;
    await prefsOGx.saveSettings(settingsModel!);
    organizationBloc.settingsController.sink.add(settingsModel!);
    var language = 'English';
    switch (locale!.languageCode) {
      case 'eng':
        language = english!;
        break;
      case 'af':
        language = afrikaans!;
        break;
      case 'fr':
        language = french!;
        break;
      case 'pt':
        language = portuguese!;
        break;
      case 'ig':
        language = ingala!;
        break;
      case 'es':
        language = spanish!;
        break;
      case 'st':
        language = sotho!;
        break;
      case 'sw':
        language = swahili!;
        break;
      case 'xh':
        language = xhosa!;
        break;
      case 'zu':
        language = zulu!;
        break;
      case 'yo':
        language = yoruba!;
        break;
      case 'de':
        language = german!;
        break;
      case 'zh':
        language = chinese!;
        break;
    }
    await setTexts();
    widget.onSelected(locale, language);
  }
}

class GeoPlaceHolder extends StatelessWidget {
  const GeoPlaceHolder({Key? key, required this.width}) : super(key: key);
  final double width;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: Theme.of(context).primaryColor,
      child: Center(
        child: Card(
          elevation: 4,
          shape: getRoundedBorder(radius: 16),
          child: SizedBox(
            height: 140,
            width: 300,
            child: Column(
              children: [
                const SizedBox(
                  height: 28,
                ),
                Text(
                  'Geo PlaceHolder',
                  style: myNumberStyleLarge(context),
                ),
                const SizedBox(
                  height: 24,
                ),
                Text(
                  'Geo content coming soon!',
                  style: myTextStyleMedium(context),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
