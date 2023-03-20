import 'dart:async';

import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/fcm_bloc.dart';
import 'package:geo_monitor/library/data/settings_model.dart';
import 'package:geo_monitor/library/generic_functions.dart';
import 'package:geo_monitor/library/ui/media/list/project_videos_page.dart';
import 'package:geo_monitor/library/ui/ratings/rating_adder.dart';
import 'package:geo_monitor/ui/audio/audio_player_card.dart';
import 'package:just_audio/just_audio.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../../../l10n/translation_handler.dart';
import '../../../api/prefs_og.dart';
import '../../../bloc/project_bloc.dart';
import '../../../data/audio.dart';
import '../../../data/project.dart';
import '../../../functions.dart';
import '../audio_grid.dart';
import 'audio_card.dart';

class ProjectAudiosPage extends StatefulWidget {
  final Project project;
  final bool refresh;
  final Function(Audio) onAudioTapped;

  const ProjectAudiosPage(
      {super.key,
      required this.project,
      required this.refresh,
      required this.onAudioTapped});

  @override
  State<ProjectAudiosPage> createState() => ProjectAudiosPageState();
}

class ProjectAudiosPageState extends State<ProjectAudiosPage> {
  var audios = <Audio>[];
  bool loading = false;
  late StreamSubscription<Audio> audioStreamSubscriptionFCM;
  String? notFound, networkProblem, loadingActivities;
  SettingsModel? settingsModel;
  @override
  void initState() {
    super.initState();
    _setTexts();
    _subscribeToStreams();
    _getAudios();
  }

  void _setTexts() async {
    settingsModel = await prefsOGx.getSettings();
    var nf =
        await mTx.translate('audiosNotFoundInProject', settingsModel!.locale!);
    notFound = nf.replaceAll('\$project', '\n\n${widget.project.name!}');
    networkProblem =
        await mTx.translate('networkProblem', settingsModel!.locale!);
    loadingActivities =
        await mTx.translate('loadingActivities', settingsModel!.locale!);
    setState(() {});
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
    try {
      settingsModel = await prefsOGx.getSettings();
      if (settingsModel != null) {
        durationText = await mTx.translate('duration', settingsModel!.locale!);
      }
      var map = await getStartEndDates();
      final startDate = map['startDate'];
      final endDate = map['endDate'];
      audios = await projectBloc.getProjectAudios(
          projectId: widget.project.projectId!,
          forceRefresh: widget.refresh,
          startDate: startDate!,
          endDate: endDate!);
      audios.sort((a, b) => b.created!.compareTo(a.created!));
    } catch (e) {
      var msg = e.toString();
      if (msg.contains('HttpException')) {
        if (mounted) {
          showToast(
              message: networkProblem == null ? 'Not found' : networkProblem!,
              context: context);
        }
      }
    }
    setState(() {
      loading = false;
    });
  }

  bool _showAudioPlayer = false;
  Audio? _selectedAudio;
  final mm = '🍎🍎🍎🍎';
  AudioPlayer audioPlayer = AudioPlayer();
  Duration? duration;
  String? stringDuration, durationText;

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
              });
            }
            break;
          case ProcessingState.buffering:
            // pp('$mm ProcessingState.buffering ...');
            if (mounted) {
              setState(() {
              });
            }
            break;
          case ProcessingState.ready:
            // pp('$mm ProcessingState.ready ...');
            if (mounted) {
              setState(() {
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
                      elevation: 8.0,
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
    if (loading) {
      return loadingActivities == null
          ? const SizedBox()
          : LoadingCard(loadingActivities: loadingActivities!);
    }
    if (audios.isEmpty) {
      return Center(
        child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(notFound == null
                  ? 'No audio clips in project'
                  : notFound!),
            )),
      );
    }
    final width = MediaQuery.of(context).size.width;
    return ScreenTypeLayout(mobile: Stack(
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
                child: bd.Badge(
                  position: bd.BadgePosition.topEnd(top: -2, end: 8),
                  badgeStyle: bd.BadgeStyle(
                    badgeColor: Theme.of(context).primaryColor,
                    elevation: 8,
                    padding: const EdgeInsets.all(8),
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
                            crossAxisCount: 2,
                            mainAxisSpacing: 1),
                        itemCount: audios.length,
                        itemBuilder: (context, index) {
                          var audio = audios.elementAt(index);

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
                                  child: AudioCard(
                                    audio: audio,
                                    durationText: durationText == null
                                        ? 'Duration'
                                        : durationText!,
                                  ),
                                ),
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
            child: AudioPlayerCard(
                audio: _selectedAudio!,
                onCloseRequested: (){
                  setState(() {
                    _showAudioPlayer = false;
                  });
                }))
            : const SizedBox(),
      ],
    ), tablet: Stack(
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
    ),
    );

  }

  onCloseRequested() {
    setState(() {
      _showAudioPlayer = false;
    });
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
