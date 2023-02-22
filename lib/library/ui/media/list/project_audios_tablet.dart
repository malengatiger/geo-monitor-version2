import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/fcm_bloc.dart';
import 'package:geo_monitor/library/ui/media/audio_grid.dart';
import 'package:geo_monitor/ui/audio/audio_player_page.dart';
import 'package:just_audio/just_audio.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../../bloc/project_bloc.dart';
import '../../../data/audio.dart';
import '../../../data/project.dart';
import '../../../functions.dart';

class ProjectAudiosTablet extends StatefulWidget {
  final Project project;
  final bool refresh;
  final Function(Audio) onAudioTapped;

  const ProjectAudiosTablet(
      {super.key,
      required this.project,
      required this.refresh,
      required this.onAudioTapped});

  @override
  State<ProjectAudiosTablet> createState() => ProjectAudiosTabletState();
}

class ProjectAudiosTabletState extends State<ProjectAudiosTablet> {
  var audios = <Audio>[];
  bool loading = false;
  late StreamSubscription<Audio> audioStreamSubscriptionFCM;
  @override
  void initState() {
    super.initState();
    _subscribeToStreams();
    _getAudios();
  }

  @override
  void dispose() {
    audioPlayer.stop();
    audioStreamSubscriptionFCM.cancel();
    super.dispose();
  }

  void _subscribeToStreams() async {
    audioStreamSubscriptionFCM = fcmBloc.audioStream.listen((event) {
      if (mounted) {
        _getAudios();
      }
    });
  }

  void _getAudios() async {
    setState(() {
      loading = true;
    });
    audios = await projectBloc.getProjectAudios(
        projectId: widget.project.projectId!, forceRefresh: widget.refresh);
    audios.sort((a, b) => b.created!.compareTo(a.created!));
    setState(() {
      loading = false;
    });
  }

  bool _showAudioPlayer = false;
  Audio? _selectedAudio;
  final mm = '🍎🍎🍎🍎';
  AudioPlayer audioPlayer = AudioPlayer();
  Duration? duration;
  String? stringDuration;
  bool _loading = false;
  Duration _currentPosition = const Duration(seconds: 0);

  late StreamSubscription<PlaybackEvent> playbackSub;

  bool isPaused = false;
  bool isStopped = false;

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return audios.isEmpty
        ? Center(
            child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0)),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No audio clips in project'),
                )),
          )
        : Stack(
            children: [
              OrientationLayoutBuilder(landscape: (context) {
                return AudioGrid(
                    audios: audios,
                    onAudioTapped: (audio, index) {
                      setState(() {
                        _showAudioPlayer = true;
                        _selectedAudio = audio;
                      });
                    },
                    itemWidth: 300,
                    crossAxisCount: 5);
              }, portrait: (context) {
                return AudioGrid(
                    audios: audios,
                    onAudioTapped: (audio, index) {
                      setState(() {
                        _selectedAudio = audio;
                        _showAudioPlayer = true;
                      });
                    },
                    itemWidth: 300,
                    crossAxisCount: 4);
              }),
              _showAudioPlayer
                  ? OrientationLayoutBuilder(landscape: (context) {
                      return Positioned(
                          top: 60,
                          left: 300,
                          right: 300,
                          bottom: 60,
                          child: SizedBox(
                            width: width / 2,
                            child: AudioPlayerCard(
                                audio: _selectedAudio!,
                                onCloseRequested: () {
                                  setState(() {
                                    _showAudioPlayer = false;
                                  });
                                }),
                          ));
                    }, portrait: (context) {
                      return Positioned(
                          top: 200,
                          left: 160,
                          right: 160,
                          bottom: 200,
                          child: SizedBox(
                            width: width / 2,
                            child: AudioPlayerCard(
                                audio: _selectedAudio!,
                                onCloseRequested: () {
                                  setState(() {
                                    _showAudioPlayer = false;
                                  });
                                }),
                          ));
                    })
                  : const SizedBox(),
            ],
          );
  }
}

class PlaybackControls extends StatelessWidget {
  const PlaybackControls({
    Key? key,
    required this.onPlay,
    required this.onPause,
    required this.onStop,
  }) : super(key: key);
  final Function onPlay;
  final Function onPause;
  final Function onStop;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: getRoundedBorder(radius: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            const SizedBox(
              width: 8,
            ),
            IconButton(
                onPressed: _onPlayTapped,
                icon: Icon(Icons.play_arrow,
                    color: Theme.of(context).primaryColor)),
            const SizedBox(
              width: 16,
            ),
            IconButton(
                onPressed: _onPlayPaused,
                icon: Icon(Icons.pause, color: Theme.of(context).primaryColor)),
            const SizedBox(
              width: 16,
            ),
            IconButton(
                onPressed: _onPlayStopped,
                icon: Icon(
                  Icons.stop,
                  color: Theme.of(context).primaryColor,
                ))
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
}
