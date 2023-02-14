import 'package:flutter/material.dart';
import 'package:geo_monitor/library/data/settings_model.dart';
import 'package:uuid/uuid.dart';

import '../../api/data_api.dart';
import '../../api/prefs_og.dart';
import '../../bloc/theme_bloc.dart';
import '../../data/project.dart';
import '../../data/user.dart';
import '../../functions.dart';
import '../../generic_functions.dart';
import '../../hive_util.dart';
import '../../project_selector.dart';

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

  var distController = TextEditingController(text: '200');
  var videoController = TextEditingController(text: '5');
  var audioController = TextEditingController(text: '60');
  var activityController = TextEditingController(text: '12');

  int photoSize = 0;
  int currentThemeIndex = 0;
  int groupValue = 0;
  bool busy = false;
  bool busyWritingToDB = false;

  @override
  void initState() {
    super.initState();
    _getSettings();
  }

  void _getSettings() async {
    pp('$mm 🍎🍎 ............. getting user from prefs ...');
    user = await prefsOGx.getUser();
    settingsModel = await prefsOGx.getSettings();
    pp('$mm 🍎🍎 user is here, huh? ${user!.toJson()}');
    _setExistingSettings();
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
        settingsModel!.activityStreamHours = 18;
        await prefsOGx.saveSettings(settingsModel!);
      }
    }
    settingsModel ??= SettingsModel(
        distanceFromProject: 500,
        photoSize: 1,
        maxVideoLengthInMinutes: 2,
        maxAudioLengthInMinutes: 15,
        themeIndex: 0,
        settingsId: const Uuid().v4(),
        created: DateTime.now().toUtc().toIso8601String(),
        organizationId: user!.organizationId!,
        projectId: null,
        activityStreamHours: 12);

    currentThemeIndex = settingsModel!.themeIndex!;
    distController.text = '${settingsModel?.distanceFromProject}';
    videoController.text = '${settingsModel?.maxVideoLengthInMinutes}';
    audioController.text = '${settingsModel?.maxAudioLengthInMinutes}';
    activityController.text = '${settingsModel?.activityStreamHours}';

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
      settingsModel = SettingsModel(
        distanceFromProject: int.parse(distController.value.text),
        photoSize: groupValue,
        maxVideoLengthInMinutes: int.parse(videoController.value.text),
        maxAudioLengthInMinutes: int.parse(audioController.value.text),
        themeIndex: currentThemeIndex,
        settingsId: const Uuid().v4(),
        created: date,
        organizationId: user!.organizationId,
        projectId: selectedProject == null ? null : selectedProject!.projectId,
        activityStreamHours: int.parse(activityController.value.text),
      );

      pp('🌸 🌸 🌸 🌸 🌸 ... about to save settings: ${settingsModel!.toJson()}');
      if (settingsModel!.projectId == null) {
        await prefsOGx.saveSettings(settingsModel!);
        themeBloc.themeStreamController.sink.add(settingsModel!.themeIndex!);
      }
      await cacheManager.addSettings(settings: settingsModel!);
      await _sendSettings();
    }
    if (mounted) {
      showToast(
          backgroundColor: Theme.of(context).primaryColor,
          message: 'Settings have been saved',
          context: context);
      Navigator.of(context).pop();
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

  Project? project;
  void onProjectSelected(Project p1) {
    setState(() {
      project = p1;
    });
  }

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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                  selectedProject == null
                      ? const SizedBox()
                      : InkWell(
                          onTap: () {
                            selectedProject = null;
                            setState(() {});
                          },
                          child: SizedBox(
                            height: 20,
                            child: Text(
                              selectedProject!.name!,
                              style: myTextStyleLargePrimaryColor(context),
                            ),
                          ),
                        ),
                  Text(
                    'The field monitors that are working '
                    'with projects must be within this distance when they are making media.',
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
                          return 'Please enter maximum distance from project in metres';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Enter maximum distance from project in metres',
                        label: Text(
                          'Maximum Monitoring Distance in metres',
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
                          return 'Please enter maximum video length in minutes';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter maximum video length in minutes',
                        label: Text(
                          'Maximum Video Length in Minutes',
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
                          return 'Please enter maximum audio length in minutes';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter maximum audio length in minutes',
                        label: Text(
                          'Maximum Audio Length in Minutes',
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
                          return 'Please enter the number of hours your activity stream must show';
                        }
                        pp('💜💜💜💜 activityController: validated value is $value');
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter activity stream length in hours',
                        label: Text(
                          'Activity Stream Audio Length in Hours',
                          style: myTextStyleSmall(context),
                        ),
                        hintStyle: myTextStyleSmall(context),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Select size of photos',
                        style: myTextStyleMedium(context),
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
                        'Small',
                        style: myTextStyleSmall(context),
                      ),
                      Radio(
                        value: 1,
                        groupValue: groupValue,
                        onChanged: _handlePhotoSizeValueChange,
                      ),
                      Text('Medium', style: myTextStyleSmall(context)),
                      Radio(
                        value: 2,
                        groupValue: groupValue,
                        onChanged: _handlePhotoSizeValueChange,
                      ),
                      Text('Large', style: myTextStyleSmall(context)),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          'Select project only if these setting are for a single project. '
                          'Otherwise, the settings are for the entire organization',
                          style: myTextStyleSmall(context),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ProjectSelector(onSelected: onSelected),
                    ],
                  ),
                  const SizedBox(
                    height: 24,
                  ),
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
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          height: 40,
                          width: 300,
                          child: Container(
                            color: Theme.of(context).primaryColor,
                            child: Center(
                              child: Text(
                                'Tap Me for Colour Scheme',
                                style: myTextStyleSmall(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
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
