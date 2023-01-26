import 'dart:async';

import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import '../../../bloc/project_bloc.dart';
import '../../../data/audio.dart';
import '../../../data/project.dart';
import '../../../functions.dart';

class ProjectAudios extends StatefulWidget {
  final Project project;
  final bool refresh;
  final Function(Audio) onAudioTapped;

  const ProjectAudios(
      {super.key,
      required this.project,
      required this.refresh,
      required this.onAudioTapped});

  @override
  State<ProjectAudios> createState() => ProjectAudiosState();
}

class ProjectAudiosState extends State<ProjectAudios> {
  var audios = <Audio>[];
  bool loading = false;
  @override
  void initState() {
    super.initState();
    _subscribeToStreams();
    _getAudios();
  }

  void _subscribeToStreams() async {}
  void _getAudios() async {
    setState(() {
      loading = true;
    });
    var bag = await projectBloc.refreshProjectData(
        projectId: widget.project.projectId!, forceRefresh: widget.refresh);
    audios = bag.audios!;
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
    if (audioPlayer.playing) {
      pp('$mm audio player is already playing; quitting');
      return;
    }
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
    // audioPlayer.playerStateStream.listen((state) {
    //   if (state.playing) {
    //   } else {
    //     switch (state.processingState) {
    //       case ProcessingState.idle:
    //         pp('$mm ProcessingState.idle ...');
    //         break;
    //       case ProcessingState.loading:
    //         pp('$mm ProcessingState.loading ...');
    //         setState(() {
    //           _loading = true;
    //         });
    //         break;
    //       case ProcessingState.buffering:
    //         pp('$mm ProcessingState.buffering ...');
    //         setState(() {
    //           _loading = false;
    //         });
    //         break;
    //       case ProcessingState.ready:
    //         pp('$mm ProcessingState.ready ...');
    //         setState(() {
    //           _loading = false;
    //         });
    //         break;
    //       case ProcessingState.completed:
    //         pp('$mm ProcessingState.completed ...');
    //         if (mounted) {
    //           setState(() {
    //             isStopped = true;
    //           });
    //         }
    //         break;
    //     }
    //   }
    // });

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

  void _showPlaybackDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
              title: Text(
                "Critical App Message",
                style: myTextStyleLarge(ctx),
              ),
              content: Text(
                '',
                style: myTextStyleMedium(ctx),
              ),
              shape: getRoundedBorder(radius: 16),
              actions: <Widget>[
                TextButton(
                  onPressed: () {},
                  child: const Text("Exit the App"),
                ),
              ],
            ));
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
                  SizedBox(
                    height: 48,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        widget.project.name!,
                        style: myTextStyleMediumBold(context),
                      ),
                    ),
                  ),
                  Expanded(
                      child: Badge(
                    position: BadgePosition.topEnd(top: -8, end: 4),
                    padding: const EdgeInsets.all(12.0),
                    badgeContent: Text(
                      '${audios.length}',
                      style: myTextStyleSmall(context),
                    ),
                    badgeColor: Colors.teal.shade700,
                    elevation: 16,
                    child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisSpacing: 1,
                                crossAxisCount: 2,
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
                                        padding: const EdgeInsets.all(8.0),
                                        child: SizedBox(
                                          height: 300,
                                          width: 300,
                                          child: Column(
                                            children: [
                                              const SizedBox(
                                                height: 16,
                                              ),
                                              const SizedBox(
                                                height: 32,
                                                width: 32,
                                                child: CircleAvatar(
                                                  child: Icon(
                                                    Icons.mic,
                                                    size: 28,
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
                              height: 24,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        getHourMinuteSecond(_currentPosition),
                                        style: GoogleFonts.secularOne(
                                            textStyle: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                            fontWeight: FontWeight.normal,
                                            fontSize: 12,
                                            color:
                                                Theme.of(context).primaryColor),
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
                              height: 48,
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
                              height: 28,
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
                                    child: const Text('Close')),
                              ],
                            ),
                            const SizedBox(
                              height: 32,
                            ),
                          ],
                        ),
                      ))
                  : const SizedBox(),

            ],
          );
  }

  // onPlay() {
  //   pp('$mm ... playing after pause? - should not start from beginning');
  //   audioPlayer.play();
  // }
  //
  // onPause() {
  //   pp('$mm ... player has been paused .............');
  //   audioPlayer.pause();
  // }
  //
  // onStop() {
  //   pp('$mm ... player has been stopped .............');
  //   audioPlayer.stop();
  // }
  //
  // onClose() {
  //   setState(() {
  //     _showAudioPlayer = false;
  //     _currentPosition = const Duration(seconds: 0);
  //   });
  // }
}

class AudioPlaybackCard extends StatelessWidget {
  const AudioPlaybackCard(
      {Key? key,
      required this.loading,
      required this.selectedAudio,
      required this.duration,
      required this.currentPosition,
      required this.onPlay,
      required this.onPause,
      required this.onStop,
      required this.onClose})
      : super(key: key);

  final bool loading;
  final Audio selectedAudio;
  final Duration duration, currentPosition;
  final Function onPlay;
  final Function onPause;
  final Function onStop;
  final Function onClose;

  @override
  Widget build(BuildContext context) {
    var stringDuration = getHourMinuteSecond(duration);
    return Card(
      elevation: 8,
      shape: getRoundedBorder(radius: 16),
      child: Column(
        children: [
          const SizedBox(
            height: 24,
          ),
          loading
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
            height: 24,
          ),
          Text(
            getFormattedDateShortWithTime(selectedAudio.created!, context),
            style: myTextStyleSmall(context),
          ),
          const SizedBox(
            height: 16,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                getHourMinuteSecond(currentPosition),
                style: GoogleFonts.secularOne(
                    textStyle: Theme.of(context).textTheme.bodySmall,
                    fontWeight: FontWeight.normal,
                    fontSize: 12,
                    color: Theme.of(context).primaryColor),
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
                stringDuration,
                style: myTextStyleTiny(context),
              ),
            ],
          ),
          const SizedBox(
            height: 48,
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
                '${selectedAudio.userName}',
                style: myTextStyleTiny(context),
              ),
            ],
          ),
          const SizedBox(
            height: 28,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: PlaybackControls(
                  onPlay: () {
                    onPlay();
                  },
                  onPause: () {
                    onPause();
                  },
                  onStop: () {
                    onStop();
                  },
                ),
              ),
              const SizedBox(
                width: 48,
              ),
              TextButton(
                  onPressed: () {
                    onClose();
                  },
                  child: const Text('Close')),
            ],
          ),
          const SizedBox(
            height: 32,
          ),
        ],
      ),
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

            IconButton(
                    onPressed: _onPlayPaused,
                    icon: Icon(Icons.pause,
                        color: Theme.of(context).primaryColor)),
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
