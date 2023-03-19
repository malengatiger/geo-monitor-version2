import 'package:flutter/material.dart';
import 'package:geo_monitor/library/functions.dart';
import 'package:music_visualizer/music_visualizer.dart';

class TestVisualizer extends StatefulWidget {
  const TestVisualizer({Key? key}) : super(key: key);

  @override
  TestVisualizerState createState() => TestVisualizerState();
}

class TestVisualizerState extends State<TestVisualizer> {
  final List<Color> colors = [
    Colors.pink[500]!,
    Colors.pink[900]!,
    Colors.blue[900]!,
    Colors.brown[900]!
  ];

  final List<int> duration = [900, 700, 600, 800, 500, 1200];
  var show = false;
  @override
  void initState() {
    super.initState();
    showVisualizer();
  }

  Future<void> showVisualizer() async {
    await Future.delayed(const Duration(seconds: 5));
    setState(() {
      show = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(width: 300, height: 260,
        child: Card(
          shape: getRoundedBorder(radius: 16),
          color: Theme.of(context).primaryColor,
          elevation: 8,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(28.0),
                child: Text(
                  'Checking Visualizer',
                  style: myTextStyleLargerPrimaryColor(context),
                ),
              ),
              show
                  ? MusicVisualizer(
                      colors: colors, duration: duration,
                  barCount: 100)
                  : SizedBox(
                      width: 100,
                      height: 160,
                      child: Text(
                        'We Fucked! ... for now!',
                        style: myTextStyleLarge(context),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
