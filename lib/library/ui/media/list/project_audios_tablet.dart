import 'dart:async';

import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/fcm_bloc.dart';
import 'package:geo_monitor/library/emojis.dart';
import 'package:geo_monitor/library/ui/ratings/rating_adder_mobile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:page_transition/page_transition.dart';

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

    Future.delayed(const Duration(milliseconds: 10), () {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.leftToRightWithFade,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1000),
              child: RatingAdderMobile(
                project: widget.project,
                audioId: _selectedAudio!.audioId!,
              )));
    });
  }

  @override
  Widget build(BuildContext context) {
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
              Column(
                children: [
                  // SizedBox(
                  //   height: 48,
                  //   child: Padding(
                  //     padding: const EdgeInsets.symmetric(vertical: 16.0),
                  //     child: Text(
                  //       widget.project.name!,
                  //       style: myTextStyleMediumBold(context),
                  //     ),
                  //   ),
                  // ),
                  Expanded(
                      child: bd.Badge(
                    position: bd.BadgePosition.topEnd(top: -8, end: 4),
                        badgeStyle:  bd.BadgeStyle(
                          badgeColor: Theme.of(context).primaryColor,
                          elevation: 8, padding: const EdgeInsets.all(8),
                        ),
                    badgeContent: Text(
                      '${audios.length}',
                      style: myTextStyleSmall(context),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisSpacing: 1,
                                  crossAxisCount: 6,
                                  mainAxisSpacing: 1),
                          itemCount: audios.length,
                          itemBuilder: (context, index) {
                            var audio = audios.elementAt(index);
                            var dt = getFormattedDateShortestWithTime(
                                audio.created!, context);
                            String dur = '00:00:00';
                            if (audio.durationInSeconds != null) {
                              dur = getHourMinuteSecond(
                                  Duration(seconds: audio.durationInSeconds!));
                            }
                            return Stack(
                              children: [
                                SizedBox(
                                  width: 300,
                                  child: GestureDetector(
                                      onTap: () {
                                        //widget.onAudioTapped(audio);
                                        setState(() {
                                          _selectedAudio = audio;
                                          _showAudioPlayer = true;
                                        });
                                        _playAudio();
                                      },
                                      child: Card(
                                        elevation: 4,
                                        shape: getRoundedBorder(radius: 12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(6.0),
                                          child: SizedBox(
                                            height: 300,
                                            width: 300,
                                            child: Column(
                                              children: [
                                                const SizedBox(
                                                  height: 12,
                                                ),
                                                const SizedBox(
                                                  height: 28,
                                                  width: 28,
                                                  child: CircleAvatar(
                                                    child: Icon(
                                                      Icons.mic,
                                                      size: 24,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 8,
                                                ),
                                                Text(
                                                  dt,
                                                  style: myTextStyleTiny(context),
                                                ),
                                                const SizedBox(
                                                  height: 8,
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Flexible(
                                                        child: Text(
                                                      '${audio.userName}',
                                                      style: myTextStyleTiny(
                                                          context),
                                                    )),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 8,
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Duration:',
                                                      style: myTextStyleTiny(
                                                          context),
                                                    ),
                                                    const SizedBox(
                                                      width: 4,
                                                    ),
                                                    Text(
                                                      dur,
                                                      style: GoogleFonts.lato(
                                                          textStyle:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontSize: 10,
                                                          color: Theme.of(context)
                                                              .primaryColor),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )),
                                ),
                              ],
                            );
                          }),
                    ),
                  )),
                ],
              ),
              _showAudioPlayer
                  ? Positioned(
                      top: 89,
                      left: 20,
                      right: 20,
                      bottom: 80,
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
                                  : Text(
                                      'Audio Report',
                                      style: myTextStyleMediumBold(context),
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
                                          getHourMinuteSecond(_currentPosition),
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
                                  Row(mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(onPressed: _onFavorite, child: Text(E.heartRed)),
                                      const SizedBox(width: 48,),
                                      TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _showAudioPlayer = false;
                                              _selectedAudio = null;
                                            });
                                            audioPlayer.stop();
                                          },
                                          child:  Text('Close', style: myTextStyleSmall(context),)),
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
