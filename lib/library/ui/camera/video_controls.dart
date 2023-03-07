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
      required this.isRecording,
      required this.onClose})
      : super(key: key);
  final Function onPlay;
  final Function onPause;
  final Function onStop;
  final Function onRecord;
  final Function onClose;
  final bool isPlaying;
  final bool isPaused;
  final bool isStopped;
  final bool isRecording;
  @override
  Widget build(BuildContext context) {
    // var showPlay = false;
    // var showStop = false;
    // var showPause = false;
    // var showRecord = false;
    // var width = 320.0;
    // if (!isPlaying && !isPaused && !isStopped) {
    //   showStop = true;
    //   showRecord = true;
    //   showPause = false;
    //   showPlay = false;
    //   width = 420;
    // } else {
    //   if (isPlaying) {
    //     showStop = true;
    //     showPause = true;
    //     showPlay = false;
    //     showRecord = false;
    //     width = 320;
    //   } else if (isStopped) {
    //     showStop = false;
    //     showPlay = true;
    //     showPause = false;
    //     showRecord = false;
    //     width = 320;
    //   } else if (isPaused) {
    //     showStop = true;
    //     showPlay = true;
    //     showPause = false;
    //     showRecord = false;
    //     width = 320;
    //   }
    // }
    // pp('This is the width fucking up: $width');
    return SizedBox(width: 100,
      child: Card(
        elevation: 8,
        shape: getRoundedBorder(radius: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
                onPressed: _onRecordTapped,
                icon: Icon(Icons.videocam,
                    color: Theme.of(context).primaryColor)),

            // IconButton(
            //     onPressed: _onPlayTapped,
            //     icon: Icon(Icons.play_arrow,
            //         color: Theme.of(context).primaryColor)),

            IconButton(
                onPressed: _onPlayPaused,
                icon: Icon(Icons.pause, color: Theme.of(context).primaryColor)),

            IconButton(
                onPressed: _onPlayStopped,
                icon: Icon(
                  Icons.stop,
                  color: Theme.of(context).primaryColor,
                )),

          ],
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
    pp('Video controls, onStop');
    onStop();
  }

  void _onPlayPaused() {
    onPause();
  }
}
