import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/data/audio.dart';
import 'package:geo_monitor/library/data/project.dart';
import 'package:geo_monitor/library/data/project_position.dart';
import 'package:geo_monitor/library/data/video.dart';
import 'package:geo_monitor/library/emojis.dart';
import 'package:geo_monitor/library/ui/camera/play_video.dart';
import 'package:image_picker/image_picker.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path_provider/path_provider.dart';

import '../../../ui/dashboard/dashboard_mobile.dart';
import '../../bloc/cloud_storage_bloc.dart';
import '../../bloc/project_bloc.dart';
import '../../data/position.dart';
import '../../data/project_polygon.dart';
import '../../functions.dart';
import '../../generic_functions.dart';
import '../../location/loc_bloc.dart';
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
    with SingleTickerProviderStateMixin
    implements StorageBlocListener {
  final mm =
      '${E.blueDot}${E.blueDot}${E.blueDot}${E.blueDot} VideoHandler: 🌿';

  late AnimationController _controller;
  final ImagePicker _picker = ImagePicker();
  late StreamSubscription orientStreamSubscription;
  late StreamSubscription<String> killSubscription;

  var polygons = <ProjectPolygon>[];
  var positions = <ProjectPosition>[];

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    killSubscription = listenForKill(context: context);

    _observeOrientation();
    _getData();
    _startVideo();
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

  void _getData() async {
    setState(() {
      busy = true;
    });
    try {
      pp('$mm .......... getting project positions and polygons');
      polygons = await projectBloc.getProjectPolygons(
          projectId: widget.project.projectId!, forceRefresh: false);
      positions = await projectBloc.getProjectPositions(
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

  void _startVideo() async {
    pp('$mm file taking started ....');
    setState(() {
      videoIsReady = false;
    });
    var settings = await prefsOGx.getSettings();
    var minutes = settings.maxVideoLengthInMinutes;
    final XFile? file = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: Duration(minutes: minutes!),
        preferredCameraDevice: CameraDevice.rear);

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
        File('${directory.path}$x${DateTime.now().millisecondsSinceEpoch}.jpg');
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

    cloudStorageBloc.errorStream.listen((event) {
      if (mounted) {
        showToast(
            message: event,
            toastGravity: ToastGravity.TOP,
            textStyle: const TextStyle(color: Colors.white),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.pink.shade400,
            context: context);
      }
    });

    if (widget.projectPosition != null) {
      var result = await cloudStorageBloc.uploadVideo(
        listener: this,
        file: mFile,
        thumbnailFile: tFile,
        project: widget.project,
        projectPositionId: widget.projectPosition!.projectPositionId!,
        projectPosition: widget.projectPosition!.position!,
      );
      pp('$mm result from cloudStorageBloc: $result, if $uploadFinished we good!');
    } else {
      var loc = await locationBlocOG.getLocation();
      if (loc != null) {
        var position =
        Position(type: 'Point', coordinates: [loc.longitude, loc.latitude]);
        var polygon = getPolygonUserIsWithin(
            polygons: polygons,
            latitude: loc.latitude!,
            longitude: loc.longitude!);

        var result = await cloudStorageBloc.uploadVideo(
          listener: this,
          file: mFile,
          thumbnailFile: tFile,
          project: widget.project,
          projectPolygonId: polygon?.projectPolygonId,
          projectPosition: position,
        );

        pp(
            '$mm result from cloudStorageBloc: $result, if $uploadFinished we good!');
      }

      var size = await finalFile!.length();
      var m = (size / 1024 / 1024).toStringAsFixed(2);
      pp('$mm Video made is $m MB in size');
      if (mounted) {
        showToast(
            context: context,
            message: 'Video file saved on device, size: $m MB',
            backgroundColor: Theme
                .of(context)
                .primaryColor,
            textStyle: Styles.whiteSmall,
            toastGravity: ToastGravity.TOP,
            duration: const Duration(seconds: 2));
      }
    }
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

  String? totalByteCount, bytesTransferred;
  String? fileUrl, thumbnailUrl;

  @override
  onFileProgress(int totalByteCount, int bytesTransferred) {
    pp('$mm 🍏file Upload progress: bytesTransferred: ${(bytesTransferred / 1024).toStringAsFixed(1)} KB '
        'of totalByteCount: ${(totalByteCount / 1024).toStringAsFixed(1)} KB');
    setState(() {
      this.totalByteCount =
          '${(totalByteCount / 1024 / 1024).toStringAsFixed(2)} MB';
      this.bytesTransferred =
          '${(bytesTransferred / 1024 / 1024).toStringAsFixed(2)} MB';
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
        leading: const SizedBox(),
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
          IconButton(
              onPressed: _onCancel,
              icon: Icon(
                Icons.close,
                color: Theme.of(context).primaryColor,
              )),
        ],
      ),
      body: Stack(
        children: [
          thumbnailFile == null
              ? Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage('assets/intro/pic2.jpg'),
                        opacity: 0.1,
                        fit: BoxFit.cover),
                  ),
                )
              : Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                        image: FileImage(finalFile!), fit: BoxFit.cover),
                  ),
                ),
          Positioned(
            left: 24,
            right: 24,
            top: 100,
            child: SizedBox(
              child: Card(
                elevation: 4,
                color: Colors.black12,
                shape: getRoundedBorder(radius: 16),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      'Video Handler',
                      style: myTextStyleLarge(context),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    widget.projectPosition == null
                        ? Text(
                            'from within Project Area',
                            style: myTextStyleSmall(context),
                          )
                        : Text(
                            'from Project Location',
                            style: myTextStyleSmall(context),
                          ),
                    const SizedBox(
                      height: 12,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Card(
                        elevation: 4,
                        shape: getRoundedBorder(radius: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      'Uploaded',
                                      style: myTextStyleSmall(context),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  bytesTransferred == null
                                      ? Text('0',
                                          style: myNumberStyleSmall(context))
                                      : Text(
                                          '$bytesTransferred',
                                          style: myNumberStyleSmall(context),
                                        ),
                                ],
                              ),
                              const SizedBox(
                                height: 24,
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      'Total Size',
                                      style: myTextStyleSmall(context),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  totalByteCount == null
                                      ? Text('0',
                                          style: myNumberStyleSmall(context))
                                      : Text(
                                          '$totalByteCount',
                                          style: myNumberStyleSmall(context),
                                        ),
                                ],
                              ),
                              const SizedBox(
                                height: 48,
                              ),
                              SizedBox(
                                width: 200,
                                child: ElevatedButton(
                                    onPressed: _startNextVideo,
                                    child: const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Text('Make Video'),
                                    )),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              videoIsReady
                                  ? SizedBox(
                                      width: 200,
                                      child: ElevatedButton(
                                        onPressed: _navigateToPlayer,
                                        child: const Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: Text('Play Video'),
                                        ),
                                      ),
                                    )
                                  : const SizedBox(),
                              const SizedBox(
                                height: 48,
                              ),
                              TextButton(
                                  onPressed: _onCancel,
                                  child: Text('Cancel',
                                      style: myTextStyleSmall(context)))
                            ],
                          ),
                        ),
                      ),
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

  @override
  onVideoReady(Video video) {
    pp('$mm video is ready for playback ... 🍎 video: ${video.toJson()}');

    setState(() {
      _currentVideo = video;
      videoIsReady = true;
    });
  }

  Video? _currentVideo;

  void _navigateToPlayer() {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.topLeft,
            duration: const Duration(seconds: 1),
            child: PlayVideo(
              project: widget.project,
              video: _currentVideo!,
            )));
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  onAudioReady(Audio audio) {}
}
