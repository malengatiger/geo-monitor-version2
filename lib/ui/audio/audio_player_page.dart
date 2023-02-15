import 'package:flutter/material.dart';
import 'package:geo_monitor/library/functions.dart';
import 'package:just_audio/just_audio.dart';

import '../../library/data/audio.dart';

class AudioPlayerPage extends StatefulWidget {
  const AudioPlayerPage(
      {Key? key,
      this.width,
      this.height,
      required this.audio,
      required this.onCloseRequested})
      : super(key: key);

  final double? width, height;
  final Audio audio;
  final Function() onCloseRequested;

  @override
  AudioPlayerPageState createState() => AudioPlayerPageState();
}

class AudioPlayerPageState extends State<AudioPlayerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 3000),
        reverseDuration: const Duration(milliseconds: 2000),
        vsync: this);
    super.initState();
    _play();
  }

  void _play() {
    audioPlayer.setUrl(widget.audio.url!);
    audioPlayer.play();
  }

  @override
  void dispose() {
    _animationController.dispose();
    audioPlayer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localDate =
        DateTime.parse(widget.audio.created!).toLocal().toIso8601String();
    final dt = getFormattedDateHourMinuteSecond(
        date: DateTime.parse(localDate), context: context);
    return SizedBox(
      width: widget.width ?? 300,
      height: widget.height ?? 400,
      child: Card(
        shape: getRoundedBorder(radius: 16),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                      onPressed: () {
                        widget.onCloseRequested();
                      },
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              Text(
                '${widget.audio.projectName}',
                style: myTextStyleLarge(context),
              ),
              const SizedBox(
                height: 24,
              ),
              Text(
                '${widget.audio.userName}',
                style: myTextStyleLargePrimaryColor(context),
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                dt,
                style: myTextStyleMedium(context),
              ),
              const SizedBox(
                height: 16,
              ),
              ElevatedButton(onPressed: _play, child: const Text('Play Audio')),
            ],
          ),
        ),
      ),
    );
  }
}
