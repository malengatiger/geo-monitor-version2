import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:geo_monitor/library/ui/camera/chewie_video_player.dart';
import 'package:geo_monitor/library/ui/camera/video_handler_two.dart';
import 'package:just_audio/just_audio.dart';
import 'package:page_transition/page_transition.dart';

import '../../../../ui/audio/audio_handler.dart';
import '../../../api/prefs_og.dart';
import '../../../bloc/project_bloc.dart';
import '../../../data/audio.dart';
import '../../../data/photo.dart';
import '../../../data/project.dart';
import '../../../data/user.dart';
import '../../../data/video.dart';
import '../../../functions.dart';
import '../../camera/photo_handler.dart';
import '../full_photo/full_photo_mobile.dart';
import 'photo_details.dart';
import 'project_audios_mobile.dart';
import 'project_photos_mobile.dart';
import 'project_videos_mobile.dart';

class ProjectMediaListMobile extends StatefulWidget {
  final Project project;

  const ProjectMediaListMobile({super.key, required this.project});

  @override
  ProjectMediaListMobileState createState() => ProjectMediaListMobileState();
}

class ProjectMediaListMobileState extends State<ProjectMediaListMobile>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  StreamSubscription<List<Photo>>? photoStreamSubscription;
  StreamSubscription<List<Video>>? videoStreamSubscription;
  StreamSubscription<Photo>? newPhotoStreamSubscription;

  String? latest, earliest;
  late TabController _tabController;

  var _photos = <Photo>[];
  User? user;
  static const mm = '🔆🔆🔆 MediaListMobile 💜💜 ';

  @override
  void initState() {
    _animationController = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 3000),
        reverseDuration: const Duration(milliseconds: 500),
        vsync: this);
    _tabController = TabController(length: 3, vsync: this);
    super.initState();

    _listen();
    _refresh(false);
  }

  Future<void> _listen() async {
    user ??= await prefsOGx.getUser();

    _listenToProjectStreams();
    _listenToPhotoStream();
  }

  void _listenToProjectStreams() async {
    pp('$mm .................... Listening to streams from userBloc ....');

    photoStreamSubscription = projectBloc.photoStream.listen((value) {
      pp('$mm Photos received from stream projectPhotoStream: 💙 ${value.length}');
      _photos = value;
      if (mounted) {
        _animationController.forward();
        setState(() {});
      } else {
        pp(' 😡😡😡 what the fuck? this thing is not mounted  😡😡😡');
      }
    });

    videoStreamSubscription = projectBloc.videoStream.listen((value) {
      pp('$mm Videos received from projectVideoStream: 🏈 ${value.length}');
      if (mounted) {
        _animationController.forward();
        setState(() {});
      } else {
        pp(' 😡😡😡 what the fuck? this thing is not mounted  😡😡😡');
      }
    });
  }

  void _listenToPhotoStream() async {
    // newPhotoStreamSubscription = cloudStorageBloc.photoStream.listen((mPhoto) {
    //   pp('${E.blueDot}${E.blueDot} '
    //       'New photo arrived from newPhotoStreamSubscription: ${mPhoto.toJson()} ${E.blueDot}');
    //   _photos.add(mPhoto);
    //   if (mounted) {
    //     setState(() {});
    //   }
    // // });
  }

  Future<void> _refresh(bool forceRefresh) async {
    pp('$mm _MediaListMobileState: .......... _refresh ...forceRefresh: $forceRefresh');
    setState(() {
      busy = true;
    });

    try {
      var map = await getStartEndDates();
      final startDate = map['startDate'];
      final endDate = map['endDate'];
      var bag = await projectBloc.refreshProjectData(
          projectId: widget.project.projectId!,
          forceRefresh: forceRefresh, startDate: startDate!, endDate: endDate!);
      pp('$mm bag has arrived safely! Yeah!! photos: ${bag.photos!.length} videos: ${bag.videos!.length}');
      _photos = bag.photos!;
      setState(() {});
      _animationController.forward();
    } catch (e) {
      pp('$mm ...... refresh problem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }

    setState(() {
      busy = false;
    });
  }

  bool _showPhotoDetail = false;
  Photo? selectedPhoto;

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Audio? selectedAudio;
  Video? selectedVideo;
  int videoIndex = 0;
  void _navigateToPlayVideo() {
    pp('... play audio from internets');
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.leftToRightWithFade,
            alignment: Alignment.topLeft,
            duration: const Duration(milliseconds: 1000),
            child: ChewieVideoPlayer(
              project: widget.project,
              videoIndex: videoIndex,
            )));
  }

  AudioPlayer audioPlayer = AudioPlayer();
  void _navigateToPlayAudio() {
    pp('... play audio from internet ....');
    audioPlayer.setUrl(selectedAudio!.url!);
    audioPlayer.play();
  }

  void _navigateToFullPhoto() {
    pp('... about to navigate after waiting 100 ms');
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.leftToRightWithFade,
            alignment: Alignment.topLeft,
            duration: const Duration(milliseconds: 1000),
            child: FullPhotoMobile(
                project: widget.project, photo: selectedPhoto!)));
    Future.delayed(const Duration(milliseconds: 100), () {});
  }

  void _startPhotoMonitoring() async {
    pp('🍏 🍏 Start Photo Monitoring this project after checking that the device is within '
        ' 🍎 ${widget.project.monitorMaxDistanceInMetres} metres 🍎 of a project point within ${widget.project.name}');
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.fade,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: PhotoHandler(
              project: widget.project,
              projectPosition: null,
            )));
  }

  void _startVideoMonitoring() async {
    pp('🍏 🍏 Start Video Monitoring this project after checking that the device is within '
        ' 🍎 ${widget.project.monitorMaxDistanceInMetres} metres 🍎 of a project point within ${widget.project.name}');
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.fade,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: VideoHandlerTwo(
              project: widget.project,
              projectPosition: null, onClose: (){
                Navigator.of(context).pop();
            },
            )));
  }

  void _startAudioMonitoring() async {
    pp('🍏 🍏 Start Audio Monitoring this project after checking that the device is within '
        ' 🍎 ${widget.project.monitorMaxDistanceInMetres} metres 🍎 of a project point within ${widget.project.name}');
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.fade,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: AudioHandler(
              project: widget.project, onClose: (){
                Navigator.of(context).pop();
            },
            )));
  }

  @override
  Widget build(BuildContext context) {
    _photos.sort((a, b) => b.created!.compareTo(a.created!));
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        // leading: IconButton(
        //     onPressed: () {
        //       Navigator.of(context).pop();
        //     },
        //     icon: const Icon(Icons.arrow_back_ios)),
        actions: [
          IconButton(
              onPressed: () {
                pp('...... navigate to take photos');
                _startPhotoMonitoring();
              },
              icon: Icon(
                Icons.camera_alt,
                size: 18,
                color: Theme.of(context).primaryColor,
              )),
          IconButton(
              onPressed: () {
                pp('...... navigate to make video');
                _startVideoMonitoring();
              },
              icon: Icon(
                Icons.video_camera_front,
                size: 18,
                color: Theme.of(context).primaryColor,
              )),
          IconButton(
              onPressed: () {
                pp('...... navigate to make audio');
                _startAudioMonitoring();
              },
              icon: Icon(
                Icons.mic,
                size: 18,
                color: Theme.of(context).primaryColor,
              )),
          IconButton(
              onPressed: () {
                _refresh(true);
              },
              icon: Icon(
                Icons.refresh,
                size: 18,
                color: Theme.of(context).primaryColor,
              )),
          // IconButton(
          //     onPressed: () {
          //       Navigator.of(context).pop();
          //     },
          //     icon: Icon(
          //       Icons.close,
          //       size: 18,
          //       color: Theme.of(context).primaryColor,
          //     )),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 4.0, right: 4.0, top: 4, bottom: 4),
                  child: Text(
                    'Photos',
                    style: myTextStyleSmall(context),
                  ),
                )),
            Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 4.0, right: 4.0, top: 4, bottom: 4),
                  child: Text(
                    'Videos',
                    style: myTextStyleSmall(context),
                  ),
                )),
            Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 4.0, right: 4.0, top: 4, bottom: 4),
                  child: Text(
                    'Audio',
                    style: myTextStyleSmall(context),
                  ),
                )),
          ],
        ),
      ),
      body: Stack(
        children: [
          busy
              ? Center(
                  child: Card(
                    shape: getRoundedBorder(radius: 16),
                    elevation: 8,
                    child: SizedBox(
                      height: 200,
                      width: 200,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: const [
                            SizedBox(
                              height: 40,
                            ),
                            Text('Loading ...'),
                            SizedBox(
                              height: 48,
                            ),
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                backgroundColor: Colors.pink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    ProjectPhotosMobile(
                      project: widget.project,
                      refresh: false,
                      onPhotoTapped: (Photo photo) {
                        pp('🔷🔷🔷Photo has been tapped: ${photo.created!}');
                        selectedPhoto = photo;
                        setState(() {
                          _showPhotoDetail = true;
                        });
                        _animationController.forward();
                      },
                    ),
                    ProjectVideosMobile(
                      project: widget.project,
                      refresh: false,
                      onVideoTapped: (Video video, int index) {
                        pp('🍎🍎🍎Video has been tapped: ${video.created!}');
                        setState(() {
                          selectedVideo = video;
                          videoIndex = index;
                        });
                        _navigateToPlayVideo();
                      },
                    ),
                    ProjectAudios(
                      project: widget.project,
                      refresh: false,
                      onAudioTapped: (Audio audio) {
                        pp('🍎🍎🍎Audio has been tapped: ${audio.created!}');
                        setState(() {
                          selectedAudio = audio;
                        });
                        _navigateToPlayAudio();
                      },
                    ),
                  ],
                ),
          _showPhotoDetail
              ? Positioned(
                  left: 28,
                  top: 48,
                  child: SizedBox(
                    width: 260,
                    child: GestureDetector(
                      onTap: () {
                        pp('🍏🍏🍏🍏Photo tapped - navigate to full photo');
                        _animationController.reverse().then((value) {
                          setState(() {
                            _showPhotoDetail = false;
                          });
                          _navigateToFullPhoto();
                        });
                      },
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (BuildContext context, Widget? child) {
                          return FadeScaleTransition(
                            animation: _animationController,
                            child: child,
                          );
                        },
                        child: PhotoDetails(
                          photo: selectedPhoto!,
                          separatorPadding: 4,
                          width: 300,
                          onClose: () {
                            setState(() {
                              _showPhotoDetail = false;
                            });
                          },
                        ),
                      ),
                    ),
                  ))
              : const SizedBox(),
        ],
      ),
    ));
  }
}
