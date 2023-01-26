import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:video_player/video_player.dart';

import '../../data/project.dart';
import '../../data/video.dart';
import '../../emojis.dart';
import '../../functions.dart';
import '../ratings/rating_adder_mobile.dart';

class PlayVideo extends StatefulWidget {
  const PlayVideo({Key? key, required this.video, required this.project}) : super(key: key);

  final Video video;
  final Project project;

  @override
  PlayVideoState createState() => PlayVideoState();
}

class PlayVideoState extends State<PlayVideo>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  VideoPlayerController? videoController;
  VoidCallback? videoPlayerListener;
  static const mm = '🔵🔵🔵🔵 PlayVideoState 🍎 : ';

  int videoDurationInSeconds = 0;
  double videoDurationInMinutes = 0.0;
  @override
  void initState() {
    _animationController = AnimationController(vsync: this);
    super.initState();
    pp('PlayVideo initState: ${widget.video.toJson()}  🔵🔵');
    videoController = VideoPlayerController.network(widget.video.url!)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        pp('.......... doing shit with videoController ... setting state .... '
            '$videoController 🍎DURATION: ${videoController!.value.duration} seconds!');

        videoController!.addListener(_checkVideo);
        setState(() {
          if (videoController != null) {
            videoDurationInSeconds = videoController!.value.duration.inSeconds;
            videoDurationInMinutes = videoDurationInSeconds / 60;
            videoController!.value.isPlaying
                ? videoController!.pause()
                : videoController!.play();
          }
        });
      });
  }

  bool _showFloatingButton = true;
  void _checkVideo() {
    if(videoController!.value.position == const Duration(seconds: 0, minutes: 0, hours: 0)) {
      pp('$mm video Started');
      setState(() {
        _showFloatingButton = false;
      });
    }

    if (videoController!.value.isPlaying) {
      setState(() {
        _showFloatingButton = false;
      });
    }
    if (videoController!.value.isBuffering) {
      setState(() {
        _showFloatingButton = false;
      });
    }
    if (!videoController!.value.isPlaying) {
      setState(() {
        _showFloatingButton = true;
      });
    }
    if(videoController!.value.position == videoController!.value.duration) {
      pp('$mm video Ended ....');
      setState(() {
        _showFloatingButton = true;
      });
    }
  }
  @override
  void dispose() {
    _animationController.dispose();
    if (videoController != null) {
      pp('Disposing the videoController ... ');
      videoController!.dispose();
    }
    super.dispose();
  }
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
                videoId: widget.video.videoId!,
              )));
    });
  }

  bool _showElapsed = false;
  @override
  Widget build(BuildContext context) {
    var m = getFormattedDateLongWithTime(widget.video.created!, context);
    var elapsedMinutes = 0.0;
    var elapsedSeconds = 0;
    if (videoController != null) {
      elapsedSeconds = videoController!.value.position.inSeconds;
      elapsedMinutes = (elapsedSeconds / 60);
    }
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Video Player',
            style: myTextStyleSmall(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                Text(
                  '${widget.video.projectName}',
                  style: myTextStyleLarge(context),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  m,
                  style: myTextStyleSmall(context),
                ),
                const SizedBox(
                  height: 2,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(onPressed: _onFavorite, child: Text(E.heartBlue)),
                    const SizedBox(width: 28,),
                    Text(
                      'Duration',
                      style: GoogleFonts.lato(
                        textStyle: Theme.of(context).textTheme.bodySmall,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Text(
                      videoDurationInMinutes > 1.0
                          ? videoDurationInMinutes.toStringAsFixed(2)
                          : '$videoDurationInSeconds',
                      style: GoogleFonts.secularOne(
                          textStyle: Theme.of(context).textTheme.bodySmall,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(
                      videoDurationInMinutes > 1.0 ? 'minutes' : 'seconds',
                      style: GoogleFonts.lato(
                        textStyle: Theme.of(context).textTheme.bodySmall,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
              ],
            ),
          ),
        ),
        body: videoController == null
            ? const Center(
                child: Text('Not ready yet!'),
              )
            : Stack(
                children: [
                  Center(
                    child: videoController!.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: videoController!.value.aspectRatio,
                            child: GestureDetector(
                                onTap: () {
                                  pp('$mm Tap happened! Pause the video if playing 🍎 ...');
                                  if (videoController!.value.isPlaying) {
                                    if (mounted) {
                                      setState(() {
                                        videoController!.pause();
                                        _showElapsed = true;
                                      });
                                    }
                                  }
                                },
                                child: VideoPlayer(videoController!)),
                          )
                        : Center(
                            child: Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.0)),
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Text('Video is buffering ...'),
                                )),
                          ),
                  ),
                  _showElapsed
                      ? Positioned(
                          top: 72,
                          left: 4,
                          child: Card(
                            color: Colors.black26,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Text(
                                    'Video paused at:  ',
                                    style: GoogleFonts.lato(
                                      textStyle:
                                          Theme.of(context).textTheme.bodySmall,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    elapsedMinutes >= 1.0
                                        ? elapsedMinutes.toStringAsFixed(2)
                                        : '$elapsedSeconds',
                                    style: GoogleFonts.secularOne(
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    elapsedMinutes > 1.0
                                        ? 'minutes elapsed'
                                        : 'seconds elapsed',
                                    style: GoogleFonts.lato(
                                      textStyle:
                                          Theme.of(context).textTheme.bodySmall,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      : const SizedBox(),
                ],
              ),

          floatingActionButton: _showFloatingButton
            ? FloatingActionButton(
            onPressed: () {
              setState(() {
                if (videoController != null) {
                  _showElapsed = false;
                  videoController!.value.isPlaying
                      ? videoController!.pause()
                      : videoController!.play();
                }
              });
            },
            child: Icon(
              videoController == null ? Icons.pause : Icons.play_arrow,
            ),
          ) : const SizedBox(),


      ),
    );
  }


}
