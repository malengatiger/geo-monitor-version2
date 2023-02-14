import 'package:flutter/material.dart';
import 'package:geo_monitor/library/ui/settings/settings_form.dart';
import 'package:uuid/uuid.dart';

import '../../api/data_api.dart';
import '../../api/prefs_og.dart';
import '../../bloc/theme_bloc.dart';
import '../../data/project.dart';
import '../../data/settings_model.dart';
import '../../data/user.dart';
import '../../functions.dart';
import '../../generic_functions.dart';
import '../../hive_util.dart';
import '../../project_selector.dart';

class SettingsTabletPortrait extends StatefulWidget {
  const SettingsTabletPortrait({Key? key}) : super(key: key);

  @override
  SettingsTabletPortraitState createState() => SettingsTabletPortraitState();
}

class SettingsTabletPortraitState extends State<SettingsTabletPortrait>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  SettingsModel? settingsModel;
  User? user;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this);
    super.initState();
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
        // leading: const SizedBox(),
        title: Text(
          'Geo Settings',
          style: myTextStyleLarge(context),
        ),
      ),
      body: busy
          ? Center(
              child: Card(
                elevation: 8,
                shape: getRoundedBorder(radius: 8),
                child: const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      backgroundColor: Colors.pink,
                    )),
              ),
            )
          : const Padding(
              padding: EdgeInsets.all(72.0),
              child: SettingsForm(padding: 48,),
            ),
    ));
  }
}
