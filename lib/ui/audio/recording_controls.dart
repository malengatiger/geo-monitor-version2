import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../library/functions.dart';

class RecordingControls extends StatelessWidget {
  const RecordingControls(
      {Key? key,
      required this.onPlay,
      required this.onPause,
      required this.onStop,
      required this.onRecord,
      required this.isRecording,
      required this.isPaused,
      required this.isStopped})
      : super(key: key);
  final Function onPlay;
  final Function onPause;
  final Function onStop;
  final Function onRecord;
  final bool isRecording;
  final bool isPaused;
  final bool isStopped;
  @override
  Widget build(BuildContext context) {
    var showRecord = true;
    var showPlay = false;
    var showStop = false;
    var showPause = false;
    //pp('🍎 isRecording: $isRecording 🍎isPaused: $isPaused 🍎isStopped: $isStopped');
    if (!isRecording && !isPaused && !isStopped) {
      pp('🍎 all flags are false; should show the recording icon only');
      showRecord = true;
      showStop = false;
      showPlay = false;
      showPause = false;
    } else {
      if (isRecording) {
        showStop = true;
        showPause = true;
        showRecord = false;
      } else if (isStopped) {
        showStop = true;
        showRecord = true;
        showPlay = true;
      } else if (isPaused) {
        showStop = true;
        showRecord = true;
        showPlay = false;
      }
    }

    return Card(
      elevation: 4,
      shape: getRoundedBorder(radius: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // const SizedBox(
            //   width: 4,
            // ),
            showRecord
                ? IconButton(
                    onPressed: _onRecord,
                    icon:
                        Icon(Icons.mic, color: Theme.of(context).primaryColor))
                : const SizedBox(),
            // const SizedBox(
            //   width: 28,
            // ),
            showPlay
                ? IconButton(
                    onPressed: _onPlayTapped,
                    icon: Icon(Icons.play_arrow,
                        color: Theme.of(context).primaryColor))
                : const SizedBox(),
            // const SizedBox(
            //   width: 28,
            // ),
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
    );
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

  void _onRecord() {
    onRecord();
  }
}

class TimerCard extends StatelessWidget {
  const TimerCard({Key? key, required this.seconds, required this.elapsedTime}) : super(key: key);
  final int seconds;
  final String elapsedTime;
  @override
  Widget build(BuildContext context) {
    int h, m, s;
    h = seconds ~/ 3600;
    m = ((seconds - h * 3600)) ~/ 60;
    s = seconds - (h * 3600) - (m * 60);
    String hourLeft = h.toString().length < 2 ? "0$h" : h.toString();
    String minuteLeft = m.toString().length < 2 ? "0$m" : m.toString();
    String secondsLeft = s.toString().length < 2 ? "0$s" : s.toString();

    String result = "$hourLeft:$minuteLeft:$secondsLeft";

    return Card(
      elevation: 8,
      shape: getRoundedBorder(radius: 12),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Text(elapsedTime,
              style: myTextStyleSmall(context),
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              '$result ',
              style: GoogleFonts.secularOne(
                  textStyle: Theme.of(context).textTheme.bodyLarge,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  color: Theme.of(context).primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
