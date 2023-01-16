// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:geo_monitor/library/data/position.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path_provider/path_provider.dart';

import 'package:video_player/video_player.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import '../../api/sharedprefs.dart';
import '../../bloc/cloud_storage_bloc.dart';
import '../../bloc/project_bloc.dart';
import '../../data/project.dart';
import '../../data/project_polygon.dart';
import '../../data/project_position.dart';
import '../../data/user.dart';
import '../../data/video.dart';
import '../../emojis.dart';
import '../../functions.dart';
import '../../generic_functions.dart';
import '../../location/loc_bloc.dart';
import '../media/list/project_media_list_mobile.dart';
import '../media/user_media_list/user_media_list_mobile.dart';

class FieldPhotoCamera extends StatefulWidget {
  final Project project;
  final ProjectPosition? projectPosition;

  const FieldPhotoCamera(
      {super.key, required this.project, this.projectPosition});

  @override
  FieldPhotoCameraState createState() {
    return FieldPhotoCameraState();
  }
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
    default:
      throw ArgumentError('Unknown lens direction');
  }
}

void logError(String code, String? message) {
  if (message != null) {
    pp('Error: $code\nError Message: $message');
  } else {
    pp('Error: $code');
  }
}

class FieldPhotoCameraState extends State<FieldPhotoCamera>
    with WidgetsBindingObserver, TickerProviderStateMixin
    implements StorageBlocListener {
  CameraController? _cameraController;
  XFile? imageFile;
  XFile? videoFile;
  VideoPlayerController? videoController;
  VoidCallback? videoPlayerListener;
  bool enableAudio = true;

  late AnimationController _flashModeControlRowAnimationController;
  late AnimationController _exposureModeControlRowAnimationController;
  final double _minAvailableZoom = 1.0;
  final double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  User? user;
  var polygons = <ProjectPolygon>[];
  static const mm = '🍎🍎🍎 FieldPhotoCamera 🍎 : ';

  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;

  @override
  void initState() {
    super.initState();
    _observeOrientation();
    _getCameras();
    _getUser();
    _getPolygons();

    _flashModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _exposureModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _getUser() async {
    user = await Prefs.getUser();
  }

  void _getPolygons() async {
    polygons = await projectBloc.getProjectPolygons(
        projectId: widget.project.projectId!, forceRefresh: false);
  }

  @override
  void dispose() {
    _flashModeControlRowAnimationController.dispose();
    _exposureModeControlRowAnimationController.dispose();
    if (videoController != null) {
      videoController!.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    pp('$mm didChangeAppLifecycleState ....');
    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      pp('$mm call onNewCameraSelected: 🥏 ....');
      _onNewCameraSelected(cameraController.description);
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final bool _showGrid = false;

  void _getCameras() async {
    cameras = await availableCameras();
    pp('$mm Found ${cameras.length} cameras');
    for (var camera in cameras) {
      pp('$mm _getCameras:camera: ${camera.name}  🔵 ${camera.lensDirection.toString()}');
    }

    cameras = [cameras.first];
    _onNewCameraSelected(cameras.first);
    setState(() {});
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _getCameraPreviewWidget() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return Listener(
        onPointerDown: (_) => _pointers++,
        onPointerUp: (_) => _pointers--,
        child: CameraPreview(
          _cameraController!,
          child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onTapDown: (details) => onViewFinderTap(details, constraints),
            );
          }),
        ),
      );
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (_pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await _cameraController!.setZoomLevel(_currentScale);
  }

  /// Display the thumbnail of the captured image or video.
  // Widget _thumbnailWidget() {
  //   final VideoPlayerController? localVideoController = videoController;
  //
  //   return Expanded(
  //     child: Align(
  //       alignment: Alignment.centerRight,
  //       child: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: <Widget>[
  //           localVideoController == null && imageFile == null
  //               ? Container()
  //               : SizedBox(
  //                   width: 64.0,
  //                   height: 64.0,
  //                   child: (localVideoController == null)
  //                       ? Image.file(File(imageFile!.path))
  //                       : Container(
  //                           decoration: BoxDecoration(
  //                               border: Border.all(color: Colors.green)),
  //                           child: Center(
  //                             child: AspectRatio(
  //                                 aspectRatio:
  //                                     localVideoController.value.aspectRatio,
  //                                 child: VideoPlayer(localVideoController)),
  //                           ),
  //                         ),
  //                 ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _getCaptureControlRowWidget() {
    final CameraController? cameraController = _cameraController;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        IconButton(
          icon: const Icon(
            Icons.camera_alt,
            size: 32,
          ),
          color: Colors.blue,
          onPressed: cameraController != null &&
                  cameraController.value.isInitialized &&
                  !cameraController.value.isRecordingVideo
              ? _onTakePictureButtonPressed
              : null,
        ),
        // IconButton(
        //   icon: const Icon(Icons.videocam),
        //   color: Colors.blue,
        //   onPressed: cameraController != null &&
        //           cameraController.value.isInitialized &&
        //           !cameraController.value.isRecordingVideo
        //       ? onVideoRecordButtonPressed
        //       : null,
        // ),
        // IconButton(
        //   icon: cameraController != null &&
        //           cameraController.value.isRecordingPaused
        //       ? const Icon(Icons.play_arrow)
        //       : const Icon(Icons.pause),
        //   color: Colors.blue,
        //   onPressed: cameraController != null &&
        //           cameraController.value.isInitialized &&
        //           cameraController.value.isRecordingVideo
        //       ? (cameraController.value.isRecordingPaused)
        //           ? onResumeButtonPressed
        //           : onPauseButtonPressed
        //       : null,
        // ),
        // IconButton(
        //   icon: const Icon(Icons.stop),
        //   color: Colors.red,
        //   onPressed: cameraController != null &&
        //           cameraController.value.isInitialized &&
        //           cameraController.value.isRecordingVideo
        //       ? onStopButtonPressed
        //       : null,
        // ),
        // IconButton(
        //   icon: const Icon(Icons.pause_presentation),
        //   color:
        //       cameraController != null && cameraController.value.isPreviewPaused
        //           ? Colors.red
        //           : Colors.blue,
        //   onPressed:
        //       cameraController == null ? null : onPausePreviewButtonPressed,
        // ),
      ],
    );
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    pp('$mm ... onViewFinderTap ....');
    if (_cameraController == null) {
      return;
    }

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    if (_cameraController != null) {
      _cameraController!.setExposurePoint(offset);
      _cameraController!.setFocusPoint(offset);
    }
    _onTakePictureButtonPressed();
  }

  void _onNewCameraSelected(CameraDescription cameraDescription) async {
    pp('$mm onNewCameraSelected .... cameraDescription: ${cameraDescription.name} ${cameraDescription.lensDirection}');
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }
    pp('$mm onNewCameraSelected .... setting up new cameraController with camera description');

    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // If the controller is updated then update the UI.
    _cameraController!.addListener(() {
      if (mounted) setState(() {});
      if (_cameraController!.value.hasError) {
        showToast(
            message: 'Camera error ${_cameraController!.value.errorDescription}',
            textStyle: const TextStyle(color: Colors.white),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.pink,
            context: context);
      }
    });

    try {
      await _cameraController!.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  // final List<File> _imageFiles = [];
  late StreamSubscription orientStreamSubscription;
  NativeDeviceOrientation? _deviceOrientation;

  Future<void> _observeOrientation() async {
    pp('${Emoji.blueDot} ........ _observeOrientation ... ');
    Stream<NativeDeviceOrientation> stream =
        NativeDeviceOrientationCommunicator()
            .onOrientationChanged(useSensor: true);
    orientStreamSubscription = stream.listen((event) {
      pp('${Emoji.blueDot}${Emoji.blueDot} orientation, name: ${event.name} index: ${event.index}');
      _deviceOrientation = event;
    });
  }

  Future<void> _onTakePictureButtonPressed() async {
    if (_deviceOrientation != null) {
      pp('$mm onTakePictureButtonPressed; last saved orientation: 🔵 '
          '${_deviceOrientation!.name}');
    }
    if (widget.projectPosition == null) {
      bool isWithin = await _doThePolygonCheck();
      if (isWithin) {
        _doThePicture();
        return;
      } else {
        _doTheMessage();
      }
    } else {
      bool isValid = await isLocationValid(
          projectPosition: widget.projectPosition!,
          validDistance: widget.project.monitorMaxDistanceInMetres!);
      if (!isValid) {
        bool isWithin = await _doThePolygonCheck();
        if (!isWithin) {
          _doTheMessage();
        } else {
          _doThePicture();
        }
      } else {
        _doThePicture();
      }
    }
  }

  void _doTheMessage() {
    const msg = 'You are no longer in range of one of the project location(s). Photos of the project cannot be taken from here';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          duration: Duration(seconds: 5),
          content: Text(
              msg)));

      showToast(
          message: msg,
          textStyle: const TextStyle(color: Colors.white),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.pink,
          context: context);
    }
  }

  Future<bool> _doThePolygonCheck() async {
    var loc = await locationBloc.getLocation();
    var isWithin = checkIfLocationIsWithinPolygons(
        polygons: polygons, latitude: loc.latitude, longitude: loc.longitude);
    return isWithin;
  }

  void _doThePicture() async {
    takePicture().then((XFile? file) async {
      if (videoController != null) {
        videoController!.dispose();
        videoController = null;
      }
      if (mounted) {
        setState(() {
          imageFile = file;
        });

        if (file != null) {
          File mImageFile = File(file.path);
          pp('$mm onTakePictureButtonPressed 🔵🔵🔵 file to upload, '
              'size: ${await mImageFile.length()} bytes🔵');

          var thumbnailFile =
              await getThumbnail(file: mImageFile, isVideo: false);
          bool isLandscape = false;
          if (_deviceOrientation != null) {
            switch (_deviceOrientation!.name) {
              case 'landscapeLeft':
                isLandscape = true;
                break;
              case 'landscapeRight':
                isLandscape = true;
                break;
            }
          } else {
            pp('_deviceOrientation is null, wtf?? means that user did not change device orientation ..........');
          }
          pp('$mm ... isLandscape: $isLandscape - check if true!  🍎');
          //can i force
          File? mFile;
          if (_deviceOrientation != null) {
            mFile = await _processOrientation(mImageFile, _deviceOrientation!);
          } else {
            mFile = mImageFile;
          }

          cloudStorageBloc.errorStream.listen((event) {
            if (mounted) {
              showToast(
                  message: event,toastGravity: ToastGravity.TOP,
                  textStyle: const TextStyle(color: Colors.white),
                  duration: const Duration(seconds: 3),
                  backgroundColor: Colors.pink.shade400,
                  context: context);
            }
          });

          if (widget.projectPosition != null) {
            cloudStorageBloc.uploadPhotoOrVideo(
                listener: this,
                file: mFile,
                thumbnailFile: thumbnailFile,
                project: widget.project,
                projectPositionId: widget.projectPosition!.projectPositionId!,
                projectPosition: widget.projectPosition!.position!,
                isVideo: false,
                isLandscape: isLandscape);
          } else {
            var loc = await locationBloc.getLocation();
            var position = Position(
                type: 'Point', coordinates: [loc.longitude, loc.latitude]);
            var polygon = getPolygonUserIsWithin(
                polygons: polygons,
                latitude: loc.latitude,
                longitude: loc.longitude);
            cloudStorageBloc.uploadPhotoOrVideo(
                listener: this,
                file: mFile,
                thumbnailFile: thumbnailFile,
                project: widget.project,
                projectPolygonId: polygon?.projectPolygonId,
                projectPosition: position,
                isVideo: false,
                isLandscape: isLandscape);
          }

          var size = await mFile.length();
          var m = (size / 1024 / 1024).toStringAsFixed(2);
          pp('$mm Picture taken is $m MB in size');
          showToast(
              context: context,
              message: 'Picture file saved on device, size: $m MB',
              backgroundColor: Colors.teal,
              textStyle: Styles.whiteSmall,
              toastGravity: ToastGravity.TOP,
              duration: const Duration(seconds: 2));

          setState(() {});
        }
      }
    });
  }

  Future<File> _getVideoThumbnail(File file) async {
    final Directory directory = await getApplicationDocumentsDirectory();

    var path = 'possibleVideoThumb_${DateTime.now().toIso8601String()}.jpg';
    final thumbFile = File('${directory.path}/$path');

    final data = await vt.VideoThumbnail.thumbnailData(
      video: file.path,
      imageFormat: vt.ImageFormat.JPEG,
      maxWidth:
          128, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
      quality: 25,
    );
    await thumbFile.writeAsBytes(data!);
    pp('$mm Video thumbnail created. length: ${await thumbFile.length()} 🔷🔷🔷');
    return thumbFile;
  }

  Future<File> getThumbnail({required File file, required bool isVideo}) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    if (isVideo) {
      var m = _getVideoThumbnail(file); //path to asset
      return m;
    }

    img.Image? image = img.decodeImage(file.readAsBytesSync());
    var thumbnail = img.copyResize(image!, width: 160);
    final File mFile = File(
        '${directory.path}/thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg');
    var thumb = mFile..writeAsBytesSync(img.encodeJpg(thumbnail, quality: 90));
    var len = await thumb.length();
    pp('$mm ....... 💜 .... thumbnail generated: 😡 ${(len / 1024).toStringAsFixed(1)} KB');
    return thumb;
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      showToast(
          message:'Error: please select a camera first',
          textStyle: const TextStyle(color: Colors.white),
          duration: const Duration(seconds: 10),
          backgroundColor: Colors.pink,
          context: context);
      return null;
    }
    if (cameraController.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showToast(
        message: 'Error: ${e.code}\n${e.description}',
        textStyle: const TextStyle(color: Colors.white),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.pink,
        context: context);
  }

  String? totalByteCount, bytesTransferred;
  String? fileUrl, thumbnailUrl;

  @override
  onFileProgress(int totalByteCount, int bytesTransferred) {
    pp('$mm 🍏file Upload progress: bytesTransferred: ${(bytesTransferred / 1024).toStringAsFixed(1)} KB '
        'of totalByteCount: ${(totalByteCount / 1024).toStringAsFixed(1)} KB');
    setState(() {
      this.totalByteCount = '${(totalByteCount / 1024).toStringAsFixed(1)} KB';
      this.bytesTransferred =
          '${(bytesTransferred / 1024).toStringAsFixed(1)} KB';
    });
  }

  @override
  onFileUploadComplete(String url, int totalByteCount, int bytesTransferred) {
    pp('$mm 😡 file Upload has been completed 😡 bytesTransferred: ${(bytesTransferred / 1024).toStringAsFixed(1)} KB '
        'of totalByteCount: ${(totalByteCount / 1024).toStringAsFixed(1)} KB');
    if (mounted) {
      setState(() {});
    }
  }

  @override
  onThumbnailProgress(int totalByteCount, int bytesTransferred) {
    pp('$mm 🍏thumbnail Upload progress: bytesTransferred: ${(bytesTransferred / 1024).toStringAsFixed(1)} KB '
        'of totalByteCount: ${(totalByteCount / 1024).toStringAsFixed(1)} KB');
  }

  @override
  onThumbnailUploadComplete(
      String url, int totalByteCount, int bytesTransferred) async {
    pp('$mm 🍏thumbnail Upload has been completed 😡 bytesTransferred: ${(bytesTransferred / 1024).toStringAsFixed(1)} KB '
        'of totalByteCount: ${(totalByteCount / 1024).toStringAsFixed(1)} KB');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Field Camera',
            style: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.bodyMedium,
                fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
              onPressed: onListButtonPressed, icon: const Icon(Icons.list)),
        ],
      ),
      body: Stack(
        children: [
          _showGrid
              ? Container()
              : Column(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(
                            color: _cameraController != null
                                ? Theme.of(context).primaryColorLight
                                : Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: _getCameraPreviewWidget(),
                        ),
                      ),
                    ),
                    _getCaptureControlRowWidget(),
                    // _modeControlRowWidget(),
                  ],
                ),
        ],
      ),
    );
  }

  void onListButtonPressed() {
    pp('$mm onListButtonPressed ...');
    Navigator.of(context).pop();
    if (user!.userType == UserType.fieldMonitor) {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.leftToRightWithFade,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1500),
              child: UserMediaListMobile(user: user!)));
    } else {
      Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.leftToRightWithFade,
              alignment: Alignment.topLeft,
              duration: const Duration(milliseconds: 1500),
              child: ProjectMediaListMobile(project: widget.project)));
    }
  }

  Future<File> _processOrientation(
      File file, NativeDeviceOrientation deviceOrientation) async {
    pp('$mm _processOrientation: attempt to rotate image file ...');
    switch (deviceOrientation.name) {
      case 'landscapeLeft':
        pp('$mm landscapeLeft ....');
        break;
      case 'landscapeRight':
        pp('$mm landscapeRight ....');
        break;
      case 'portraitUp':
        return file;
      case 'portraitDown':
        return file;
    }
    final appDocumentDirectory = await getApplicationDocumentsDirectory();
    final File mFile = File(
        '${appDocumentDirectory.path}/rotatedImageFile${DateTime.now().millisecondsSinceEpoch}.jpg');

    final img.Image? capturedImage = img.decodeImage(await file.readAsBytes());
    var orientedImage = img.copyRotate(capturedImage!, angle: 270);

    await File(mFile.path).writeAsBytes(img.encodeJpg(orientedImage));

    final heightOrig = capturedImage.height;
    final widthOrig = capturedImage.width;

    final height = orientedImage.height;
    final width = orientedImage.width;

    pp('$mm _processOrientation: rotated file has 😡height: $height 😡width: $width, 🔵 '
        'original file size: height: $heightOrig width: $widthOrig');
    return mFile;
  }

  @override
  onError(String message) {
    pp('$mm onError fired - $message');
    if (mounted) {
      showToast(
          message: message,
          textStyle: const TextStyle(color: Colors.white),
          duration: const Duration(seconds: 3),
          toastGravity: ToastGravity.TOP,
          backgroundColor: Colors.pink,
          context: context);
    }
  }

  @override
  onVideoReady(Video video) {}
}

