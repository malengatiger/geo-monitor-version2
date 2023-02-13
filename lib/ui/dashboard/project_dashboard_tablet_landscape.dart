import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geo_monitor/library/bloc/downloader.dart';
import 'package:geo_monitor/library/ui/maps/project_map_mobile.dart';
import 'package:geo_monitor/library/ui/maps/project_polygon_map_mobile.dart';
import 'package:geo_monitor/library/ui/media/list/project_media_list_mobile.dart';
import 'package:geo_monitor/ui/dashboard/project_dashboard_grid.dart';
import 'package:page_transition/page_transition.dart';

import '../../library/data/audio.dart';
import '../../library/data/photo.dart';
import '../../library/data/project.dart';
import '../../library/data/video.dart';
import '../../library/functions.dart';
import '../../library/ui/maps/photo_map_tablet.dart';
import '../activity/geo_activity.dart';

class ProjectDashboardTabletLandscape extends StatefulWidget {
  const ProjectDashboardTabletLandscape({Key? key, required this.project})
      : super(key: key);

  final Project project;

  @override
  ProjectDashboardTabletLandscapeState createState() =>
      ProjectDashboardTabletLandscapeState();
}

class ProjectDashboardTabletLandscapeState
    extends State<ProjectDashboardTabletLandscape>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _navigateToMedia() async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: ProjectMediaListMobile(
              project: widget.project,
            )));
  }

  _navigateToPositionsMap() async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: ProjectMapMobile(
              project: widget.project,
            )));
  }

  _navigateToPolygonsMap() async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: ProjectPolygonMapMobile(
              project: widget.project,
            )));
  }

  bool _showPhoto = false;
  bool _showVideo = false;
  bool _showAudio = false;
  final mm = ' 🍔 🍔 🍔 🍔 🍔 🍔ProjectDashboardTabletLandscape: ';

  void _displayPhoto(Photo photo) async {
    pp('$mm _displayPhoto ...');
    this.photo = photo;
    setState(() {
      _showPhoto = true;
      _showVideo = false;
      _showAudio = false;
    });
  }

  void _displayVideo(Video video) async {
    pp('$mm _displayVideo ...');
    this.video = video;
    setState(() {
      _showPhoto = false;
      _showVideo = true;
      _showAudio = false;
    });
  }

  void _displayAudio(Audio audio) async {
    pp('$mm _displayAudio ...');
    this.audio = audio;
    setState(() {
      _showPhoto = false;
      _showVideo = false;
      _showAudio = true;
    });
  }

  Photo? photo;
  Video? video;
  Audio? audio;
  void _navigateToPhotoMap() {
    pp('$mm _navigateToPhotoMap ...');

    if (mounted) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.scale,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1000),
              child: PhotoMapTablet(
                photo: photo!,
              )));
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Project Dashboard',
          style: myTextStyleLarge(context),
        ),
      ),
      body: Stack(
        children: [
          Row(
            children: [
              SizedBox(
                width: width / 2,
                height: 500,
                child: Center(
                  child: ProjectDashboardGrid(
                      topPadding: 32,
                      showProjectName: true,
                      onTypeTapped: onTypeTapped,
                      project: widget.project),
                ),
              ),
              GeoActivity(
                width: width / 2,
                thinMode: false,
                showPhoto: (photo) {
                  _displayPhoto(photo);
                },
                showVideo: (video) {
                  _displayVideo(video);
                },
                showAudio: (audio) {
                  _displayAudio(audio);
                },
              ),
            ],
          ),
          _showPhoto
              ? Positioned(
                  left: 0,
                  top: 0,
                  child: SizedBox(
                    width: 420,
                    height: 640,
                    // color: Theme.of(context).primaryColor,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showPhoto = false;
                          });
                        },
                        child: Card(
                          shape: getRoundedBorder(radius: 16),
                          elevation: 8,
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 12,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${photo!.projectName}',
                                      style: myTextStyleMediumPrimaryColor(
                                          context),
                                    ),
                                    IconButton(
                                        onPressed: () {
                                          pp('$mm .... put photo on a map!');
                                          _navigateToPhotoMap();
                                        },
                                        icon: Icon(
                                          Icons.location_on,
                                          color: Theme.of(context).primaryColor,
                                          size: 24,
                                        )),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Text(
                                '${photo!.userName}',
                                style: myTextStyleSmallBold(context),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                getFormattedDateShortWithTime(
                                    photo!.created!, context),
                                style: myTextStyleTiny(context),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 2.0, vertical: 2.0),
                                  child: InteractiveViewer(
                                      child: CachedNetworkImage(
                                          fit: BoxFit.cover,
                                          progressIndicatorBuilder: (context,
                                                  url, downloadProgress) =>
                                              Center(
                                                  child: SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child: CircularProgressIndicator(
                                                          backgroundColor:
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                          value: downloadProgress
                                                              .progress))),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                          fadeInDuration: const Duration(
                                              milliseconds: 1500),
                                          fadeInCurve: Curves.easeInOutCirc,
                                          placeholderFadeInDuration:
                                              const Duration(milliseconds: 1500),
                                          imageUrl: photo!.url!)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ))
              : const SizedBox(),
          _showVideo
              ? Positioned(
                  child: Container(
                  width: 480,
                  height: 640,
                  color: Colors.red,
                ))
              : const SizedBox(),
          _showAudio
              ? Positioned(
                  child: Container(
                  width: 480,
                  height: 640,
                  color: Colors.green,
                ))
              : const SizedBox(),
        ],
      ),
    ));
  }

  onTypeTapped(int p1) {
    switch (p1) {
      case typePhotos:
        _navigateToMedia();
        break;
      case typeVideos:
        _navigateToMedia();
        break;
      case typeAudios:
        _navigateToMedia();
        break;
      case typePositions:
        _navigateToPositionsMap();
        break;
      case typePolygons:
        _navigateToPolygonsMap();
        break;
    }
  }
}
