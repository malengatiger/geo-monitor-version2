import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/fcm_bloc.dart';
import 'package:geo_monitor/library/ui/media/video_grid.dart';

import '../../../bloc/project_bloc.dart';
import '../../../data/project.dart';
import '../../../data/video.dart';
import '../../../functions.dart';

class ProjectVideosMobile extends StatefulWidget {
  final Project project;
  final bool refresh;
  final Function(Video, int) onVideoTapped;

  const ProjectVideosMobile(
      {super.key,
      required this.project,
      required this.refresh,
      required this.onVideoTapped});

  @override
  State<ProjectVideosMobile> createState() => ProjectVideosMobileState();
}

class ProjectVideosMobileState extends State<ProjectVideosMobile> {
  var videos = <Video>[];
  bool loading = false;
  late StreamSubscription<Video> videoStreamSubscriptionFCM;

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
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${widget.project.name}',
                  style: myTextStyleMediumBold(context),
                ),
              ),
              Expanded(
                child: VideoGrid(
                    videos: videos,
                    crossAxisCount: 2,
                    onVideoTapped: (video, index) {
                      widget.onVideoTapped(video, index);
                    },
                    itemWidth: 300),
              ),
            ],
          );
  }
}
