import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:video_player/video_player.dart';

import '../../data/video.dart';
import '../../emojis.dart';
import '../../functions.dart';
import '../ratings/rating_adder_mobile.dart';

class VideoPlayerTabletPage extends StatefulWidget {
  const VideoPlayerTabletPage({
    Key? key,
    required this.video,
    required this.onCloseRequested,
  }) : super(key: key);

  final Video video;
  final Function() onCloseRequested;

  @override
  VideoPlayerTabletPageState createState() => VideoPlayerTabletPageState();
}

class VideoPlayerTabletPageState extends State<VideoPlayerTabletPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  VideoPlayerController? _videoPlayerController;
  late ChewieController _chewieController;
  VoidCallback? videoPlayerListener;
  static const mm = '🔵🔵🔵🔵 VideoPlayerTabletPage 🍎 : ';

  int videoDurationInSeconds = 0;
  double videoDurationInMinutes = 0.0;
  final double _aspectRatio = 16 / 9;

  var videoHeight = 0.0;
  var videoWidth = 0.0;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this);
    super.initState();
    pp('$mm initState: ${widget.video.toJson()}  🔵🔵');
    _videoPlayerController = VideoPlayerController.network(widget.video.url!)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        pp('.......... doing shit with videoController ... setting state .... '
            '$_videoPlayerController 🍎DURATION: ${_videoPlayerController!.value.duration} seconds!');

        var size = _videoPlayerController?.value.size;
        videoHeight = size!.height;
        videoWidth = size.width;
        pp('.......... size of video ... '
            'videoHeight: $videoHeight videoWidth: $videoWidth .... ');

        _videoPlayerController!.addListener(_checkVideo);
        setState(() {
          if (_videoPlayerController != null) {
            videoDurationInSeconds =
                _videoPlayerController!.value.duration.inSeconds;
            videoDurationInMinutes = videoDurationInSeconds / 60;
            _videoPlayerController!.value.isPlaying
                ? _videoPlayerController!.pause()
                : _videoPlayerController!.play();
          }
        });
      });
  }

  void _setChewie(String url) {
    _videoPlayerController = VideoPlayerController.network(url);
    _chewieController = ChewieController(
      allowedScreenSleep: false,
      allowFullScreen: true,
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
      videoPlayerController: _videoPlayerController!,
      aspectRatio: _aspectRatio,
      autoInitialize: true,
      autoPlay: true,
      showControls: true,
    );
    _chewieController.addListener(() {
      if (_chewieController.isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    });
  }

  bool _toggleFloatingButton = true;
  void _checkVideo() {
    if (_videoPlayerController!.value.position ==
        const Duration(seconds: 0, minutes: 0, hours: 0)) {
      setState(() {
        _toggleFloatingButton = false;
      });
    }

    if (_videoPlayerController!.value.isPlaying) {
      setState(() {
        _toggleFloatingButton = false;
      });
    }
    if (_videoPlayerController!.value.isBuffering) {
      setState(() {
        _toggleFloatingButton = false;
      });
    }
    if (!_videoPlayerController!.value.isPlaying) {
      setState(() {
        _toggleFloatingButton = true;
      });
    }
    if (_videoPlayerController!.value.position ==
        _videoPlayerController!.value.duration) {
      pp('$mm video Ended ....');
      setState(() {
        _toggleFloatingButton = true;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (_videoPlayerController != null) {
      pp('Disposing the videoController ... ');
      _videoPlayerController!.dispose();
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
                projectId: widget.video.projectId!,
                videoId: widget.video.videoId!,
              )));
    });
  }

  bool _showElapsed = false;
  @override
  Widget build(BuildContext context) {
    var mDateTime =
        getFormattedDateLongWithTime(widget.video.created!, context);
    var elapsedMinutes = 0.0;
    var elapsedSeconds = 0;
    if (_videoPlayerController != null) {
      elapsedSeconds = _videoPlayerController!.value.position.inSeconds;
      elapsedMinutes = (elapsedSeconds / 60);
    }

    var width = 400.0;
    final ori = MediaQuery.of(context).orientation;
    final tWidth = MediaQuery.of(context).size.width;
    if (ori.name == 'portrait') {
      width = tWidth / 2;
    } else {
      width = tWidth / 3;
    }
    final tHeight = MediaQuery.of(context).size.height;
    // pp('$mm video player: width: $width height: $tHeight');
    return SizedBox(
      width: width,
      height: tHeight - 120,
      child: Card(
        shape: getRoundedBorder(radius: 16),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                      onPressed: () {
                        widget.onCloseRequested();
                      },
                      icon: const Icon(Icons.close)),
                ],
              ),
              Text(
                '${widget.video.projectName}',
                style: myTextStyleLarge(context),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                mDateTime,
                style: myTextStyleSmall(context),
              ),
              const SizedBox(
                height: 2,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(onPressed: _onFavorite, child: Text(E.heartBlue)),
                  const SizedBox(
                    width: 28,
                  ),
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
                height: 8,
              ),
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: _videoPlayerController!.value.isInitialized
                          ? AspectRatio(
                              aspectRatio:
                                  _videoPlayerController!.value.aspectRatio,
                              child: GestureDetector(
                                  onTap: () {
                                    pp('$mm Tap happened! Pause the video if playing 🍎 ...');
                                    if (_videoPlayerController!
                                        .value.isPlaying) {
                                      if (mounted) {
                                        setState(() {
                                          _videoPlayerController!.pause();
                                          _showElapsed = true;
                                        });
                                      }
                                    }
                                  },
                                  child: SizedBox(
                                      height: 500,
                                      child: VideoPlayer(
                                          _videoPlayerController!))),
                            )
                          : Center(
                              child: Card(
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16.0)),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Text('Video is buffering ...'),
                                  )),
                            ),
                    ),
                    _showElapsed
                        ? Positioned(
                            top: 24,
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
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
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
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ))
                        : const SizedBox(),
                    Positioned(
                        bottom: 12,
                        right: 12,
                        child: FloatingActionButton(
                          backgroundColor: Theme.of(context).primaryColor,
                          onPressed: () {
                            setState(() {
                              if (_videoPlayerController != null) {
                                _showElapsed = false;
                                _videoPlayerController!.value.isPlaying
                                    ? _videoPlayerController!.pause()
                                    : _videoPlayerController!.play();
                              }
                            });
                          },
                          child: Icon(
                            _videoPlayerController == null
                                ? Icons.pause
                                : _toggleFloatingButton
                                    ? Icons.play_arrow
                                    : Icons.stop,
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
