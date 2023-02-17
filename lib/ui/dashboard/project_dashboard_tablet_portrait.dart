import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geo_monitor/library/ui/maps/project_map_mobile.dart';
import 'package:geo_monitor/library/ui/media/list/project_media_list_mobile.dart';
import 'package:geo_monitor/ui/activity/geo_activity_tablet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../library/bloc/downloader.dart';
import '../../library/data/audio.dart';
import '../../library/data/photo.dart';
import '../../library/data/project.dart';
import '../../library/data/user.dart';
import '../../library/data/video.dart';
import '../../library/emojis.dart';
import '../../library/functions.dart';
import '../../library/ui/camera/video_player_tablet.dart';
import '../../library/ui/maps/photo_map_tablet.dart';
import '../../library/ui/maps/project_polygon_map_mobile.dart';
import '../audio/audio_player_page.dart';
import 'project_dashboard_grid.dart';

class ProjectDashboardTabletPortrait extends StatefulWidget {
  const ProjectDashboardTabletPortrait({
    Key? key,
    required this.project,
  }) : super(key: key);
  final Project project;
  @override
  ProjectDashboardTabletPortraitState createState() =>
      ProjectDashboardTabletPortraitState();
}

class ProjectDashboardTabletPortraitState
    extends State<ProjectDashboardTabletPortrait>
    with TickerProviderStateMixin {
  var busy = false;
  User? user;

  static const mm = '🎽🎽🎽🎽🎽🎽 ProjectDashboardTabletPortrait: 🎽';
  bool networkAvailable = false;
  final dur = 600;

  @override
  void initState() {
    super.initState();
  }

  final _key = GlobalKey<ScaffoldState>();

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
    final height = MediaQuery.of(context).size.height;

    final width1 = width - 300;
    const width2 = 280.0;
    return SafeArea(
      child: Scaffold(
        key: _key,
        appBar: AppBar(
          actions: [
            IconButton(
              icon: Icon(
                Icons.refresh,
                size: 28,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                setState(() {});
              },
            )
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(180),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    'Project Dashboard',
                    style: myTextStyleLarge(context),
                  ),
                  const SizedBox(
                    height: 48,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        widget.project.name!,
                        style: GoogleFonts.lato(
                            textStyle: Theme.of(context).textTheme.titleLarge,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).primaryColor),
                      ),
                      // const SizedBox(
                      //   width: 100,
                      // ),
                      IconButton(
                          onPressed: _navigateToPositionsMap,
                          icon: const Icon(
                            Icons.map,
                            size: 28.0,
                          ))
                    ],
                  ),
                  const SizedBox(
                    height: 28,
                  ),
                ],
              ),
            ),
          ),
        ),
        body: busy
            ? const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    backgroundColor: Colors.pink,
                  ),
                ),
              )
            : Stack(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: width1,
                        child: ProjectDashboardGrid(
                          showProjectName: false,
                          topPadding: 48,
                          onTypeTapped: (type) {
                            switch (type) {
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
                          },
                          project: widget.project,
                        ),
                      ),
                      SizedBox(
                        width: width2,
                        child: GeoActivityTablet(
                          width: width2,
                          project: widget.project,
                          thinMode: true,
                          showPhoto: (photo) {
                            showPhoto(photo);
                          },
                          showVideo: (video) {
                            showVideo(video);
                          },
                          showAudio: (audio) {
                            showAudio(audio);
                          },
                          forceRefresh: true,
                        ),
                      )
                    ],
                  ),
                  _showPhoto
                      ? Positioned(
                          left: 100,
                          right: 100,
                          top: 12,
                          child: SizedBox(
                            width: 600,
                            height: 800,
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
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 12,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 48.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${photo!.projectName}',
                                                style:
                                                    myTextStyleLargePrimaryColor(
                                                        context),
                                              ),
                                              IconButton(
                                                  onPressed: () {
                                                    pp('$mm .... put photo on a map!');
                                                    _navigateToPhotoMap();
                                                  },
                                                  icon: Icon(
                                                    Icons.location_on,
                                                    color: Theme.of(context)
                                                        .primaryColor,
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
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 2.0, vertical: 2.0),
                                          child: InteractiveViewer(
                                              child: CachedNetworkImage(
                                                  fit: BoxFit.fill,
                                                  progressIndicatorBuilder: (context,
                                                          url,
                                                          downloadProgress) =>
                                                      Center(
                                                          child: SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child: CircularProgressIndicator(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .pink,
                                                                  value: downloadProgress
                                                                      .progress))),
                                                  errorWidget: (context, url, error) =>
                                                      const Icon(Icons.error),
                                                  fadeInDuration: const Duration(
                                                      milliseconds: 1500),
                                                  fadeInCurve:
                                                      Curves.easeInOutCirc,
                                                  placeholderFadeInDuration:
                                                      const Duration(milliseconds: 1500),
                                                  imageUrl: photo!.url!)),
                                        ),
                                        const SizedBox(
                                          height: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ))
                      : const SizedBox(),
                  _showVideo
                      ? Positioned(
                          left: 20,
                          top: -8,
                          child: SizedBox(
                            width: 360,
                            height: height - 360,
                            child: VideoPlayerTabletPage(
                              video: video!,
                              onCloseRequested: () {
                                if (mounted) {
                                  setState(() {
                                    _showVideo = false;
                                  });
                                }
                              },
                            ),
                          ),
                        )
                      : const SizedBox(),
                  _showAudio
                      ? Positioned(
                          left: 100,
                          right: 100,
                          top: 160,
                          child: AudioPlayerCard(
                            audio: audio!,
                            onCloseRequested: () {
                              if (mounted) {
                                setState(() {
                                  _showAudio = false;
                                });
                              }
                            },
                          ))
                      : const SizedBox(),
                ],
              ),
      ),
    );
  }

  bool _showPhoto = false;
  bool _showVideo = false;
  bool _showAudio = false;
  void showPhoto(Photo photo) {
    this.photo = photo;
    setState(() {
      _showPhoto = true;
      _showVideo = false;
      _showAudio = false;
    });
  }

  void showVideo(Video video) {
    this.video = video;
    setState(() {
      _showPhoto = false;
      _showVideo = true;
      _showAudio = false;
    });
  }

  void showAudio(Audio audio) {
    this.audio = audio;
    setState(() {
      _showPhoto = false;
      _showVideo = false;
      _showAudio = true;
    });
  }
}

//////
void showKillDialog({required String message, required BuildContext context}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(
        "Critical App Message",
        style: myTextStyleLarge(ctx),
      ),
      content: Text(
        message,
        style: myTextStyleMedium(ctx),
      ),
      shape: getRoundedBorder(radius: 16),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            pp('$mm Navigator popping for the last time, Sucker! 🔵🔵🔵');
            var android = UniversalPlatform.isAndroid;
            var ios = UniversalPlatform.isIOS;
            if (android) {
              SystemNavigator.pop();
            }
            if (ios) {
              Navigator.of(ctx).pop();
              Navigator.of(ctx).pop();
            }
          },
          child: const Text("Exit the App"),
        ),
      ],
    ),
  );
}

final mm = '${E.heartRed}${E.heartRed}${E.heartRed}${E.heartRed} Dashboard: ';
