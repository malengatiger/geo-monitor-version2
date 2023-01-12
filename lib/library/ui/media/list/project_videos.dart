import 'package:badges/badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../bloc/project_bloc.dart';
import '../../../data/photo.dart';
import '../../../data/project.dart';
import '../../../data/video.dart';
import '../../../functions.dart';

class ProjectVideos extends StatefulWidget {
  final Project project;
  final bool refresh;
  final Function(Video) onVideoTapped;

  const ProjectVideos(
      {super.key,
      required this.project,
      required this.refresh,
      required this.onVideoTapped});

  @override
  State<ProjectVideos> createState() => _ProjectPhotosState();
}

class _ProjectPhotosState extends State<ProjectVideos> {
  var videos = <Video>[];
  bool loading = false;
  @override
  void initState() {
    super.initState();
    _subscribeToStreams();
    _getVideos();
  }

  void _subscribeToStreams() async {}
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
              Container(
                color: Colors.blue,
                height: 2,
              ),
              Expanded(
                  child: Badge(
                position: BadgePosition.topEnd(top: 8, end: 12),
                badgeContent: Text(
                  '${videos.length}',
                  style: GoogleFonts.lato(
                      textStyle: Theme.of(context).textTheme.bodySmall,
                      fontWeight: FontWeight.normal,
                      color: Colors.white),
                ),
                badgeColor: Colors.indigo,
                elevation: 16,
                child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisSpacing: 1,
                            crossAxisCount: 2,
                            mainAxisSpacing: 1),
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      var video = videos.elementAt(index);
                      var dt = getFormattedDateShortestWithTime(
                          video.created!, context);
                      return Stack(
                        children: [
                          SizedBox(
                            width: 300,
                            child: GestureDetector(
                              onTap: () {
                                widget.onVideoTapped(video);
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
