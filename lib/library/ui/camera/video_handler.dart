import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/bloc/fcm_bloc.dart';
import 'package:geo_monitor/library/data/project.dart';
import 'package:geo_monitor/library/data/project_position.dart';
import 'package:geo_monitor/library/data/video.dart';
import 'package:geo_monitor/library/emojis.dart';
import 'package:geo_monitor/library/ui/camera/chewie_video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../../device_location/device_location_bloc.dart';
import '../../bloc/project_bloc.dart';
import '../../bloc/video_for_upload.dart';
import '../../cache_manager.dart';
import '../../data/position.dart';
import '../../data/project_polygon.dart';
import '../../data/user.dart';
import '../../functions.dart';
import '../../generic_functions.dart';
import '../media/list/project_media_list_mobile.dart';

class VideoHandler extends StatefulWidget {
  const VideoHandler({Key? key, required this.project, this.projectPosition})
      : super(key: key);
  final Project project;
  final ProjectPosition? projectPosition;
  @override
  VideoHandlerState createState() => VideoHandlerState();
}

class VideoHandlerState extends State<VideoHandler>
    with SingleTickerProviderStateMixin {
  final mm =
      '${E.blueDot}${E.blueDot}${E.blueDot}${E.blueDot} VideoHandler: 🌿';

  late AnimationController _controller;
  final ImagePicker _picker = ImagePicker();
  late StreamSubscription orientStreamSubscription;
  late StreamSubscription<String> killSubscription;

  var polygons = <ProjectPolygon>[];
  var positions = <ProjectPosition>[];
  var videos = <Video>[];
  User? user;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listen();
    _observeOrientation();
    _getData();
    //_startVideo();
  }

  Future<void> _observeOrientation() async {
    pp('${E.blueDot} ........ _observeOrientation ... ');
    Stream<NativeDeviceOrientation> stream =
        NativeDeviceOrientationCommunicator()
            .onOrientationChanged(useSensor: true);
    orientStreamSubscription = stream.listen((event) {
      // pp('${E.blueDot}${E.blueDot} orientation, name: ${event.name} index: ${event.index}');
    });
  }

  late StreamSubscription<Video> videoSubscription;

  void _listen() async {
    videoSubscription = fcmBloc.videoStream.listen((event) {
      videos.add(event);
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _getData() async {
    setState(() {
      busy = true;
    });
    try {
      user = await prefsOGx.getUser();
      pp('$mm .......... getting project positions and polygons');
      polygons = await projectBloc.getProjectPolygons(
          projectId: widget.project.projectId!, forceRefresh: false);
      positions = await projectBloc.getProjectPositions(
          projectId: widget.project.projectId!, forceRefresh: false);
      videos = await projectBloc.getProjectVideos(
          projectId: widget.project.projectId!, forceRefresh: false);
      pp('$mm positions: ${positions.length} polygons: ${polygons.length} found');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }

    setState(() {
      busy = false;
    });
  }

  int start = 0;
  VideoPlayerController? _videoPlayerController;
  void _startVideo() async {
    pp('$mm video making started ....');
    setState(() {
      videoIsReady = false;
    });
    var minutes = 0;
    var settings = await prefsOGx.getSettings();
    if (settings != null) {
      minutes = settings.maxVideoLengthInMinutes!;
    }

    final XFile? file = await _picker
        .pickVideo(
            source: ImageSource.camera,
            maxDuration: Duration(minutes: minutes),
            preferredCameraDevice: CameraDevice.rear)
        .whenComplete(() {});

    if (file != null) {
      await _processFile(file);
      setState(() {});
    }

    // file.saveTo(path);
  }

  File? finalFile, thumbnailFile;
  Future<void> _processFile(XFile file) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    const x = '/video';
    final File mFile =
        File('${directory.path}$x${DateTime.now().millisecondsSinceEpoch}.mp4');

    const z = '/video_thumbnail';
    final File tFile =
        File('${directory.path}$z${DateTime.now().millisecondsSinceEpoch}.jpg');

    File mImageFile = File(file.path);
    await mImageFile.copy(mFile.path);
    pp('$mm _processFile 🔵🔵🔵 video file to upload: ${mFile.path}'
        ' size: ${await mFile.length()} bytes 🔵');

    var thumbnailFile0 = await getVideoThumbnail(mImageFile);
    await thumbnailFile0.copy(tFile.path);

    pp('$mm _processFile 🔵🔵🔵 video file to upload: ${mFile.path}'
        ' size: ${await mFile.length()} bytes 🔵');

    setState(() {
      finalFile = mFile;
      thumbnailFile = tFile;
    });

    var size = await finalFile!.length();
    var m = (size / 1024 / 1024).toStringAsFixed(2);
    pp('$mm Video made is $m MB in size');
    await _danceWithTheVideo(
      videoFile: mFile,
      thumbnailFile: tFile,
    );
    if (mounted) {
      showToast(
          context: context,
          message: 'Video file saved on device, size: $m MB',
          backgroundColor: Theme.of(context).primaryColor,
          textStyle: Styles.whiteSmall,
          toastGravity: ToastGravity.TOP,
          duration: const Duration(seconds: 2));
    }
  }

  Future<void> _danceWithTheVideo({
    required File videoFile,
    required File thumbnailFile,
  }) async {
    pp('$mm.......... _danceWithTheVideo ... Take Me To Church!!');
    var loc = await locationBloc.getLocation();
    Position? position;
    if (loc != null) {
      position =
          Position(type: 'Point', coordinates: [loc.longitude, loc.latitude]);
    }
    var videoForUpload = VideoForUpload(
        userName: user!.name,
        userThumbnailUrl: user!.thumbnailUrl,
        userId: user!.userId,
        organizationId: user!.organizationId,
        filePath: videoFile.path,
        thumbnailPath: thumbnailFile.path,
        project: widget.project,
        videoId: const Uuid().v4(),
        durationInSeconds: 0,
        position: position,
        width: 0.0,
        height: 0.0,
        date: DateTime.now().toUtc().toIso8601String());

    await cacheManager.addVideoForUpload(video: videoForUpload);
  }

  void _startNextVideo() {
    pp('$mm _startNextVideo ................');
    _startVideo();
  }

  @override
  void dispose() {
    _controller.dispose();
    killSubscription.cancel();
    super.dispose();
  }

  String? fileUrl, thumbnailUrl;

  void _navigateToList() {
    Navigator.of(context).pop();
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(milliseconds: 1500),
            child: ProjectMediaListMobile(project: widget.project)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back_ios)),
        title: Text(
          '${widget.project.name}',
          style: myTextStyleSmall(context),
        ),
        actions: [
          IconButton(
              onPressed: _navigateToList,
              icon: Icon(
                Icons.list,
                color: Theme.of(context).primaryColor,
              )),
          // IconButton(
          //     onPressed: _onCancel,
          //     icon: Icon(
          //       Icons.close,
          //       color: Theme.of(context).primaryColor,
          //     )),
        ],
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/intro/pic2.jpg'),
                  opacity: 0.1,
                  fit: BoxFit.cover),
            ),
          ),
          Positioned(
              left: 80,
              right: 20,
              top: 200,
              child: Opacity(
                  opacity: 0.1,
                  child: Text(
                    '${videos.length}',
                    style: myNumberStyleLargest(context),
                  ))),
          Positioned(
            left: 24,
            right: 24,
            bottom: 20,
            child: SizedBox(
              height: 60,
              child: Card(
                elevation: 4,
                color: Colors.black12,
                shape: getRoundedBorder(radius: 16),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 4,
                    ),
                    SizedBox(
                      width: 200,
                      child: TextButton(
                          onPressed: _startNextVideo,
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Text('Make Video'),
                          )),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  bool videoIsReady = false;

  Video? _currentVideo;

  void _navigateToPlayer() {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: ChewieVideoPlayer(
              project: widget.project,
            )));
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }
}

final mxx =
    '${E.heartBlue}${E.heartBlue}${E.heartBlue}${E.heartBlue} Isolate: ';

class GCSMessage {
  late double totalBytes, bytesTransferred;
  late int statusCode;
  late String message;

  GCSMessage(
      {required this.totalBytes,
      required this.bytesTransferred,
      required this.statusCode,
      required this.message});
}
