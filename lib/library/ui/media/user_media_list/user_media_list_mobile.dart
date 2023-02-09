import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';

import '../../../api/prefs_og.dart';
import '../../../bloc/cloud_storage_bloc.dart';
import '../../../bloc/organization_bloc.dart';
import '../../../bloc/user_bloc.dart';
import '../../../data/project.dart';
import '../../../data/user.dart';
import '../../../data/video.dart';
import '../../../emojis.dart';
import '../../../functions.dart';
import '../../../data/photo.dart';
import '../../camera/play_video.dart';
import '../../project_monitor/project_monitor_mobile.dart';
import '../full_photo/full_photo_mobile.dart';
import '../list/media_grid.dart';
import '../list/photo_details.dart';
import '../list/user_photos.dart';
import '../list/user_videos.dart';

class UserMediaListMobile extends StatefulWidget {
  final User user;

  const UserMediaListMobile({super.key, required this.user});

  @override
  MediaListMobileState createState() => MediaListMobileState();
}

class MediaListMobileState extends State<UserMediaListMobile>
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
  bool _showProjectChooser = false;
  User? user;
  static const mm = '🔆🔆🔆 UserMediaListMobile 💜💜 ';

  @override
  void initState() {
    _animationController = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 2000),
        reverseDuration: const Duration(milliseconds: 1000),
        vsync: this);
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
    _listen();
  }

  Future<void> _listen() async {
    user ??= await prefsOGx.getUser();

    _listenToProjectStreams();
    _listenToPhotoStream();
    //
    if (mounted) {
      _refresh(false);
    }
  }

  void _listenToProjectStreams() async {
    pp('$mm .................... Listening to streams from userBloc ....');

    photoStreamSubscription = userBloc.photoStream.listen((value) {
      pp('$mm Photos received from stream projectPhotoStream: 💙 ${value.length}');
      _photos = value;
      _photos.sort((a, b) => b.created!.compareTo(a.created!));
      if (mounted) {
        setState(() {});
      }
    });

    videoStreamSubscription = userBloc.videoStream.listen((value) {
      pp('$mm:Videos received from projectVideoStream: 🏈 ${value.length}');
      _videos = value;
      _videos.sort((a, b) => b.created!.compareTo(a.created!));
      if (mounted) {
        setState(() {});
      }
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

    //todo - refactor userBloc.refreshUserData ....
    // await userBloc.refreshUserData(
    //     userId: widget.user.userId!, forceRefresh: forceRefresh);

    setState(() {
      busy = false;
    });
  }

  bool _showPhotoDetail = false;
  Photo? selectedPhoto;
  Project? project;
  @override
  void dispose() {
    _animationController.dispose();
    photoStreamSubscription!.cancel();
    videoStreamSubscription!.cancel();
    super.dispose();
  }

  onSelected(Project p1) {
    setState(() {
      project = p1;
      _showProjectChooser = false;
    });
    _navigateToMonitor();
  }

  @override
  Widget build(BuildContext context) {
    _photos.sort((a, b) => b.created!.compareTo(a.created!));
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Photos & Videos',
          style: GoogleFonts.lato(
            textStyle: Theme.of(context).textTheme.bodyMedium,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
              onPressed: () {
                pp('...... navigate to take photos');
                setState(() {
                  _showProjectChooser = true;
                });
              },
              icon: Icon(
                Icons.camera_alt,
                size: 20,
                color: Theme.of(context).primaryColor,
              )),
          IconButton(
              onPressed: () {
                pp('...... refresh photos');
                _refresh(true);
              },
              icon: Icon(Icons.refresh,
                  size: 20, color: Theme.of(context).primaryColor)),
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
                      left: 12.0, right: 12.0, top: 8, bottom: 8),
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
                      left: 12.0, right: 12.0, top: 8, bottom: 8),
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
          TabBarView(
            controller: _tabController,
            children: [
              UserPhotos(
                user: widget.user,
                refresh: true,
                onPhotoTapped: (Photo photo) {
                  pp('🔷🔷🔷Photo has been tapped: ${photo.created!}');
                  selectedPhoto = photo;
                  setState(() {
                    _showPhotoDetail = true;
                  });
                  _animationController.forward();
                },
              ),
              UserVideos(
                user: widget.user,
                refresh: true,
                onVideoTapped: (Video video) {
                  pp('🍎🍎🍎Video has been tapped: ${video.created!}');
                  setState(() {
                    selectedVideo = video;
                  });
                  _navigateToPlayVideo();
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
                          separatorPadding: 8,
                          width: 300,
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
          _showProjectChooser
              ? Positioned(child: ProjectChooserOriginal(onSelected: onSelected))
              : const SizedBox(),
        ],
      ),
    ));
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
                project: project!,
                photo: selectedPhoto!)));
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
            child: PlayVideo(
                project: project!,
                video: selectedVideo!)));
  }

  void _navigateToMonitor() {
    pp('${E.redDot}... about to navigate after waiting 100 ms - should select project if null');

    Future.delayed(const Duration(milliseconds: 100), () {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.leftToRightWithFade,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1500),
              child: ProjectMonitorMobile(
                project: project!,
              )));
    });
  }

  @override
  onMediaSelected(mediaBag) {
    // TODO: implement onMediaSelected
    throw UnimplementedError();
  }
}

class ProjectChooserOriginal extends StatefulWidget {
  const ProjectChooserOriginal({Key? key, required this.onSelected}) : super(key: key);
  final Function(Project) onSelected;
  @override
  State<ProjectChooserOriginal> createState() => _ProjectChooserOriginalState();
}

class _ProjectChooserOriginalState extends State<ProjectChooserOriginal> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  var _projects = <Project>[];
  User? user;
  bool loading = false;
  @override
  void initState() {
    _animationController = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 2000),
        reverseDuration: const Duration(milliseconds: 2000),
        vsync: this);
    super.initState();
    _getProjects(false);
  }
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _getProjects(bool forceRefresh) async {
    setState(() {
      loading = true;
    });
    user = await prefsOGx.getUser();
    _projects = await organizationBloc.getOrganizationProjects(
        organizationId: user!.organizationId!, forceRefresh: forceRefresh);

    setState(() {
      loading = false;
    });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        loading
            ? Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: const [
                        Text('Loading ...'),
                        SizedBox(
                          width: 28,
                        ),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            backgroundColor: Colors.pink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0)),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                     SizedBox(
                      height: 20, child: Text('Tap to Select Project', style: myTextStyleMedium(context)),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    _projects.isEmpty
                        ? const SizedBox()
                        : Expanded(
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (BuildContext context, Widget? child) {
                                return FadeScaleTransition(animation: _animationController, child: child,);
                              },
                              child: ListView.builder(
                                  itemCount: _projects.length,
                                  itemBuilder: (context, index) {
                                    var proj = _projects.elementAt(index);
                                    return GestureDetector(
                                      onTap: () {
                                        widget.onSelected(proj);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.0),
                                        child: Card(
                                            child: Row(
                                          children: [
                                            Text(E.blueDot),
                                            const SizedBox(
                                              width: 4,
                                            ),
                                            Flexible(
                                                child: Text(
                                              '${proj.name}',
                                              style: myTextStyleSmall(context),
                                            )),
                                          ],
                                        )),
                                      ),
                                    );
                                  }),
                            ),
                          ),
                  ],
                ),
              ),
      ],
    );
  }
}
