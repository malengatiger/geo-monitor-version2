import 'package:flutter/material.dart';
import 'package:geo_monitor/library/ui/settings/settings_form.dart';

import '../../functions.dart';

class SettingsTabletLandscape extends StatefulWidget {
  const SettingsTabletLandscape({Key? key}) : super(key: key);

  @override
  SettingsTabletLandscapeState createState() =>
      SettingsTabletLandscapeState();
}

class SettingsTabletLandscapeState extends State<SettingsTabletLandscape>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    pp('💜💜💜💜 device size; height: ${size.height} width: ${size.width}');
    return SafeArea(child: Scaffold(
      appBar: AppBar(
        title: const Text('Geo Settings'),
      ),
      body: Row(
        children:  [
          SizedBox(width: size.width/2, child:  const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: SettingsForm(padding: 12,),
          ),),
          GeoPlaceHolder(width:size.width/2,),
        ],
      ),
    ));
  }
}
