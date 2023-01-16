import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:geo_monitor/library/bloc/failed_bag.dart';
import 'package:geo_monitor/library/hive_util.dart';
import 'package:http/http.dart' as http;
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:path_provider/path_provider.dart';

import 'package:uuid/uuid.dart';

import '../api/data_api.dart';
import '../api/sharedprefs.dart';
import '../data/position.dart';
import '../data/user.dart';
import '../data/video.dart';
import '../emojis.dart';
import '../functions.dart';
import '../location/loc_bloc.dart';
import '../data/photo.dart';
import '../data/project.dart';

final CloudStorageBloc cloudStorageBloc = CloudStorageBloc();

class CloudStorageBloc {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  Random rand = Random(DateTime.now().millisecondsSinceEpoch);
  static const mm = '☕️☕️☕️☕️☕️☕️ CloudStorageBloc: 💚 ';
  final List<StorageMediaBag> _mediaBags = [];
  final StreamController<List<StorageMediaBag>> _mediaStreamController =
      StreamController.broadcast();
  Stream<List<StorageMediaBag>> get mediaStream =>
      _mediaStreamController.stream;

  User? _user;

  close() {
    _mediaStreamController.close();
  }

  final photoStorageName = 'geoPhotos';
  final videoStorageName = 'geoVideos';

  final StreamController<Photo> _photoStreamController =
      StreamController.broadcast();
  final StreamController<Video> _videoStreamController =
      StreamController.broadcast();
  final StreamController<String> _errorStreamController =
      StreamController.broadcast();

  Stream<Photo> get photoStream => _photoStreamController.stream;
  Stream<Video> get videoStream => _videoStreamController.stream;
  Stream<String> get errorStream => _errorStreamController.stream;

  late StorageBlocListener storageBlocListener;

  Future<int> uploadPhotoOrVideo(
      {required StorageBlocListener listener,
      required File file,
      required File thumbnailFile,
      required Project project,
      required Position projectPosition,
      required bool isVideo,
      String? projectPositionId,
      String? projectPolygonId,
      required bool isLandscape}) async {
    pp('\n\n\n$mm️ uploadPhotoOrVideo ☕️☕️☕️☕️☕️☕️☕️️file length: ${await file.length()} bytes - isLandscape: $isLandscape');

    String storageName = _setup(listener, isVideo);
    try {
      pp('$mm️ uploadPhotoOrVideo ☕️☕️☕️☕️☕️☕️☕️file path: \n${file.path}');
     //todo - REMOVE AFTER TEST - OTHERWISE cloud storage upload will NEVER run
     //  if (storageName.isNotEmpty) {
     //    var msg = 'Fake exception 🔴🔴🔴🔴 for cloud storage '
     //        'failure testing; storageName: $storageName 🔴';
     //    pp('\n\n\n$mm $msg');
     //    throw Exception(msg);
     //  }
      //upload main file
      var fileName = _getFileName(isVideo, project);
      var firebaseStorageRef =
          FirebaseStorage.instance.ref().child(storageName).child(fileName);
      var uploadTask = firebaseStorageRef.putFile(file);
      _reportProgress(uploadTask, listener);
      var taskSnapshot = await uploadTask.whenComplete(() {
        pp('$mm This is like a finally block - consider this ...');
      });
      final url = await taskSnapshot.ref.getDownloadURL();
      pp('$mm file url is available, meaning that upload is complete: \n$url');
      _printSnapshot(taskSnapshot);

      // upload thumbnail here
      final thumbName = _getFileName(false, project);
      final firebaseStorageRef2 =
          FirebaseStorage.instance.ref().child(storageName).child(thumbName);
      final thumbUploadTask = firebaseStorageRef2.putFile(thumbnailFile);
      _reportProgress(thumbUploadTask, listener);
      final thumbTaskSnapshot = await thumbUploadTask.whenComplete(() {
        pp('$mm This is like a finally block - consider this ...');
      });
      final thumbUrl = await thumbTaskSnapshot.ref.getDownloadURL();
      pp('$mm thumbnail file url is available, meaning that upload is complete: \n$thumbUrl');
      _printSnapshot(thumbTaskSnapshot);

      //write to db
      pp('\n$mm adding photo or video data to the database ...');
      await _writeToDatabase(
          isVideo,
          project,
          projectPosition,
          projectPositionId,
          projectPolygonId,
          url,
          thumbUrl,
          file,
          isLandscape);

      pp('\n$mm upload process completed, tell the faithful listener!.\n\n');
      listener.onFileUploadComplete(
          url, taskSnapshot.totalBytes, taskSnapshot.bytesTransferred);
      return uploadFinished;
    } catch (e) {
      pp('\n\n$mm 👿👿👿👿 Photo/Video upload failed: $e');
      listener.onError('👿👿👿👿 Houston, we have a cloud storage problem $e');
      await _saveFailedMedia(
          file, thumbnailFile, project, projectPosition,
          isLandscape, isVideo);
    }

    return uploadError;
  }

