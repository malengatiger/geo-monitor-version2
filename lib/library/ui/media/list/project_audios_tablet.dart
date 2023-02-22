import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/fcm_bloc.dart';
import 'package:geo_monitor/library/emojis.dart';
import 'package:geo_monitor/library/ui/media/audio_grid.dart';
import 'package:geo_monitor/library/ui/ratings/rating_adder.dart';
import 'package:google_fonts/google_fonts.dart';
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

  Future<void> _playAudio() async {
    try {
      _listenToAudioPlayer();
      duration = await audioPlayer.setUrl(_selectedAudio!.url!);
      stringDuration = getHourMinuteSecond(duration!);
      pp('🍎🍎🍎🍎 Duration of file is: $stringDuration ');
    } on PlayerException catch (e) {
      pp('$mm  PlayerException : $e');
    } on PlayerInterruptedException catch (e) {
      pp('$mm  PlayerInterruptedException : $e'); //
    } catch (e) {
      pp(e);
    }

    setState(() {});
    audioPlayer.play();
  }

  late StreamSubscription<PlaybackEvent> playbackSub;
  void _listenToAudioPlayer() {
    audioPlayer.playerStateStream.listen((state) {
      if (state.playing) {
      } else {
        switch (state.processingState) {
          case ProcessingState.idle:
            // pp('$mm ProcessingState.idle ...');
            break;
          case ProcessingState.loading:
            // pp('$mm ProcessingState.loading ...');
            if (mounted) {
              setState(() {
                _loading = true;
              });
            }
            break;
          case ProcessingState.buffering:
            // pp('$mm ProcessingState.buffering ...');
            if (mounted) {
              setState(() {
                _loading = false;
              });
            }
            break;
          case ProcessingState.ready:
            // pp('$mm ProcessingState.ready ...');
            if (mounted) {
              setState(() {
                _loading = false;
              });
            }
            break;
          case ProcessingState.completed:
            pp('$mm ProcessingState.completed ...');
            if (mounted) {
              setState(() {
                isStopped = true;
              });
            }
            break;
        }
      }
    });

    audioPlayer.positionStream.listen((event) {
      if (mounted) {
        setState(() {
          _currentPosition = event;
        });
      }
    });
    playbackSub = audioPlayer.playbackEventStream.listen((event) {
      if (event.processingState == ProcessingState.completed) {
        pp('\n$mm  playback: ProcessingState.complete : 🔵🔵 $event 🔵🔵');
        if (mounted) {
          setState(() {
            isStopped = true;
          });
        }
      }
    });

    playbackSub.onError((err, stackTrace) {
      if (err != null) {
        pp('$mm ERROR : $err');
        pp(stackTrace);
        return;
      }
    });
  }

  bool isPaused = false;
  bool isStopped = false;
  void _onFavorite() async {
    pp('$mm on favorite tapped - do da bizness! navigate to RatingAdder');

    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Container(
                    color: Colors.black12,
                    child: RatingAdder(
                      width: 400,
                      audio: _selectedAudio!,
                      onDone: () {
                        Navigator.of(context).pop();
                      },
                    )),
              ),
            ));
  }

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
                      });
                    },
                    itemWidth: 300,
                    crossAxisCount: 5);
              }, portrait: (context) {
                return AudioGrid(
                    audios: audios,
                    onAudioTapped: (audio, index) {
                      setState(() {
                        _showAudioPlayer = true;
                      });
                    },
                    itemWidth: 300,
                    crossAxisCount: 4);
              }),
              _showAudioPlayer
                  ? Positioned(
                      top: 200,
                      left: 300,
                      right: 300,
                      bottom: 100,
                      child: SizedBox(
                        width: width / 2,
                        child: Card(
                          elevation: 16,
                          shape: getRoundedBorder(radius: 16),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 24,
                                ),
                                _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 4,
                                          backgroundColor: Colors.pink,
                                        ),
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 28.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Audio Report',
                                              style: myTextStyleMediumBold(
                                                  context),
                                            ),
                                            IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _showAudioPlayer = false;
                                                  });
                                                },
                                                icon: Icon(
                                                  Icons.close,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                ))
                                          ],
                                        ),
                                      ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Text(
                                  getFormattedDateShortWithTime(
                                      _selectedAudio!.created!, context),
                                  style: myTextStyleSmall(context),
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                duration == null
                                    ? const SizedBox()
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            getHourMinuteSecond(
                                                _currentPosition),
                                            style: GoogleFonts.secularOne(
                                                textStyle: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color: Theme.of(context)
                                                    .primaryColor),
                                          ),
                                          const SizedBox(
                                            width: 8,
                                          ),
                                          Text(
                                            'of',
                                            style: myTextStyleTiny(context),
                                          ),
                                          const SizedBox(
                                            width: 8,
                                          ),
                                          Text(
                                            '$stringDuration',
                                            style: myTextStyleTiny(context),
                                          ),
                                        ],
                                      ),
                                const SizedBox(
                                  height: 32,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Made By:',
                                      style: myTextStyleTiny(context),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      '${_selectedAudio!.userName}',
                                      style: myTextStyleTiny(context),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 32,
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 28.0),
                                      child: PlaybackControls(
                                        onPlay: () {
                                          if (isStopped) {
                                            _playAudio();
                                          } else {
                                            audioPlayer.play();
                                          }
                                          isStopped = false;
                                        },
                                        onPause: () {
                                          audioPlayer.pause();
                                          isStopped = false;
                                        },
                                        onStop: () {
                                          audioPlayer.stop();
                                          isStopped = true;
                                        },
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 16,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        TextButton(
                                            onPressed: _onFavorite,
                                            child: Text(E.heartRed)),
                                        const SizedBox(
                                          width: 48,
                                        ),
                                        TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _showAudioPlayer = false;
                                                _selectedAudio = null;
                                              });
                                              audioPlayer.stop();
                                            },
                                            child: Text(
                                              'Close',
                                              style: myTextStyleSmall(context),
                                            )),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 32,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ))
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
