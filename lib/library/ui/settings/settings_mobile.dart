import 'package:flutter/material.dart';
import 'package:geo_monitor/library/ui/settings/settings_form.dart';

import '../../data/project.dart';
import '../../data/settings_model.dart';
import '../../data/user.dart';
import '../../functions.dart';

class SettingsMobile extends StatefulWidget {
  const SettingsMobile({Key? key}) : super(key: key);

  @override
  SettingsMobileState createState() => SettingsMobileState();
}

class SettingsMobileState extends State<SettingsMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  SettingsModel? settingsModel;
  var distController = TextEditingController(text: '500');
  var videoController = TextEditingController(text: '20');
  var audioController = TextEditingController(text: '60');
  var activityController = TextEditingController(text: '24');

  var orgSettings = <SettingsModel>[];

  int photoSize = 0;
  int currentThemeIndex = 0;
  int groupValue = 0;
  bool busy = false;
  bool busyWritingToDB = false;
  Project? selectedProject;
  User? user;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this);
    super.initState();
    // _getOrganizationSettings();
  }

  // void _getOrganizationSettings() async {
  //   pp('🍎🍎 ............. getting user from prefs ...');
  //   user = await prefsOGx.getUser();
  //   pp('🍎🍎 user is here, huh? ${user!.toJson()}');
  //   setState(() {
  //     busy = true;
  //   });
  //   try {
  //     orgSettings = await cacheManager.getOrganizationSettings();
  //   } catch (e) {
  //     pp(e);
  //     if (mounted) {
  //       showToast(
  //           duration: const Duration(seconds: 5),
  //           message: '$e',
  //           context: context);
  //     }
  //   }
  //   setState(() {
  //     busy = false;
  //   });
  // }

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
