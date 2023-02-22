import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/fcm_bloc.dart';
import 'package:geo_monitor/library/ui/media/video_grid.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../../bloc/project_bloc.dart';
import '../../../data/project.dart';
import '../../../data/video.dart';

class ProjectVideosTablet extends StatefulWidget {
  final Project project;
  final bool refresh;
  final Function(Video, int) onVideoTapped;

  const ProjectVideosTablet(
      {super.key,
      required this.project,
      required this.refresh,
      required this.onVideoTapped});

  @override
  State<ProjectVideosTablet> createState() => ProjectVideosTabletState();
}

class ProjectVideosTabletState extends State<ProjectVideosTablet> {
  var videos = <Video>[];
  bool loading = false;
  late StreamSubscription<Video> videoStreamSubscriptionFCM;
  bool _showVideoPlayer = false;
  Video? _selectedVideo;
  @override
  void initState() {
    super.initState();
    _subscribeToStreams();
    _getVideos();
  }

  void _subscribeToStreams() async {
    videoStreamSubscriptionFCM = fcmBloc.videoStream.listen((event) {
      if (mounted) {
        _getVideos();
      }
    });
  }

  void _getVideos() async {
    setState(() {
      loading = true;
    });
    videos = await projectBloc.getProjectVideos(
        projectId: widget.project.projectId!, forceRefresh: widget.refresh);
    videos.sort((a, b) => b.created!.compareTo(a.created!));
    setState(() {
      loading = false;
    });
  }

  @override
  void dispose() {
    videoStreamSubscriptionFCM.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return videos.isEmpty
        ? Center(
            child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0)),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No videos in project'),
                )),
          )
        : OrientationLayoutBuilder(landscape: (context) {
            return VideoGrid(
                videos: videos,
                onVideoTapped: (video, index) {
                  _selectedVideo = video;
                  setState(() {
                    _showVideoPlayer = true;
                  });
                },
                itemWidth: 300,
                crossAxisCount: 6);
          }, portrait: (context) {
            return VideoGrid(
                videos: videos,
                onVideoTapped: (video, index) {
                  _selectedVideo = video;
                  setState(() {
                    _showVideoPlayer = true;
                  });
                },
                itemWidth: 300,
                crossAxisCount: 6);
          });
  }
}
