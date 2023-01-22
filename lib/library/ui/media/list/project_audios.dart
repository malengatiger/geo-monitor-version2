import 'package:badges/badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geo_monitor/library/data/audio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import '../../../bloc/project_bloc.dart';
import '../../../data/photo.dart';
import '../../../data/project.dart';
import '../../../data/video.dart';
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
  State<ProjectAudios> createState() => _ProjectPhotosState();
}

class _ProjectPhotosState extends State<ProjectAudios> {
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

  AudioPlayer audioPlayer = AudioPlayer();

  void _playAudio() {
    audioPlayer.setUrl(_selectedAudio!.url!);
    audioPlayer.play();
    // audioPlayer.playerStateStream.listen((event) {
    //   if (event.playing) {
    //     //ignore
    //   } else {
    //     audioPlayer.stop();
    //     setState(() {
    //       _showAudioPlayer = false;
    //     });
    //   }
    // });
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
                child: Text(widget.project.name!, style: myTextStyleMediumBold(context),),
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
                                  child:  Card(
                                    elevation: 4,
                                    shape: getRoundedBorder(radius: 16),
                                    child:  Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: SizedBox(
                                        height: 200, width: 200,
                                        child: Column(
                                          children:  [
                                            const SizedBox(height: 28,),
                                            const SizedBox(height: 48, width: 48,
                                              child: CircleAvatar(
                                                child: Icon(Icons.mic, size: 32,),
                                              ),
                                            ),
                                            const SizedBox(height: 16,),
                                            Text(dt, style: myTextStyleSmall(context),),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                              ),
                            ),
                          ],
                        );
                      }),
                )),
          ],
        ),
        _showAudioPlayer? Positioned(
            top: 100, left: 40, right: 40, bottom: 200,
            child: Card(
              elevation: 8,
          shape: getRoundedBorder(radius: 16),
          child: Column(
            children: [
              const SizedBox(height: 64,),
               Text('Audio Playing', style: myTextStyleLarge(context),),
              const SizedBox(height: 32,),
              Text(getFormattedDateShortWithTime(_selectedAudio!.created!, context), style: myTextStyleSmall(context),),
              const SizedBox(height: 20,),
              TextButton(onPressed: () {
                setState(() {
                  _showAudioPlayer = false;
                  _selectedAudio = null;
                });
                audioPlayer.stop();
              }, child: const Text('Stop')),
              const SizedBox(height: 32,),
            ],
          ),
        )): const SizedBox(),
      ],
    );
  }
}