  Future<void> _saveFailedMedia(File file, File thumbnailFile, Project project,
      Position projectPosition, bool isLandscape, bool isVideo) async {

    var failedBag = FailedBag(
        filePath: file.path,
        thumbnailPath: thumbnailFile.path,
        project: project,
        projectPosition: projectPosition,
        isLandscape: isLandscape,
        isVideo: isVideo,
        date: DateTime.now().toUtc().toIso8601String());

    await hiveUtil.addFailedBag(bag: failedBag);
    pp('\n$mm failedBag cached in hive after cloud storage failure 🔴🔴🔴');
  }

  String _setup(StorageBlocListener listener, bool isVideo) {
    storageBlocListener = listener;
    rand = Random(DateTime.now().millisecondsSinceEpoch);
    var storageName = '';
    if (isVideo) {
      storageName = videoStorageName;
    } else {
      storageName = photoStorageName;
    }
    return storageName;
  }

  Future<void> _writeToDatabase(
      bool isVideo,
      Project project,
      Position projectPosition,
      String? projectPositionId,
      String? projectPolygonId,
      String url,
      String thumbUrl,
      File file,
      bool isLandscape) async {

      if (isVideo) {
        await _writeVideo(
            project: project,
            projectPosition: projectPosition,
            projectPositionId: projectPositionId,
            projectPolygonId: projectPolygonId,
            fileUrl: url,
            thumbnailUrl: thumbUrl);
      } else {
        final mainFileSize = ImageSizeGetter.getSize(FileInput(file));
        await _writePhoto(
            project: project,
            projectPosition: projectPosition,
            fileUrl: url,
            thumbnailUrl: thumbUrl,
            projectPositionId: projectPositionId,
            projectPolygonId: projectPolygonId,
            height: mainFileSize.height,
            width: mainFileSize.width,
            isLandscape: isLandscape);
      }

  }

  String _getFileName(bool isVideo, Project project) {
    if (isVideo) {
      return 'video@${project.projectId}@${DateTime.now().toUtc().toIso8601String()}.${'mp4'}';
    } else {
      return 'photo@${project.projectId}@${DateTime.now().toUtc().toIso8601String()}.${'jpg'}';
    }
  }

  void _printSnapshot(TaskSnapshot taskSnapshot) {
    var totalByteCount = taskSnapshot.totalBytes;
    var bytesTransferred = taskSnapshot.bytesTransferred;
    var bt = '${(bytesTransferred / 1024).toStringAsFixed(2)} KB';
    var tot = '${(totalByteCount / 1024).toStringAsFixed(2)} KB';
    pp('$mm uploadTask: 💚💚 '
        'photo or video upload complete '
        ' 🧩 $bt of $tot 🧩 transferred.'
        ' date: ${DateTime.now().toIso8601String()}\n');
  }

  void _reportProgress(UploadTask uploadTask, StorageBlocListener listener) {
    uploadTask.snapshotEvents.listen((event) {
      var totalByteCount = event.totalBytes;
      var bytesTransferred = event.bytesTransferred;
      var bt = '${(bytesTransferred / 1024).toStringAsFixed(2)} KB';
      var tot = '${(totalByteCount / 1024).toStringAsFixed(2)} KB';
      pp('️$mm _reportProgress:  💚 progress ******* 🧩 $bt KB of $tot KB 🧩 transferred');
      listener.onFileProgress(event.totalBytes, event.bytesTransferred);
    });
  }

