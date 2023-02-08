import 'package:flutter/material.dart';
import 'package:geo_monitor/library/ui/settings/settings_mobile.dart';
import 'package:responsive_builder/responsive_builder.dart';

import 'settings_tablet_landscape.dart';
import 'settings_tablet_portrait.dart';



class SettingsMain extends StatelessWidget {
  const SettingsMain({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: const SettingsMobile(
      ),
      tablet: OrientationLayoutBuilder(
        portrait: (context) {
          return const SettingsTabletPortrait();
        },
        landscape: (context){
          return const SettingsTabletLandscape();
        },
      ),
    );;
  }
}
