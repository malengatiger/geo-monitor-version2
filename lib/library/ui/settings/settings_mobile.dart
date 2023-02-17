import 'package:flutter/material.dart';
import 'package:geo_monitor/library/ui/settings/settings_form.dart';
import 'package:uuid/uuid.dart';

import '../../api/data_api.dart';
import '../../api/prefs_og.dart';
import '../../bloc/theme_bloc.dart';
import '../../cache_manager.dart';
import '../../data/project.dart';
import '../../data/settings_model.dart';
import '../../data/user.dart';
import '../../functions.dart';
import '../../generic_functions.dart';

class SettingsMobile extends StatefulWidget {
  const SettingsMobile({Key? key}) : super(key: key);

  @override
  SettingsMobileState createState() => SettingsMobileState();
}

class SettingsMobileState extends State<SettingsMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  SettingsModel? settingsModel;
  var distController = TextEditingController(text: '100');
  var videoController = TextEditingController(text: '5');
  var audioController = TextEditingController(text: '60');
  var activityController = TextEditingController(text: '12');

  var orgSettings = <SettingsModel>[];

  int photoSize = 0;
  int currentThemeIndex = 0;
  int groupValue = 0;
  bool busy = false;
  bool busyWritingToDB = false;
  Project? selectedProject;
  User? user;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _animationController = AnimationController(vsync: this);
    super.initState();
    _getOrganizationSettings();
    _getSettings();
  }

  void _getOrganizationSettings() async {
    pp('🍎🍎 ............. getting user from prefs ...');
    user = await prefsOGx.getUser();
    pp('🍎🍎 user is here, huh? ${user!.toJson()}');
    setState(() {
      busy = true;
    });
    try {
      orgSettings = await cacheManager.getOrganizationSettings();
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
      busy = false;
    });
  }

  onSelected(Project p1) {
    setState(() {
      selectedProject = p1;
    });
  }

  void _getSettings() async {
    settingsModel = await prefsOGx.getSettings();
    currentThemeIndex = settingsModel!.themeIndex!;
    distController.text = '${settingsModel?.distanceFromProject}';
    videoController.text = '${settingsModel?.maxVideoLengthInMinutes}';
    audioController.text = '${settingsModel?.maxAudioLengthInMinutes}';
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

  void writeSettings() async {
    if (user == null) {
      pp('\n\n\n\n🌀🌀🌀🌀 user is null, what the fuck?\n');
      return;
    }
    if (_formKey.currentState!.validate()) {
      pp('🔵🔵🔵 writing settings to remote database ... currentThemeIndex: $currentThemeIndex');
      var model = SettingsModel(
          distanceFromProject: int.parse(distController.value.text),
          photoSize: groupValue,
          maxVideoLengthInMinutes: int.parse(videoController.value.text),
          maxAudioLengthInMinutes: int.parse(audioController.value.text),
          themeIndex: currentThemeIndex,
          activityStreamHours: int.parse(activityController.text),
          settingsId: const Uuid().v4(),
          created: DateTime.now().toUtc().toIso8601String(),
          organizationId: user!.organizationId,
          projectId:
              selectedProject == null ? null : selectedProject!.projectId);

      pp('🌸 🌸 🌸 🌸 🌸 ... about to save settings: ${model.toJson()}');
      if (model.projectId == null) {
        await prefsOGx.saveSettings(model);
        themeBloc.themeStreamController.sink.add(model.themeIndex!);
      }
      await sendSettings(model);
    }
    if (mounted) {
      showToast(
          backgroundColor: Theme.of(context).primaryColor,
          message: 'Settings have been saved',
          context: context);
      Navigator.of(context).pop();
    }
  }

  Future sendSettings(SettingsModel model) async {
    pp('\n\n🔵🔵🔵 settings sent to database: ${model.toJson()}');
    setState(() {
      busyWritingToDB = true;
    });
    try {
      var s = await DataAPI.addSettings(model);
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
  onProjectSelected(Project p1) {
    setState(() {
      project = p1;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        leading: const SizedBox(),
        title: Text(
          'GeoMonitor Settings',
          style: myTextStyleLarge(context),
        ),
      ),
      body: busy
          ? const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      backgroundColor: Colors.pink,
                    )),
              ),
            )
          : const SettingsForm(padding: 20),
    ));
  }
}
