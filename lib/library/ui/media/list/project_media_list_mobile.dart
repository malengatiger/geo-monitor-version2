import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:page_transition/page_transition.dart';

import '../../../../ui/dashboard/dashboard_mobile.dart';
import '../../../api/sharedprefs.dart';
import '../../../bloc/cloud_storage_bloc.dart';
import '../../../bloc/project_bloc.dart';
import '../../../data/audio.dart';
import '../../../data/user.dart';
import '../../../data/video.dart';
import '../../../emojis.dart';
import '../../../functions.dart';
import '../../../data/photo.dart';
import '../../../data/project.dart';
import '../../camera/play_video.dart';
import '../../project_monitor/project_monitor_mobile.dart';
import '../full_photo/full_photo_mobile.dart';
import 'media_grid.dart';
import 'photo_details.dart';
import 'project_audios.dart';
import 'project_photos.dart';
import 'project_videos.dart';

class ProjectMediaListMobile extends StatefulWidget {
  final Project project;

  const ProjectMediaListMobile({super.key, required this.project});

  @override
  ProjectMediaListMobileState createState() => ProjectMediaListMobileState();
}

class ProjectMediaListMobileState extends State<ProjectMediaListMobile>
    with TickerProviderStateMixin
    implements MediaGridListener {
  late AnimationController _animationController;
  StreamSubscription<List<Photo>>? photoStreamSubscription;
  StreamSubscription<List<Video>>? videoStreamSubscription;
  StreamSubscription<Photo>? newPhotoStreamSubscription;

  String? latest, earliest;
  late TabController _tabController;
  late StreamSubscription<String> killSubscription;


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
    killSubscription = listenForKill(context: context);

    _listen();
    _refresh(false);
  }

  Future<void> _listen() async {
    user ??= await Prefs.getUser();

    _listenToProjectStreams();
    _listenToPhotoStream();
    //
  }

  void _listenToProjectStreams() async {
    pp('$mm .................... Listening to streams from userBloc ....');

    photoStreamSubscription = projectBloc.photoStream.listen((value) {
      pp('$mm Photos received from stream projectPhotoStream: 💙 ${value.length}');
      _photos = value;
      if (mounted) {
        setState(() {});
      } else {
        pp(' 😡😡😡 what the fuck? this thing is not mounted  😡😡😡');
      }
      _animationController.forward();
    });

    videoStreamSubscription = projectBloc.videoStream.listen((value) {
      pp('$mm Videos received from projectVideoStream: 🏈 ${value.length}');
      if (mounted) {
        setState(() {});
      }else {
        pp(' 😡😡😡 what the fuck? this thing is not mounted  😡😡😡');
      }
      _animationController.forward();
    });
  }

  void _listenToPhotoStream() async {
    newPhotoStreamSubscription = cloudStorageBloc.photoStream.listen((mPhoto) {
      pp('${E.blueDot}${E.blueDot} '
          'New photo arrived from newPhotoStreamSubscription: ${mPhoto.toJson()} ${E.blueDot}');
      _photos.add(mPhoto);
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _refresh(bool forceRefresh) async {
    pp('$mm _MediaListMobileState: .......... _refresh ...forceRefresh: $forceRefresh');
    setState(() {
      busy = true;
    });

    try {
      var bag = await projectBloc.refreshProjectData(
          projectId: widget.project.projectId!, forceRefresh: forceRefresh);
      pp('$mm bag has arrived safely! Yeah!! photos: ${bag.photos!.length} videos: ${bag.videos!.length}');
      _photos = bag.photos!;
      setState(() {

      });
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
    photoStreamSubscription!.cancel();
    videoStreamSubscription!.cancel();
    killSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _photos.sort((a, b) => b.created!.compareTo(a.created!));
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        leading: const SizedBox(),
        // title: Column(
        //   children: [
        //     Text(
        //       'Photos & Videos',
        //       style: myTextStyleMedium(context),
        //     ),
        //     // const SizedBox(height: 4,),
        //     // Text('${widget.project.name}', style: myTextStyleSmall(context),),
        //   ],
        // ),
        actions: [
          IconButton(
              onPressed: () {
                pp('...... navigate to take photos');
                _navigateToMonitor();
              },
              icon: Icon(
                Icons.camera_alt,
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
          IconButton(
              onPressed: () {

                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.close,
                size: 18,
                color: Theme.of(context).primaryColor,
              )),
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
                    child: SizedBox(height: 200, width: 200,
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
                    ProjectPhotos(
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
                    ProjectVideos(
                      project: widget.project,
                      refresh: false,
                      onVideoTapped: (Video video) {
                        pp('🍎🍎🍎Video has been tapped: ${video.created!}');
                        setState(() {
                          selectedVideo = video;
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

  Audio? selectedAudio;
  Video? selectedVideo;
  void _navigateToPlayVideo() {
    pp('... play audio from internets');
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.leftToRightWithFade,
            alignment: Alignment.topLeft,
            duration: const Duration(milliseconds: 1000),
            child: PlayVideo(
                project: widget.project,
                video: selectedVideo!)));
  }
  AudioPlayer audioPlayer = AudioPlayer();
  void _navigateToPlayAudio() {
    pp('... play audio from internet ....');
    audioPlayer.setUrl(selectedAudio!.url!);
    audioPlayer.play();
    // Navigator.push(
    //     context,
    //     PageTransition(
    //         type: PageTransitionType.leftToRightWithFade,
    //         alignment: Alignment.topLeft,
    //         duration: const Duration(milliseconds: 1000),
    //         child: PlayVideo(video: selectedAudio!)));
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
                project: widget.project,
                photo: selectedPhoto!)));
    Future.delayed(const Duration(milliseconds: 100), () {});
  }

  void _navigateToMonitor() {
    pp('... about to navigate after waiting 100 ms - should select project if null');

    Future.delayed(const Duration(milliseconds: 100), () {
      Navigator.of(context).pop();
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.leftToRightWithFade,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1500),
              child: ProjectMonitorMobile(
                project: widget.project,
              )));
    });
  }

  @override
  onMediaSelected(mediaBag) {
    // TODO: implement onMediaSelected
    throw UnimplementedError();
  }
}

