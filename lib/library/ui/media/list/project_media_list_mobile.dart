import 'dart:async';

import 'package:animations/animations.dart';
import 'package:badges/badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';

import '../../../api/sharedprefs.dart';
import '../../../bloc/cloud_storage_bloc.dart';
import '../../../bloc/project_bloc.dart';
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

  var _photos = <Photo>[];
  var _videos = <Video>[];
  User? user;
  static const mm = '🔆🔆🔆 MediaListMobile 💜💜 ';

  @override
  void initState() {
    _animationController = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 3000),
        reverseDuration: const Duration(milliseconds: 2000),
        vsync: this);
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
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
      _videos = value;
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
      pp('${Emoji.blueDot}${Emoji.blueDot} '
          'New photo arrived from newPhotoStreamSubscription: ${mPhoto.toJson()} ${Emoji.blueDot}');
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
      _videos = bag.videos!;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _photos.sort((a, b) => b.created!.compareTo(a.created!));
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Photos & Videos',
              style: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.bodyMedium,
                fontWeight: FontWeight.w900,
              ),
            ),
            // const SizedBox(height: 4,),
            // Text('${widget.project.name}', style: myTextStyleSmall(context),),
          ],
        ),
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
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0)),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 24.0, right: 24.0, top: 8, bottom: 8),
                  child: Text(
                    'Photos',
                    style: GoogleFonts.lato(
                      textStyle: Theme.of(context).textTheme.bodySmall,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                )),
            Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0)),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 24.0, right: 24.0, top: 8, bottom: 8),
                  child: Text(
                    'Videos',
                    style: GoogleFonts.lato(
                      textStyle: Theme.of(context).textTheme.bodySmall,
                      fontWeight: FontWeight.normal,
                    ),
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
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (BuildContext context, Widget? child) {
                        return FadeScaleTransition(
                          animation: _animationController,
                          child: child,
                        );
                      },
                      child: ProjectPhotos(
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
                    ),
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (BuildContext context, Widget? child) {
                        return FadeScaleTransition(
                          animation: _animationController,
                          child: child,
                        );
                      },
                      child: ProjectVideos(
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
                            _animationController.reverse().then((value) {
                              setState(() {
                                _showPhotoDetail = false;
                              });
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

  Video? selectedVideo;
  void _navigateToPlayVideo() {
    pp('... about to navigate after waiting 100 ms');
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.leftToRightWithFade,
            alignment: Alignment.topLeft,
            duration: const Duration(milliseconds: 1000),
            child: PlayVideo(video: selectedVideo!)));
  }

  void _navigateToFullPhoto() {
    pp('... about to navigate after waiting 100 ms');
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.leftToRightWithFade,
            alignment: Alignment.topLeft,
            duration: const Duration(milliseconds: 1000),
            child: FullPhotoMobile(photo: selectedPhoto!)));
    Future.delayed(const Duration(milliseconds: 100), () {});
  }

  void _navigateToMonitor() {
    pp('... about to navigate after waiting 100 ms - should select project if null');

    Future.delayed(const Duration(milliseconds: 100), () {
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

void heavyTask() {}
