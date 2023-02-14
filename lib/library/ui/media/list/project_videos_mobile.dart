import 'dart:async';

import 'package:badges/badges.dart' as bd;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/fcm_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

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
              SizedBox(
                height: 48,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    widget.project.name!,
                    style: myTextStyleMediumBold(context),
                  ),
                ),
              ),
              Expanded(
                  child: bd.Badge(
                badgeStyle: bd.BadgeStyle(
                  badgeColor: Theme.of(context).primaryColor,
                  elevation: 8,
                  padding: const EdgeInsets.all(8),
                ),
                position: bd.BadgePosition.topEnd(top: 4, end: 4),
                // padding: const EdgeInsets.all(12.0),
                badgeContent: Text(
                  '${videos.length}',
                  style: GoogleFonts.lato(
                      textStyle: Theme.of(context).textTheme.bodySmall,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                      fontSize: 10),
                ),
                // badgeColor: Colors.black,
                // elevation: 16,
                child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisSpacing: 1,
                            crossAxisCount: 2,
                            mainAxisSpacing: 1),
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      var video = videos.elementAt(index);
                      // var dt = getFormattedDateShortestWithTime(
                      //     video.created!, context);
                      return Stack(
                        children: [
                          SizedBox(
                            width: 300,
                            child: GestureDetector(
                              onTap: () {
                                widget.onVideoTapped(video,index);
                              },
                              child: CachedNetworkImage(
                                  imageUrl: video.thumbnailUrl!,
                                  fit: BoxFit.cover),
                            ),
                          ),
                        ],
                      );
                    }),
              )),
            ],
          );
  }
}
