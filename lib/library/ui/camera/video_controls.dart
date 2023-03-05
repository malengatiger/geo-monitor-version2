import 'package:flutter/material.dart';

import '../../functions.dart';

class VideoControls extends StatelessWidget {
  const VideoControls(
      {Key? key,
      required this.onRecord,
      required this.onPlay,
      required this.onPause,
      required this.onStop,
      required this.isPlaying,
      required this.isPaused,
      required this.isStopped,
      required this.isRecording})
      : super(key: key);
  final Function onPlay;
  final Function onPause;
  final Function onStop;
  final Function onRecord;
  final bool isPlaying;
  final bool isPaused;
  final bool isStopped;
  final bool isRecording;
  @override
  Widget build(BuildContext context) {
    var showPlay = false;
    var showStop = false;
    var showPause = false;
    var showRecord = false;
    var width = 120.0;
    if (!isPlaying && !isPaused && !isStopped) {
      showStop = false;
      showRecord = true;
      showPause = false;
      showPlay = false;
      width = 120;
    } else {
      if (isPlaying) {
        showStop = true;
        showPause = true;
        showPlay = false;
        showRecord = false;
        width = 240;
      } else if (isStopped) {
        showStop = false;
        showPlay = true;
        showPause = false;
        showRecord = false;
        width = 240;
      } else if (isPaused) {
        showStop = true;
        showPlay = true;
        showPause = false;
        showRecord = false;
        width = 240;
      }
    }

    return SizedBox(
      width: width,
      child: Card(
        elevation: 4,
        shape: getRoundedBorder(radius: 16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(
                width: 4,
              ),
              showRecord
                  ? IconButton(
                  onPressed: _onRecordTapped,
                  icon: Icon(Icons.videocam,
                      color: Theme.of(context).primaryColor))
                  : const SizedBox(),
              showPlay
                  ? IconButton(
                      onPressed: _onPlayTapped,
                      icon: Icon(Icons.play_arrow,
                          color: Theme.of(context).primaryColor))
                  : const SizedBox(),
              showPause
                  ? IconButton(
                      onPressed: _onPlayPaused,
                      icon: Icon(Icons.pause,
                          color: Theme.of(context).primaryColor))
                  : const SizedBox(),
              // const SizedBox(
              //   width: 28,
              // ),
              showStop
                  ? IconButton(
                      onPressed: _onPlayStopped,
                      icon: Icon(
                        Icons.stop,
                        color: Theme.of(context).primaryColor,
                      ))
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }

  void _onRecordTapped() {
    onRecord();
  }

  void _onPlayTapped() {
    onPlay();
  }

  void _onPlayStopped() {
    onStop();
  }

  void _onPlayPaused() {
    onPause();
  }
}