  void thumbnailProgress(UploadTask uploadTask, StorageBlocListener listener) {
    uploadTask.snapshotEvents.listen((event) {
      var totalByteCount = event.totalBytes;
      var bytesTransferred = event.bytesTransferred;
      var bt = '${(bytesTransferred / 1024).toStringAsFixed(2)} KB';
      var tot = '${(totalByteCount / 1024).toStringAsFixed(2)} KB';
      pp('$mm️ .uploadThumbnail:  🥦 progress ******* 🍓 $bt KB of $tot KB 🍓 transferred');
      listener.onThumbnailProgress(event.totalBytes, event.bytesTransferred);
    });
  }

  Future _writePhoto(
      {required Project project,
      required Position projectPosition,
      required String fileUrl,
      required String thumbnailUrl,
      String? projectPositionId,
      String? projectPolygonId,
      required int height,
      required int width,
      required bool isLandscape}) async {
    pp('\n$mm 🎽🎽🎽🎽 _writePhoto : 🎽 🎽 adding photo - isLandscape: $isLandscape');
    if (_user == null) {
      await getUser();
    }

    var distance = await locationBloc.getDistanceFromCurrentPosition(
        latitude: projectPosition.coordinates[1],
        longitude: projectPosition.coordinates[0]);

    pp('🎽🎽🎽🎽 StorageBloc: _writePhoto : 🎽🎽 adding photo ..... 😡😡 distance: $distance 😡😡 isLandscape: $isLandscape');
    var u = const Uuid();

    var photo = Photo(
        url: fileUrl,
        caption: 'tbd',
        created: DateTime.now().toUtc().toIso8601String(),
        userId: _user!.userId,
        userName: _user!.name,
        projectPosition: projectPosition,
        distanceFromProjectPosition: distance,
        projectId: project.projectId,
        thumbnailUrl: thumbnailUrl,
        projectName: project.name,
        organizationId: _user!.organizationId,
        height: height,
        width: width,
        projectPositionId: projectPositionId,
        projectPolygonId: projectPolygonId,
        photoId: u.v4(),
        landscape: isLandscape ? 0 : 1);

    try {
      var result = await DataAPI.addPhoto(photo);
      _photoStreamController.sink.add(photo);
      pp('$mm Photo has been added to database, result photo: 🎁 $result - 🎁 isLandscape: $isLandscape');
      pp('$mm  Photo has been added to photoStream ...');
    } catch (e) {
      pp('$mm Photo problem: $e');
      _errorStreamController.sink.add("Photo database write failed: $e");
      await hiveUtil.addFailedPhoto(photo: photo);
      storageBlocListener.onError('Photo database write failed');
    }
  }

  Future _writeVideo(
      {required Project project,
      required Position projectPosition,
      String? projectPositionId,
      String? projectPolygonId,
      required String fileUrl,
      required String thumbnailUrl}) async {
    pp('$mm adding video .....');

    if (_user == null) {
      await getUser();
    }
    var distance = await locationBloc.getDistanceFromCurrentPosition(
        latitude: projectPosition.coordinates[1],
        longitude: projectPosition.coordinates[0]);

    pp('$mm adding video ..... 😡😡 distance: '
        '${distance.toStringAsFixed(2)} metres 😡😡');
    var u = const Uuid();
    var video = Video(
        url: fileUrl,
        caption: 'tbd',
        created: DateTime.now().toUtc().toIso8601String(),
        userId: _user!.userId,
        userName: _user!.name,
        projectPosition: projectPosition,
        distanceFromProjectPosition: distance,
        projectId: project.projectId,
        thumbnailUrl: thumbnailUrl,
        projectName: project.name,
        projectPositionId: projectPositionId,
        projectPolygonId: projectPolygonId,
        organizationId: _user!.organizationId,
        videoId: u.v4());

    try {
      var result = await DataAPI.addVideo(video);
      pp('$mm Video has been added to database: 🎁 $result');
      storageBlocListener.onVideoReady(video);
    } catch (e) {
      pp('$mm Video upload problem: $e');
      _errorStreamController.sink.add("Video database write failed: $e");
      await hiveUtil.addFailedVideo(video: video);
      storageBlocListener.onError('Video database write failed');
    }
  }

