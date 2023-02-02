import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/api/data_api.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/functions.dart';
import 'package:geo_monitor/library/hive_util.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../data/user.dart';
import '../generic_functions.dart';

class AvatarEditor extends StatefulWidget {
  const AvatarEditor({Key? key, required this.user}) : super(key: key);
  final User user;
  @override
  AvatarEditorState createState() => AvatarEditorState();
}

class AvatarEditorState extends State<AvatarEditor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final ImagePicker _picker = ImagePicker();
  final mm = '🐳🐳🐳🐳🐳🐳 AvatarEditor: ';
  final height = 800.0, width = 600.0;
  File? finalFile;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  void _pickPhotoFromGallery() async {
    pp('$mm photo picking from gallery started ....');
    xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: height,
        maxWidth: width,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear);

    imageFile = File(xFile!.path);
    setState(() {});
  }

  XFile? xFile;
  File? imageFile;
  void _takePhoto() async {
    pp('$mm photo taking started ....');

    xFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxHeight: height,
        maxWidth: width,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.front);

    imageFile = File(xFile!.path);

    setState(() {});
  }

  Future<void> _processFile() async {
    File mImageFile = File(xFile!.path);
    pp('$mm _processFile 🔵🔵🔵 ....... file to upload, '
        'size: ${await mImageFile.length()} bytes🔵');
    setState(() {
      busy = true;
    });
    var thumbnailFile = await getPhotoThumbnail(file: mImageFile);

    final Directory directory = await getApplicationDocumentsDirectory();
    const x = '/photo_';
    final File mFile =
        File('${directory.path}$x${DateTime.now().millisecondsSinceEpoch}.jpg');
    const z = '/photo_thumbnail';
    final File tFile =
        File('${directory.path}$z${DateTime.now().millisecondsSinceEpoch}.jpg');

    await thumbnailFile.copy(tFile.path);
    await mImageFile.copy(mFile.path);

    setState(() {
      finalFile = mFile;
    });

    pp('$mm check file upload names: \n💚 ${mFile.path} length: ${await mFile.length()} '
        '\n💚thumb: ${tFile.path} length: ${await tFile.length()}');

    var size = await mFile.length();
    var m = (size / 1024 / 1024).toStringAsFixed(2);
    pp('$mm Picture taken is $m MB in size');
    await _uploadToCloud(mFile.path, tFile.path);
    pp('\n\n$mm Picture taken has been uploaded OK');
    setState(() {
      imageFile = null;
    });
    if (mounted) {
      showToast(
          context: context,
          message: 'Picture file saved on device, size: $m MB',
          backgroundColor: Theme.of(context).primaryColor,
          textStyle: Styles.whiteSmall,
          toastGravity: ToastGravity.TOP,
          duration: const Duration(seconds: 2));
    }
  }

  final photoStorageName = 'geoUserPhotos';
  String? url, thumbUrl;

  Future<int> _uploadToCloud(String filePath, String thumbnailPath) async {
    late UploadTask uploadTask;
    late TaskSnapshot taskSnapshot;
    try {
      //upload main file
      var fileName = 'photo@${widget.user.organizationId}@${widget.user.userId}'
          '@${DateTime.now().toUtc().toIso8601String()}.${'jpg'}';
      var firebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child(photoStorageName)
          .child(fileName);
      var file = File(filePath);
      pp('$mm️ photo to be uploaded ☕️☕️☕️☕️☕️☕️☕️file path: \n${file.path}');

      uploadTask = firebaseStorageRef.putFile(file);
      taskSnapshot = await uploadTask.whenComplete(() {});
      url = await taskSnapshot.ref.getDownloadURL();
      pp('$mm file url is available, meaning that upload is complete: \n$url');
      _printSnapshot(taskSnapshot, 'PHOTO');
      // upload thumbnail here
      final thumbName =
          'thumbnail@${widget.user.organizationId}@${widget.user.userId}@${DateTime.now().toUtc().toIso8601String()}.${'jpg'}';
      final firebaseStorageRef2 = FirebaseStorage.instance
          .ref()
          .child(photoStorageName)
          .child(thumbName);

      var thumbnailFile = File(thumbnailPath);
      final thumbUploadTask = firebaseStorageRef2.putFile(thumbnailFile);
      final thumbTaskSnapshot = await thumbUploadTask.whenComplete(() {});
      thumbUrl = await thumbTaskSnapshot.ref.getDownloadURL();
      pp('$mm thumbnail file url is available, meaning that upload is complete: \n$thumbUrl');
      _printSnapshot(thumbTaskSnapshot, 'PHOTO THUMBNAIL');
      widget.user.imageUrl = url;
      widget.user.thumbnailUrl = thumbUrl;
      widget.user.updated = DateTime.now().toUtc().toIso8601String();

      await _updateDatabase();
      return 0;
    } catch (e) {
      pp(e);
      return 9;
    }
  }

  Future _updateDatabase() async {
    pp('\n\n$mm User database entry to be updated: ${widget.user.name}\n');

    try {
      await DataAPI.updateUser(widget.user);
      var me = await prefsOGx.getUser();
      if (widget.user.userId == me!.userId) {
        await prefsOGx.saveUser(widget.user);
      }
      await cacheManager.addUser(user: widget.user);
      pp('\n\n$mm User photo and thumbnail uploaded and database updated\n');
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

  void _printSnapshot(TaskSnapshot taskSnapshot, String type) {
    var totalByteCount = taskSnapshot.totalBytes;
    var bytesTransferred = taskSnapshot.bytesTransferred;
    var bt = '${(bytesTransferred / 1024).toStringAsFixed(2)} KB';
    var tot = '${(totalByteCount / 1024).toStringAsFixed(2)} KB';
    pp('$mm uploadTask $type: 💚💚 '
        ' upload complete '
        ' 🧩 $bt of $tot 🧩 transferred.'
        ' date: ${DateTime.now().toIso8601String()}\n');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Avatar Builder',
          style: myTextStyleSmall(context),
        ),
        actions: [
          imageFile == null
              ? const SizedBox()
              : IconButton(
                  onPressed: _processFile,
                  icon: Icon(
                    Icons.check,
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ))
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 4,
              shape: getRoundedBorder(radius: 16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      '${widget.user.name}',
                      style: myTextStyleLargePrimaryColor(context),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    imageFile == null
                        ? const SizedBox()
                        : SizedBox(
                            width: 320,
                            height: 360,
                            child: Image.file(
                              imageFile!,
                              fit: BoxFit.cover,
                            ),
                          ),
                    const SizedBox(
                      height: 24,
                    ),
                    busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              backgroundColor: Colors.pink,
                            ),
                          )
                        : SizedBox(
                            height: 240,
                            width: 400,
                            child: Column(
                              children: [
                                TextButton(
                                    onPressed: _takePhoto,
                                    child: Text(
                                      'Use Camera',
                                      style: myTextStyleMedium(context),
                                    )),
                                const SizedBox(
                                  height: 0,
                                ),
                                TextButton(
                                    onPressed: _pickPhotoFromGallery,
                                    child: Text(
                                      'Pick from Gallery',
                                      style: myTextStyleMedium(context),
                                    )),
                                const SizedBox(
                                  height: 0,
                                ),
                                imageFile == null
                                    ? const SizedBox()
                                    : TextButton(
                                        onPressed: _processFile,
                                        child: Text(
                                          'Submit Photo',
                                          style: myTextStyleMedium(context),
                                        )),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
          imageFile == null
              ? const SizedBox()
              : thumbUrl == null
                  ? const SizedBox()
                  : Positioned(
                      right: 4,
                      top: 48,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(thumbUrl!),
                      ),
                    ),
        ],
      ),
    ));
  }
}
