import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';
import 'package:geo_monitor/library/data/settings_model.dart';
import 'package:geo_monitor/library/ui/settings/settings_form.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/translation_handler.dart';
import '../../api/prefs_og.dart';
import '../../bloc/theme_bloc.dart';
import '../../data/project.dart';
import '../../data/user.dart';
import '../../functions.dart';

class SettingsFormMonitor extends StatefulWidget {
  const SettingsFormMonitor(
      {Key? key, required this.padding, required this.onLocaleChanged})
      : super(key: key);
  final double padding;
  final Function(String locale) onLocaleChanged;

  @override
  State<SettingsFormMonitor> createState() => SettingsFormMonitorState();
}

class SettingsFormMonitorState extends State<SettingsFormMonitor> {
  final _formKey = GlobalKey<FormState>();
  final mm = '🥨🥨🥨🥨🥨 SettingsFormMonitor: ';
  User? user;
  var orgSettings = <SettingsModel>[];
  Project? selectedProject;
  SettingsModel? settingsModel;
  SettingsModel? oldSettingsModel;

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
    _setTexts();
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
      large, maxVideoLessThan,maxAudioLessThan,
      numberOfDaysForDashboardData,
      selectLanguage,
      title,
      hint;

  void _setTexts() async {
    title =
        await mTx.translate('settings', settingsModel!.locale!);
    maxVideoLessThan =
    await mTx.translate('maxVideoLessThan', settingsModel!.locale!);
    maxAudioLessThan =
    await mTx.translate('maxAudioLessThan', settingsModel!.locale!);
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


  Locale? selectedLocale;
  String? selectSizePhotos, settingsChanged;
  bool showColorPicker = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          elevation: 4,
          shape: getRoundedBorder(radius: 16),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
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
                              setState(() {
                                showColorPicker = true;
                              });
                            },
                            child: Card(
                              elevation: 8,
                              shape: getRoundedBorder(radius: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
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
                            width: 8,
                          ),

                        ],
                      ),
                      const SizedBox(
                        height: 48,
                      ),
                      Text(
                        fieldMonitorInstruction == null
                            ? 'instruction'
                            : fieldMonitorInstruction!,
                        style: myTextStyleSmall(context),
                      ),
                      const SizedBox(
                        height: 48,
                      ),
                      SizedBox(
                        width: 400,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 48,
                              child: Text(settingsModel == null
                                  ? '0'
                                  : '${settingsModel!.distanceFromProject!}', style: myNumberStyleMediumPrimaryColor(context),),
                            ),
                            Expanded(
                              child: Text(maximumMonitoringDistance == null
                                  ? ''
                                  : maximumMonitoringDistance!, style: myTextStyleSmall(context),),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      SizedBox(
                        width: 400,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 48,
                              child: Text(settingsModel == null
                                  ? '0'
                                  : '${settingsModel!.maxVideoLengthInSeconds!}',style: myNumberStyleMediumPrimaryColor(context),),
                            ),
                            Expanded(
                              child: Text(maximumVideoLength == null
                                  ? ''
                                  : maximumVideoLength!, style: myTextStyleSmall(context),),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      SizedBox(
                        width: 400,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 48,
                              child: Text(settingsModel == null
                                  ? '0'
                                  : '${settingsModel!.maxAudioLengthInMinutes!}', style: myNumberStyleMediumPrimaryColor(context),),
                            ),
                            Expanded(
                              child: Text(maximumAudioLength == null
                                  ? ''
                                  : maximumAudioLength!, style: myTextStyleSmall(context),),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      SizedBox(
                        width: 400,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 48,
                              child: Text(settingsModel == null
                                  ? '0'
                                  : '${settingsModel!.activityStreamHours!}',style: myNumberStyleMediumPrimaryColor(context),),
                            ),
                            Expanded(
                              child: Text(activityStreamHours == null
                                  ? ''
                                  : activityStreamHours!,style: myTextStyleSmall(context),),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      SizedBox(
                        width: 400,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 48,
                              child: Text(settingsModel == null
                                  ? '0'
                                  : '${settingsModel!.numberOfDays!}',style: myNumberStyleMediumPrimaryColor(context),),
                            ),
                            Expanded(
                              child: Text(numberOfDaysForDashboardData == null
                                  ? ''
                                  : numberOfDaysForDashboardData!, style: myTextStyleSmall(context),),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 60,
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

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        showColorPicker? Positioned(
          top: 20, left: 12, right: 12,
          child: SizedBox(height: 300,
            child: ColorSchemePicker(onColorScheme: (index) {
              currentThemeIndex = index;
              themeBloc.changeToTheme(currentThemeIndex);
              if (settingsModel != null) {
                settingsModel!.themeIndex = currentThemeIndex;
                prefsOGx.saveSettings(settingsModel!);
              }
              setState(() {
                showColorPicker = false;
              });
            }, crossAxisCount: 6, itemWidth: 28, elevation: 16,),
          ),
        ): const SizedBox(),
      ],
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
    _setTexts();

    widget.onLocaleChanged(locale.languageCode);
  }
}

