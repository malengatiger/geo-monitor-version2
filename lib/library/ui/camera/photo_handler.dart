import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';

import 'package:image_picker/image_picker.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

import '../../../ui/dashboard/dashboard_mobile.dart';
import '../../bloc/cloud_storage_bloc.dart';
import '../../bloc/project_bloc.dart';
import '../../data/audio.dart';
import '../../data/position.dart';
import '../../data/project.dart';
import '../../data/project_polygon.dart';
import '../../data/project_position.dart';
import '../../data/video.dart';
import '../../emojis.dart';
import '../../functions.dart';
import '../../generic_functions.dart';
import '../../location/loc_bloc.dart';
import '../media/list/project_media_list_mobile.dart';
import '../settings.dart';

class PhotoHandler extends StatefulWidget {
  const PhotoHandler({Key? key, required this.project, this.projectPosition})
      : super(key: key);
  final Project project;
  final ProjectPosition? projectPosition;
  @override
  PhotoHandlerState createState() => PhotoHandlerState();
}

class PhotoHandlerState extends State<PhotoHandler>
    with SingleTickerProviderStateMixin
    implements StorageBlocListener {
  final mm =
      '${E.blueDot}${E.blueDot}${E.blueDot}${E.blueDot} PhotoHandler: 🌿';

  late AnimationController _controller;
  final ImagePicker _picker = ImagePicker();
  late StreamSubscription orientStreamSubscription;
  late StreamSubscription<String> killSubscription;

  NativeDeviceOrientation? _deviceOrientation;
  var polygons = <ProjectPolygon>[];
  var positions = <ProjectPosition>[];

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    killSubscription = listenForKill(context: context);

    _observeOrientation();
    _getData();
    _startPhoto();
  }

  Future<void> _observeOrientation() async {
    pp('${E.blueDot} ........ _observeOrientation ... ');
    Stream<NativeDeviceOrientation> stream =
        NativeDeviceOrientationCommunicator()
            .onOrientationChanged(useSensor: true);
    orientStreamSubscription = stream.listen((event) {
      // pp('${E.blueDot}${E.blueDot} orientation, name: ${event.name} index: ${event.index}');
      _deviceOrientation = event;
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
/*

Standard Display Resolution Sizes
Name(s)	Resolution in pixels
High Definition (HD)	1280 x 720
Full HD, FHD	1920 x 1080
 */
  void _startPhoto() async {
    pp('$mm photo taking started ....');
    var settings = await prefsOGx.getSettings();
    var height = 0.0, width = 0.0;
    switch(settings.photoSize) {
      case 0:
        height = 640;
        width = 480;
        break;
      case 1:
        height = 720;
        width = 1280;
        break;
      case 2:
        height = 1080;
        width = 1920;
        break;
    }
    final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxHeight: height,
        maxWidth: width,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear);

    if (file != null) {
      await _processFile(file);
      setState(() {});
    }
    // file.saveTo(path);
  }

  File? finalFile;
  Future<void> _processFile(XFile file) async {
    File mImageFile = File(file.path);
    pp('$mm _processFile 🔵🔵🔵 file to upload, '
        'size: ${await mImageFile.length()} bytes🔵');

    var thumbnailFile = await getPhotoThumbnail(file: mImageFile);
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
    final Directory directory = await getApplicationDocumentsDirectory();
    const x = '/photo_';
    final File mFile = File(
        '${directory.path}$x${DateTime.now().millisecondsSinceEpoch}.jpg');
    const z = '/photo_thumbnail';
    final File tFile = File(
        '${directory.path}$z${DateTime.now().millisecondsSinceEpoch}.jpg');
     await thumbnailFile.copy(tFile.path);
    //can i force
    if (_deviceOrientation != null) {
      final finalFile = await _processOrientation(mImageFile, _deviceOrientation!);
      await finalFile.copy(mFile.path);
    } else {
      await mImageFile.copy(mFile.path);
    }
    setState(() {
      finalFile = mFile;
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

    pp('$mm check file upload names: \n💚 ${mFile.path} length: ${await mFile.length()} '
        '\n💚thumb: ${tFile.path} length: ${await tFile.length()}');
    if (widget.projectPosition != null) {
      cloudStorageBloc.uploadPhoto(
          listener: this,
          file: mFile,
          thumbnailFile: tFile,
          project: widget.project,
          projectPositionId: widget.projectPosition!.projectPositionId!,
          projectPosition: widget.projectPosition!.position!,);
    } else {
      var loc = await locationBlocOG.getLocation();
      if (loc != null) {
        var position =
        Position(type: 'Point', coordinates: [loc.longitude, loc.latitude]);
        var polygon = getPolygonUserIsWithin(
            polygons: polygons,
            latitude: loc.latitude!,
            longitude: loc.longitude!);

        var result = await cloudStorageBloc.uploadPhoto(
          listener: this,
          file: mFile,
          thumbnailFile: tFile,
          project: widget.project,
          projectPolygonId: polygon?.projectPolygonId,
          projectPosition: position,);

        pp(
            '$mm result from cloudStorageBloc: $result, if $uploadFinished we good!');
      }

      var size = await mFile.length();
      var m = (size / 1024 / 1024).toStringAsFixed(2);
      pp('$mm Picture taken is $m MB in size');
      if (mounted) {
        showToast(
            context: context,
            message: 'Picture file saved on device, size: $m MB',
            backgroundColor: Theme
                .of(context)
                .primaryColor,
            textStyle: Styles.whiteSmall,
            toastGravity: ToastGravity.TOP,
            duration: const Duration(seconds: 2));
      }
    }
  }

  void _startNextPhoto() {
    pp('$mm _startNextPhoto');
    _startPhoto();
  }

  @override
  void dispose() {
    _controller.dispose();
    killSubscription.cancel();
    super.dispose();
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

  String? totalByteCount, bytesTransferred;
  String? fileUrl, thumbnailUrl;

  @override
  onFileProgress(int totalByteCount, int bytesTransferred) {
    pp('$mm 🍏file Upload progress: bytesTransferred: ${(bytesTransferred / 1024).toStringAsFixed(1)} KB '
        'of totalByteCount: ${(totalByteCount / 1024).toStringAsFixed(1)} KB');
    setState(() {
      this.totalByteCount = '${(totalByteCount / 1024/1024).toStringAsFixed(2)} MB';
      this.bytesTransferred =
          '${(bytesTransferred / 1024/1024).toStringAsFixed(2)} MB';
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
        title: Text('${widget.project.name}', style: myTextStyleSmall(context),),
        actions: [
          IconButton(
              onPressed: _navigateToList, icon:  Icon(Icons.list, color: Theme.of(context).primaryColor,)),
        ],
      ),
      body: Stack(
        children: [
          finalFile == null
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
            left: 12, right: 12,
            top: 100,
            child: SizedBox(
              width: 300,
              height: 360,
              child: Card(
                elevation: 4,
                color: Colors.black38,
                shape: getRoundedBorder(radius: 16),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      'Photo Handler',
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
                      padding: const EdgeInsets.all(20.0),
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
                                    width: 150,
                                    child: Text(
                                      'Bytes Uploaded',
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
                                height: 16,
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      'Total Bytes',
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
                                height: 24,
                              ),
                              ElevatedButton(
                                  onPressed: _startNextPhoto,
                                  child: const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text('Take Picture'),
                                  )),
                              const SizedBox(
                                height: 24,
                              ),
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

  @override
  onVideoReady(Video video) {}

  @override
  onAudioReady(Audio audio) {
  }
}
