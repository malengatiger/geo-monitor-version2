import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/data/project.dart';
import 'package:geo_monitor/library/ui/camera/video_controls.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../device_location/device_location_bloc.dart';
import '../../bloc/geo_uploader.dart';
import '../../bloc/video_for_upload.dart';
import '../../cache_manager.dart';
import '../../data/position.dart';
import '../../data/project_position.dart';
import '../../functions.dart';
import '../../generic_functions.dart';

List<CameraDescription> cameras = [];

class VideoHandlerTwo extends StatefulWidget {
  const VideoHandlerTwo({Key? key, required this.project, this.projectPosition})
      : super(key: key);

  final Project project;
  final ProjectPosition? projectPosition;

  @override
  VideoHandlerTwoState createState() => VideoHandlerTwoState();
}

class VideoHandlerTwoState extends State<VideoHandlerTwo>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  static const mm = '🍏🍏🍏🍏🍏🍏 VideoHandlerTwo: ';

  final resolutionPresets = ResolutionPreset.values;
  ResolutionPreset currentResolutionPreset = ResolutionPreset.high;

  late CameraController _cameraController;

  CameraDescription? cameraDescription;
  bool _isCameraInitialized = false;
  Timer? timer;
  Duration duration = const Duration(seconds: 0);
  Duration finalDuration = const Duration(seconds: 0);
  bool _showChoice = false;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    pp('$mm initState cameras: ${cameras.length} ...');
    super.initState();
    // Hide the status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _getData();
  }

  int maxSeconds = 10;
  void _getData() async {
    setState(() {
      busy = true;
    });
    try {
      user = await prefsOGx.getUser();
      cameras = await availableCameras();
      var settings = await prefsOGx.getSettings();
      if (settings != null) {
        maxSeconds = settings.maxVideoLengthInSeconds!;
      }
      pp('$mm video recording limit: $maxSeconds seconds');
      onNewCameraSelected(cameras[0]);
    } catch (e) {
      pp(e);
      if (mounted) {
        showToast(message: '$e', context: context);
      }
    }

    setState(() {
      busy = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    pp('$mm didChangeAppLifecycleState: $state');
    final CameraController cameraController = _cameraController;

    // App state changed before we got the chance to initialize.
    if (!cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
      onNewCameraSelected(cameraController.description);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    timer?.cancel();
    timer = null;
    super.dispose();
  }

  bool _isRecordingInProgress = false;

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    pp('$mm onNewCameraSelected: $cameraDescription');
    // final previousCameraController = _cameraController;
    // Instantiating the camera controller
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Dispose the previous controller
    // await previousCameraController.dispose();

    // Replace with the new controller
    if (mounted) {
      setState(() {
        _cameraController = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    // Initialize controller
    try {
      pp('$mm cameraController.initialize() ...');
      await cameraController.initialize();
      pp('$mm cameraController.initialized!');
    } on CameraException catch (e) {
      pp('Error initializing camera: $e');
    }

    // Update the Boolean
    if (mounted) {
      setState(() {
        _isCameraInitialized = _cameraController!.value.isInitialized;
      });
    }
  }

  void startTimer() async {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      duration = Duration(seconds: timer.tick);
      if (timer.tick > maxSeconds) {
        pp('$mm video recording limit reached ... will stop!');
        stopVideoRecording();
        showToast(message: 'Recording limit reached', context: context);
      }
      setState(() {});
    });
  }

  Future<void> startVideoRecording() async {
    pp('$mm startVideoRecording ...');
    final CameraController cameraController = _cameraController;
    if (_cameraController!.value.isRecordingVideo) {
      pp('$mm A recording has already started, do nothing.');
      return;
    }
    try {
      setState(() {
        _isRecordingInProgress = true;
        isRecording = false;
        _showChoice = false;
        pp('$mm _isRecordingInProgress: $_isRecordingInProgress');
      });
      duration == const Duration(seconds: 0);
      startTimer();
      await cameraController!.startVideoRecording();
    } on CameraException catch (e) {
      pp('Error starting to record video: $e');
    }
  }

  XFile? file;
  String fileSize = '0';
  Future<XFile?> stopVideoRecording() async {
    pp('$mm stopVideoRecording ... 🔴');

    if (!_cameraController!.value.isRecordingVideo) {
      // Recording is already is stopped state
      return null;
    }
    try {
      file = await _cameraController!.stopVideoRecording();
      timer!.cancel();
      fileSize = getFileSizeString(bytes: await file!.length(), decimals: 2);
      pp('$mm Error stopping video recording, file size: '
          '$fileSize');
      finalDuration = Duration(seconds: duration.inSeconds);
      setState(() {
        _isRecordingInProgress = false;
        isRecording = false;
        duration = const Duration(seconds: 0);
        _showChoice = true;
        pp('$mm setting state:_isRecordingInProgress: $_isRecordingInProgress');
      });

      return file;
    } on CameraException catch (e) {
      pp('$mm Error stopping video recording: $e');
      return null;
    }
  }

  void _processFile() async {
    setState(() {
      _showChoice = false;
    });
    var bytes = await file?.length();
    var size = getFileSizeString(bytes: bytes!, decimals: 2);
    pp('\n\n$mm _processFile ... video file size: $size ');
    final Directory directory = await getApplicationDocumentsDirectory();
    const x = '/video';
    final File mFile =
        File('${directory.path}$x${DateTime.now().millisecondsSinceEpoch}.mp4');

    const z = '/video_thumbnail';
    final File tFile =
        File('${directory.path}$z${DateTime.now().millisecondsSinceEpoch}.jpg');

    File mImageFile = File(file!.path);
    await mImageFile.copy(mFile.path);
    pp('$mm _processFile 🔵🔵🔵 video file to upload: ${mFile.path}'
        ' size: ${await mFile.length()} bytes 🔵');

    var thumbnailFile0 = await getVideoThumbnail(mImageFile);
    await thumbnailFile0.copy(tFile.path);

    pp('$mm.......... _danceWithTheVideo ... Take Me To Church!!');
    var loc = await locationBloc.getLocation();
    Position? position;
    if (loc != null) {
      position =
          Position(type: 'Point', coordinates: [loc.longitude, loc.latitude]);
    }
    // var bytes = await videoFile.readAsBytes();
    // var tBytes = await thumbnailFile.readAsBytes();
    var videoForUpload = VideoForUpload(
        userName: user!.name,
        userThumbnailUrl: user!.thumbnailUrl,
        userId: user!.userId,
        organizationId: user!.organizationId,
        filePath: mFile.path,
        thumbnailPath: tFile.path,
        project: widget.project,
        videoId: const Uuid().v4(),
        durationInSeconds: finalDuration.inSeconds,
        position: position,
        width: 0.0,
        height: 0.0,
        date: DateTime.now().toUtc().toIso8601String(),
        fileBytes: null,
        thumbnailBytes: null);

    await cacheManager.addVideoForUpload(video: videoForUpload);
    geoUploader.manageMediaUploads();
    if (mounted) {
      showToast(
          duration: const Duration(seconds: 3),
          padding: 16,
          textStyle: myTextStyleMediumBold(context),
          toastGravity: ToastGravity.TOP,
          backgroundColor: Theme.of(context).primaryColor,
          message: 'Video will be uploaded soon!',
          context: context);
    }
  }

  void pauseVideoRecording() {}
  void resumeVideoRecording() {}

  bool isPlaying = false;
  bool isPaused = false;
  bool isStopped = false;
  bool isRecording = false;

  void onRecord() {
    pp('$mm onRecord ...figure out how to record ...');
    startVideoRecording();
  }

  void onPlay() {
    //todo - figure out how to play
    pp('$mm onPlay ...figure out how to play ...');
  }

  void onPause() {
    pp('$mm onPause ...figure out how to pause ...');
    pauseVideoRecording();
  }

  void onStop() {
    stopVideoRecording();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: Stack(
        children: [
          _isCameraInitialized
              ? _showChoice
                  ? Positioned(
                      top: 200,
                      left: 20,
                      right: 20,
                      child: SizedBox(
                        height: 360,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 40,
                            ),
                            Text(
                              'Recording complete',
                              style: myTextStyleLarge(context),
                            ),
                            const SizedBox(
                              height: 40,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('File Size'),
                                const SizedBox(
                                  width: 12,
                                ),
                                Text(
                                  fileSize,
                                  style:
                                      myNumberStyleLargePrimaryColor(context),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Duration'),
                                const SizedBox(
                                  width: 12,
                                ),
                                Text(
                                  getHourMinuteSecond(finalDuration),
                                  style:
                                      myNumberStyleLargePrimaryColor(context),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 32,
                            ),
                            ChoiceCard(
                                onUpload: onUpload,
                                onPlay: onPlay,
                                onCancel: onCancel),
                          ],
                        ),
                      ))
                  : AspectRatio(
                      aspectRatio: 1 / _cameraController.value.aspectRatio,
                      child: _cameraController.buildPreview(),
                    )
              : Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Getting camera ready',
                        style: myTextStyleMediumBold(context),
                      ),
                    ),
                  ),
                ),
          Positioned(
              right: 8,
              top: 8,
              child: Card(
                shape: getRoundedBorder(radius: 16),
                color: Colors.black12,
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    getHourMinuteSecond(duration),
                    style: myTextStyleMediumPrimaryColor(context),
                  ),
                ),
              )),
          Positioned(
              bottom: 8,
              right: 100,
              left: 100,
              child: VideoControls(
                onRecord: onRecord,
                onPlay: onPlay,
                onPause: onPause,
                onStop: onStop,
                isPlaying: isPlaying,
                isPaused: isPaused,
                isStopped: isStopped,
                isRecording: isRecording,
                onClose: () {
                  Navigator.of(context).pop();
                },
              )),
        ],
      ),
    ));
  }

  void onUpload() {
    pp('$mm onUpload tapped');
    _processFile();
  }

  void onCancel() {
    pp('$mm onCancel tapped');
  }
}

class ChoiceCard extends StatelessWidget {
  const ChoiceCard(
      {Key? key,
      required this.onUpload,
      required this.onPlay,
      required this.onCancel})
      : super(key: key);

  final Function onUpload;
  final Function onPlay;
  final Function onCancel;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: 360,
      child: Card(
        elevation: 8,
        shape: getRoundedBorder(radius: 16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                  onPressed: () {
                    onUpload();
                  },
                  icon: const Icon(Icons.upload)),
              IconButton(
                  onPressed: () {
                    onPlay();
                  },
                  icon: const Icon(Icons.play_arrow)),
              IconButton(
                  onPressed: () {
                    onCancel();
                  },
                  icon: const Icon(Icons.cancel)),
            ],
          ),
        ),
      ),
    );
  }
}
