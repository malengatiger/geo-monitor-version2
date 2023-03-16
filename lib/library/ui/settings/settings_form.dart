import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  const SettingsForm({Key? key, required this.padding}) : super(key: key);
  final double padding;
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
      selectLanguage,
      hint;

  void _setTitles() async {
    fieldMonitorInstruction =
        await mTx.translate('fieldMonitorInstruction', settingsModel!.locale!);
    maximumMonitoringDistance =
        await mTx.translate('maximumMonitoringDistance', settingsModel!.locale!);
    maximumVideoLength =
        await mTx.translate('maximumVideoLength', settingsModel!.locale!);
    maximumAudioLength =
        await mTx.translate('maximumAudioLength', settingsModel!.locale!);
    activityStreamHours =
        await mTx.translate('activityStreamHours', settingsModel!.locale!);

    pleaseSelectCountry =
        await mTx.translate('pleaseSelectCountry', settingsModel!.locale!);
    tapForColorScheme =
        await mTx.translate('tapForColorScheme', settingsModel!.locale!);
    numberOfDays = await mTx.translate('numberOfDays', settingsModel!.locale!);
    settings = await mTx.translate('settings', settingsModel!.locale!);
    small = await mTx.translate('small', settingsModel!.locale!);
    medium = await mTx.translate('medium', settingsModel!.locale!);
    large = await mTx.translate('large', settingsModel!.locale!);
    selectLanguage = await mTx.translate('selectLanguage', settingsModel!.locale!);
    hint = await mTx.translate('selectLanguage', settingsModel!.locale!);

    setState(() {});
  }

  void _checkLocaleChangeAndExit() async {
    pp('$mm if locale changed - display dialog with shutDown button');
    var sett = await prefsOGx.getSettings();
    String? message, stop;
    if (sett != null) {
      message = await mTx.translate('stopMessage', sett.locale!);
      stop = await mTx.translate('stop', sett.locale!);
      if (sett.locale == oldSettingsModel!.locale!) {
        if (mounted) {
          pp('Pooping out ... will not display dialog');
          // Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          pp('$mm is mounted, so show dialog');
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: SizedBox(
                  width: 400,
                  height: 400,
                  child: Column(
                    children: [
                      Text(message == null
                          ? 'If you have changed the language of the app please press stop'
                              ' and then then restart the app to use the new language'
                          : message!),
                      const SizedBox(
                        height: 64,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            SystemChannels.platform
                                .invokeMethod('SystemNavigator.pop');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(stop == null ? 'Stop' : stop!),
                          )),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }
    }
  }

  // var instruction = S.of(context).fieldMonitorInstruction;
  // var maxDistance = S.of(context).maximumMonitoringDistance;
  // pp('$mm instruction: $instruction');
  // pp('$mm maxDistance: $maxDistance');

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
          message: 'Settings have been saved',
          context: context);

      await Future.delayed(const Duration(milliseconds: 200));
      _checkLocaleChangeAndExit();
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

  @override
  Widget build(BuildContext context) {
    var localeText = 'English';
    if (selectedLocale != null) {
      switch (selectedLocale.toString()) {
        case 'en':
          localeText = 'English';
          break;
        case 'af':
          localeText = 'Afrikaans';
          break;
        case 'fr':
          localeText = 'French';
          break;
        case 'pt':
          localeText = 'Portuguese';
          break;
        case 'es':
          localeText = 'Spanish';
          break;
        case 'zu':
          localeText = 'Zulu';
          break;
        case 'yo':
          localeText = 'Yoruba';
          break;
        case 'ts':
          localeText = 'Tsonga';
          break;
        case 'xh':
          localeText = 'Xhosa';
          break;

        case 'st':
          localeText = 'Sotho';
          break;
        case 'ig':
          localeText = 'Ingala';
          break;
        case 'sw':
          localeText = 'Swahili';
          break;
      }
    }

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
                              height: 32,
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
                            size: 32,
                            color: Theme.of(context).primaryColor,
                          )),
                    ],
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    fieldMonitorInstruction == null
                        ? 'instruction'
                        : fieldMonitorInstruction!,
                    style: myTextStyleSmall(context),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  SizedBox(
                    width: 260,
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
                    width: 260,
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
                    width: 260,
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
                    width: 260,
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
                    width: 260,
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
                          'Number of Dashboard Days',
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
                        'Select size of photos',
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
                        style: myTextStyleSmall(context),
                      ),
                      Radio(
                        value: 1,
                        groupValue: groupValue,
                        onChanged: _handlePhotoSizeValueChange,
                      ),
                      Text(medium == null ? 'Medium' : medium!,
                          style: myTextStyleSmall(context)),
                      Radio(
                        value: 2,
                        groupValue: groupValue,
                        onChanged: _handlePhotoSizeValueChange,
                      ),
                      Text(large == null ? 'Large' : large!,
                          style: myTextStyleSmall(context)),
                    ],
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          selectLanguage == null
                              ? 'Select language '
                              : selectLanguage!,
                          style: myTextStyleSmall(context),
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      selectedLocale == null
                          ? const Text('No language')
                          : Text(localeText),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      LocaleChooser(
                        onSelected: (locale) {
                          _handleLocaleChange(locale);
                        },
                        hint: hint == null ? 'Select Country' : hint!,
                      ),
                    ],
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

  void _handleLocaleChange(Locale locale) async {
    pp('$mm onLocaleChange ... going to ${locale.languageCode}');
    mTx.translate('settings',locale.toLanguageTag());
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
    });
  }
}

class LocaleChooser extends StatelessWidget {
  const LocaleChooser({Key? key, required this.onSelected, required this.hint})
      : super(key: key);

  final Function(Locale) onSelected;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Locale>(
        hint: Text(hint),
        items: const [
          DropdownMenuItem(value: Locale('en'), child: Text('English')),
          DropdownMenuItem(value: Locale('fr'), child: Text('French')),
          DropdownMenuItem(value: Locale('pt'), child: Text('Portuguese')),
          DropdownMenuItem(value: Locale('ig'), child: Text('Ingala')),
          DropdownMenuItem(value: Locale('nso'), child: Text('Sepedi')),
          DropdownMenuItem(value: Locale('st'), child: Text('Sotho')),
          DropdownMenuItem(value: Locale('es'), child: Text('Spanish')),
          DropdownMenuItem(value: Locale('sw'), child: Text('Swahili')),
          DropdownMenuItem(value: Locale('ts'), child: Text('Tsonga')),
          DropdownMenuItem(value: Locale('xh'), child: Text('Xhosa')),
          DropdownMenuItem(value: Locale('zu'), child: Text('Zulu')),
          DropdownMenuItem(value: Locale('yo'), child: Text('Yoruba')),
        ],
        onChanged: onChanged);
  }

  void onChanged(Locale? locale) {
    pp('LocaleChooser 🌀🌀🌀🌀:onChanged: selected locale: '
        '${locale.toString()}');
    if (locale != null) {
      onSelected(locale);
    }
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