  Future<File> downloadFile(String url) async {
    pp('🌿🌿🌿🌿🌿🌿🌿 : downloadFile: 😡😡😡 $url ....');
    final http.Response response =
        await http.get(Uri.parse(url)).catchError((e) {
      pp('😡😡😡 Download failed: 😡😡😡 $e');
      throw Exception('😡😡😡 Download failed: $e');
    });

    pp('🌿🌿🌿🌿🌿🌿🌿 : downloadFile: OK?? 💜💜💜💜'
        '  statusCode: ${response.statusCode}');

    if (response.statusCode == 200) {
      final Directory directory = await getApplicationDocumentsDirectory();
      var type = 'jpg';
      if (url.contains('mp4')) {
        type = 'mp4';
      }
      final File mFile = File(
          '${directory.path}/download${DateTime.now().millisecondsSinceEpoch}.$type');
      pp('🌿🌿🌿🌿🌿🌿🌿 : downloadFile: 💜  .... new file: ${mFile.path}');
      mFile.writeAsBytesSync(response.bodyBytes);
      var len = await mFile.length();
      pp('🌿🌿🌿🌿🌿🌿🌿 : downloadFile: 💜  .... file downloaded length: 😡 '
          '${(len / 1024).toStringAsFixed(1)} KB - path: ${mFile.path}');
      return mFile;
    } else {
      pp('🌿🌿🌿🌿🌿🌿🌿 : downloadFile: Download failed: 😡😡😡 statusCode ${response.statusCode} 😡 ${response.body} 😡');
      throw Exception('Download failed: statusCode: ${response.statusCode}');
    }
  }

  // ignore: missing_return
  Future<int> deleteFolder(String folderName) async {
    pp('.deleteFolder ######## deleting $folderName');
    var task = _firebaseStorage.ref().child(folderName).delete();
    await task.then((f) {
      pp('.deleteFolder $folderName deleted from FirebaseStorage');
      return 0;
    }).catchError((e) {
      pp('.deleteFolder ERROR $e');
      return 1;
    });
    return 0;
  }

  // ignore: missing_return
  Future<int> deleteFile(String folderName, String name) async {
    pp('.deleteFile ######## deleting $folderName : $name');
    var task = _firebaseStorage.ref().child(folderName).child(name).delete();
    task.then((f) {
      pp('.deleteFile $folderName : $name deleted from FirebaseStorage');
      return 0;
    }).catchError((e) {
      pp('.deleteFile ERROR $e');
      return 1;
    });
    return 0;
  }

  CloudStorageBloc() {
    pp('🍇 🍇 🍇 🍇 🍇 StorageBloc constructor 🍇 🍇 🍇 🍇 🍇');
    getUser();
  }
  Future? getUser() async {
    _user = await Prefs.getUser();
    return _user;
  }
}

abstract class StorageBlocListener {
  onFileProgress(int totalByteCount, int bytesTransferred);
  onFileUploadComplete(String url, int totalByteCount, int bytesTransferred);

  onThumbnailProgress(int totalByteCount, int bytesTransferred);
  onThumbnailUploadComplete(
      String url, int totalByteCount, int bytesTransferred);

  onVideoReady(Video video);

  onError(String message);
}

class StorageMediaBag {
  String url, thumbnailUrl, date;
  bool isVideo;
  File? file;
  File? thumbnailFile;

  StorageMediaBag(
      {required this.url,
      required this.file,
      required this.thumbnailUrl,
      required this.isVideo,
      this.thumbnailFile,
      required this.date});
}

const uploadBusy = 201;
const uploadFinished = 200;
const uploadError = 500;
