import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:geo_monitor/library/functions.dart';

class AppSettings extends StatefulWidget {
  const AppSettings({Key? key}) : super(key: key);

  @override
  AppSettingsState createState() => AppSettingsState();
}

class AppSettingsState extends State<AppSettings>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  @override
  void initState() {
    animationController = AnimationController(vsync: this);
    super.initState();
  }

  Widget _buildPreferenceSwitch(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        const Text('Shared Pref'),
        Switch(
            activeColor: Theme.of(context).primaryColor,
            value: true,
            onChanged: (newVal) {
              if (kIsWeb) {
                return;
              }
              setState(() {});
            }),
        const Text('SharedPrefs Storage'),
      ],
    );
  }


  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                Text(
                  'GeoMonitor Settings',
                  style: myTextStyleLarge(context),
                ),
                const SizedBox(
                  height: 20,
                ),
                Expanded(child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Card(
                      shape: getRoundedBorder(radius: 16),
                      child: Column(
                        children: [
                          SettingsRow(title: 'Distance',
                              icon: const Icon(Icons.location_on),
                              widget: NumberPicker(multiple: 100,
                                  onSelected: onDistanceSelected)),
                          SettingsRow(title: 'Size', icon: const Icon(Icons.camera_alt
                          ), widget: ImageSizePicker(onSelectedIndex: _onSelectedImageIndex,))
                        ],
                      ),
                    ),
                  ),
                ))
              ],
            ),
          ),
        ],
      ),
    ));
  }

  onDistanceSelected(int p1) {
    Settings.setValue('monitorDistance', p1);
  }

  _onSelectedImageIndex(int p1) {
    Settings.setValue('imageSizeIndex', p1);
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({Key? key, required this.title,
    required this.icon, required this.widget}) : super(key: key);
  final String title;
  final Icon icon;
  final Widget widget;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(title),),
        const SizedBox(width: 20,),
        widget,
      ],
    );
  }
}

class NumberPicker extends StatelessWidget {
  const NumberPicker({Key? key, required this.multiple, required this.onSelected}) : super(key: key);
  final int multiple;
  final Function(int) onSelected;
  @override
  Widget build(BuildContext context) {
    var items = <DropdownMenuItem>[];
    for (var i = 0; i < 10; i++) {
      items.add(DropdownMenuItem<int>(
          value: multiple * (i + 1),
          child: Text('${multiple * (i + 1)}', style: myTextStyleSmall(context),)));
    }

    return DropdownButton(
        hint: const Text('Distance'),
        items: items, onChanged: onChanged);
  }

  void onChanged(value) {
    onSelected(value);
  }
}

class ImageSizePicker extends StatelessWidget {
  const ImageSizePicker({Key? key, required this.onSelectedIndex}) : super(key: key);
  final Function(int) onSelectedIndex;
  @override
  Widget build(BuildContext context) {
    var items = <DropdownMenuItem>[];
    var cnt = 0;
    for (var value1 in imageSizes) {
      items.add(DropdownMenuItem<int>(
          value: cnt,
          child: Text(value1, style: myTextStyleSmall(context))));
      cnt++;
    }
    return DropdownButton(
      hint: const Text('Size'),
      items: items, onChanged: (value) {
      onSelectedIndex(value);
    },);
  }
}

final imageSizes = [
  "480 x 640",
  '600 x 800',
];



