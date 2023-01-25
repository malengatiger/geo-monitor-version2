import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
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

  Future<void> _playAudio() async {
    duration = await audioPlayer.setUrl(_selectedAudio!.url!);
    stringDuration = getHourMinuteSecond(duration!);
    pp('🍎🍎🍎🍎 Duration of file is: $stringDuration ');
    setState(() {

    });
    audioPlayer.play();

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
                        String dur = '00:00:00';
                        if (audio.durationInSeconds != null) {
                          dur = getHourMinuteSecond(Duration(seconds: audio
                              .durationInSeconds!));
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
                                  child:  Card(
                                    elevation: 4,
                                    shape: getRoundedBorder(radius: 12),
                                    child:  Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SizedBox(
                                        height: 300, width: 300,
                                        child: Column(
                                          children:  [
                                            const SizedBox(height: 16,),
                                            const SizedBox(height: 40, width: 40,
                                              child: CircleAvatar(
                                                child: Icon(Icons.mic, size: 36,),
                                              ),
                                            ),
                                            const SizedBox(height: 8,),
                                            Text(dt, style: myTextStyleTiny(context),),
                                            const SizedBox(height: 8,),
                                            Text('${audio.userName}', style: myTextStyleTiny(context),),
                                            const SizedBox(height: 8,),
                                            Row(mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text('Duration:', style: myTextStyleTiny(context),),
                                                const SizedBox(width: 8,),
                                                Text(dur, style: myTextStyleSmall(context),),
                                              ],
                                            ),
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
              duration == null? const SizedBox(): Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text('Duration', style: myTextStyleSmall(context),),
                  const SizedBox(width: 8,),
                  Text('$stringDuration', style: myNumberStyleSmall(context),),
                  const SizedBox(width: 8,),
                   Text('seconds', style: myTextStyleSmall(context),),
                ],
              ),
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