List<CameraDescription> cameras = [];

class UploadParameters {
  late SendPort sendPort;
  late File file;
  late File thumbnailFile;
  late Project project;
  late ProjectPosition projectPosition;
  late bool isVideo;
  late String urlPrefix, token;
  late User user;
  late double distanceFromProjectPosition;
  late NativeDeviceOrientation deviceOrientation;

  UploadParameters(
      {required this.sendPort,
      required this.file,
      required this.thumbnailFile,
      required this.project,
      required this.projectPosition,
      required this.isVideo,
      required this.deviceOrientation,
      required this.urlPrefix,
      required this.token,
      required this.user,
      required this.distanceFromProjectPosition});
}

heavyTask(UploadParameters parameters) async {
  //cloudStorageBloc.uploadPhotoOrVideo(parameters);
}

class UploadMessage {
  late int statusCode;
  late String message;
  late String fileUrl, thumbnailUrl;
  int totalBytes = 0;
  int bytesTransferred = 0;

  UploadMessage(
      {required this.statusCode,
      required this.message,
      required this.totalBytes,
      required this.bytesTransferred,
      required this.fileUrl,
      required this.thumbnailUrl});

  UploadMessage.fromJson(Map data) {
    statusCode = data['statusCode'];
    message = data['message'];
    fileUrl = data['fileUrl'];
    thumbnailUrl = data['thumbnailUrl'];
    totalBytes = data['totalBytes'];
    bytesTransferred = data['bytesTransferred'];
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'statusCode': statusCode,
      'message': message,
      'fileUrl': fileUrl,
      'thumbnailUrl': thumbnailUrl,
      'totalBytes': totalBytes,
      'bytesTransferred': bytesTransferred,
    };
    return map;
  }
}
