import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:geo_monitor/library/bloc/failed_audio.dart';
import 'package:geo_monitor/library/bloc/failed_bag.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';
import 'package:geo_monitor/library/hive_util.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'package:uuid/uuid.dart';

import '../api/data_api.dart';
import '../api/sharedprefs.dart';
import '../data/audio.dart';
import '../data/position.dart';
import '../data/user.dart';
import '../data/video.dart';
import '../functions.dart';
import '../location/loc_bloc.dart';
import '../data/photo.dart';
import '../data/project.dart';

final CloudStorageBloc cloudStorageBloc = CloudStorageBloc();

class CloudStorageBloc {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  Random rand = Random(DateTime.now().millisecondsSinceEpoch);
  static const mm = '☕️☕️☕️☕️☕️☕️ CloudStorageBloc: 💚 ';
  final StreamController<List<StorageMediaBag>> _mediaStreamController =
      StreamController.broadcast();
  Stream<List<StorageMediaBag>> get mediaStream =>
      _mediaStreamController.stream;
  bool busy = false;
  User? _user;

  close() {
    _mediaStreamController.close();
  }

  final photoStorageName = 'geoPhotos';
  final videoStorageName = 'geoVideos';
  final audioStorageName = 'geoAudios';

  final StreamController<Photo> _photoStreamController =
      StreamController.broadcast();
  final StreamController<Video> _videoStreamController =
      StreamController.broadcast();
  final StreamController<Video> _audioStreamController =
      StreamController.broadcast();
  final StreamController<String> _errorStreamController =
      StreamController.broadcast();

  Stream<Photo> get photoStream => _photoStreamController.stream;
  Stream<Video> get videoStream => _videoStreamController.stream;
  Stream<Video> get audioStream => _audioStreamController.stream;

  Stream<String> get errorStream => _errorStreamController.stream;

  late StorageBlocListener storageBlocListener;
  AudioPlayer audioPlayer = AudioPlayer();

  Future<int> uploadAudio({
    required StorageBlocListener listener,
    required File file,
    required Project project,
    Position? projectPosition,
    String? projectPositionId,
    String? projectPolygonId,
  }) async {
    pp('\n\n\n$mm️ uploadAudio ☕️☕️☕️☕️☕️☕️☕️️file length: ${await file.length()} bytes');

      String url = 'unknown';
      UploadTask? uploadTask;
      try {
        var fileName =
            'audio@${project.organizationId}@${project.projectId}@${DateTime.now().toUtc().toIso8601String()}.mp3';
        var firebaseStorageRef = FirebaseStorage.instance
            .ref()
            .child(audioStorageName)
            .child(fileName);
        uploadTask = firebaseStorageRef.putFile(file);
        _reportProgress(uploadTask, listener);
        var taskSnapshot = await uploadTask.whenComplete(() {
          // pp('$mm This is like a finally block - consider this ...');
        });
        url = await taskSnapshot.ref.getDownloadURL();
        pp('$mm file url is available, meaning that upload is complete: \n$url');
        _printSnapshot(taskSnapshot);
      } catch (e) {
        pp('$mm Upload failed save the details ...');
        var failed = FailedAudio(
            filePath: file.path,
            project: project,
            audio: null,
            projectPolygonId: projectPolygonId,
            projectPositionId: projectPositionId,
            projectPosition: projectPosition,
            date: DateTime.now().toIso8601String());

        await cacheManager.addFailedAudio(failedAudio: failed);
        pp('\n$mm 🔴🔴🔴 failed audio cached in hive after upload or database failure 🔴🔴🔴');
        listener.onError('Audio upload failed: $e');
        return uploadError;
      }
      var user = await Prefs.getUser();
      var distance = 0.0;
      Audio? audio;

      if (user != null) {
        if (projectPosition != null) {
          distance = await locationBloc.getDistanceFromCurrentPosition(
              latitude: projectPosition.coordinates[1],
              longitude: projectPosition.coordinates[0]);
        } else {
          distance = 0.0;
        }
        pp('$mm adding audio ..... 😡😡 distance: '
            '${distance.toStringAsFixed(2)} metres 😡😡');

        var dur = await audioPlayer.setUrl(url);
        audio = Audio(
            url: url,
            created: DateTime.now().toUtc().toIso8601String(),
            userId: user.userId,
            userName: user.name,
            projectPosition: projectPosition,
            distanceFromProjectPosition: distance,
            projectId: project.projectId,
            audioId: const Uuid().v4(),
            organizationId: project.organizationId,
            projectName: project.name,
            durationInSeconds: dur!.inSeconds);

        try {
          var result = await DataAPI.addAudio(audio);
          await organizationBloc.addAudioToStream(result);
          listener.onFileUploadComplete(url, uploadTask.snapshot.totalBytes,
              uploadTask.snapshot.bytesTransferred);
        } catch (e) {
          pp(e);
          var failed = FailedAudio(
              filePath: null,
              audio: audio,
              project: project,
              projectPosition: projectPosition,
              projectPolygonId: projectPolygonId,
              projectPositionId: projectPositionId,
              date: DateTime.now().toIso8601String());
          await cacheManager.addFailedAudio(failedAudio: failed);
          listener.onError('Audio database write failed: $e');
          pp('\n$mm 🔴🔴🔴 failed audio cached in hive after upload or database failure 🔴🔴🔴');
          return uploadError;
        }
      }


    return uploadFinished;
  }

  Future<int> uploadPhoto(
      {required StorageBlocListener listener,
      required File file,
      required File thumbnailFile,
      required Project project,
      required Position projectPosition,
      String? projectPositionId,
      String? projectPolygonId,}) async {

    pp('\n\n\n$mm️ uploadPhoto ☕️☕️☕️☕️☕️☕️☕️️file length: ${await file.length()} bytes ');

    var url = 'unknown';
    var thumbUrl = 'unknown';
    late UploadTask uploadTask;
    late TaskSnapshot taskSnapshot;
    try {
      pp('$mm️ uploadPhoto ☕️☕️☕️☕️☕️☕️☕️file path: \n${file.path}');
      //upload main file
      var fileName =  'photo@${project.projectId}@${DateTime.now().toUtc().toIso8601String()}.${'jpg'}';
      var firebaseStorageRef =
          FirebaseStorage.instance.ref().child(photoStorageName).child(fileName);
      uploadTask = firebaseStorageRef.putFile(file);
      _reportProgress(uploadTask, listener);
      taskSnapshot = await uploadTask.whenComplete(() {});
      url = await taskSnapshot.ref.getDownloadURL();
      pp('$mm file url is available, meaning that upload is complete: \n$url');
      _printSnapshot(taskSnapshot);
      // upload thumbnail here
      final thumbName = 'thumbnail@${project.projectId}@${DateTime.now().toUtc().toIso8601String()}.${'jpg'}';
      final firebaseStorageRef2 =
          FirebaseStorage.instance.ref().child(photoStorageName).child(thumbName);
      final thumbUploadTask = firebaseStorageRef2.putFile(thumbnailFile);
      final thumbTaskSnapshot = await thumbUploadTask.whenComplete(() {});
      thumbUrl = await thumbTaskSnapshot.ref.getDownloadURL();
      pp('$mm thumbnail file url is available, meaning that upload is complete: \n$thumbUrl');
      _printSnapshot(thumbTaskSnapshot);
    } catch (e) {
      await _saveFailedMedia(
          file: file,
          thumbnailFile: thumbnailFile,
          project: project,
          projectPosition: projectPosition,
          photo: null,
          video: null);

      listener.onError('File upload failed: $e');
      return uploadError;
    }

    //write to db
    pp('\n$mm adding photo data to the database ...o');
    Photo? photo;
    try {
      var distance = await locationBloc.getDistanceFromCurrentPosition(
          latitude: projectPosition.coordinates[1],
          longitude: projectPosition.coordinates[0]);

      var height = 0, width = 0;
        decodeImageFromList(file.readAsBytesSync(), (image) {
          height = image.height;
          width = image.width;
        });
        pp('$mm the famous photo ========> 🌀 height: $height 🌀 width: $width');

        pp('$mm adding photo ..... 😡😡 distance: '
            '${distance.toStringAsFixed(2)} metres 😡😡');
        photo = Photo(
            url: url,
            caption: 'tbd',
            created: DateTime.now().toUtc().toIso8601String(),
            userId: _user!.userId,
            userName: _user!.name,
            projectPosition: projectPosition,
            distanceFromProjectPosition: distance,
            projectId: project.projectId,
            thumbnailUrl: thumbUrl,
            projectName: project.name,
            organizationId: _user!.organizationId,
            height: height,
            width: width,
            projectPositionId: projectPositionId,
            projectPolygonId: projectPolygonId,
            photoId: const Uuid().v4(),
            landscape: width > height ? 0 : 1);

        await DataAPI.addPhoto(photo);

      pp('\n$mm upload process completed, tell the faithful listener!.');
      listener.onFileUploadComplete(
          url, taskSnapshot.totalBytes, taskSnapshot.bytesTransferred);
      return uploadFinished;
    } catch (e) {
      pp('\n\n$mm 👿👿👿👿 Photo write to database failed, We may have a database problem: 🔴🔴🔴 $e');
      await _saveFailedMedia(
          file: null,
          thumbnailFile: null,
          project: project,
          projectPosition: projectPosition,
          photo: photo,
          video: null);

      listener.onError('We have a database problem $e');
      return uploadError;
    }
  }

  Future<int> uploadVideo(
      {required StorageBlocListener listener,
        required File file,
        required File thumbnailFile,
        required Project project,
        required Position projectPosition,
        String? projectPositionId,
        String? projectPolygonId,}) async {
    pp('\n\n\n$mm️ uploadVideo ☕️☕️☕️☕️☕️☕️☕️️file length: ${await file.length()} bytes');

    var url = 'unknown';
    var thumbUrl = 'unknown';
    late UploadTask uploadTask;
    late TaskSnapshot taskSnapshot;
    try {
      pp('$mm️ uploadVideo ☕️☕️☕️☕️☕️☕️☕️file path: \n${file.path}');
      //upload main file
      var fileName = 'video@${project.projectId}@${DateTime.now().toUtc().toIso8601String()}.${'mp4'}';
      var firebaseStorageRef =
      FirebaseStorage.instance.ref().child(videoStorageName).child(fileName);
      uploadTask = firebaseStorageRef.putFile(file);
      _reportProgress(uploadTask, listener);
      taskSnapshot = await uploadTask.whenComplete(() {});
      url = await taskSnapshot.ref.getDownloadURL();
      pp('$mm file url is available, meaning that upload is complete: \n$url');
      _printSnapshot(taskSnapshot);
      // upload thumbnail here
      final thumbName = 'thumbnail@${project.projectId}@${DateTime.now().toUtc().toIso8601String()}.${'jpg'}';
      final firebaseStorageRef2 =
      FirebaseStorage.instance.ref().child(videoStorageName).child(thumbName);
      final thumbUploadTask = firebaseStorageRef2.putFile(thumbnailFile);
      final thumbTaskSnapshot = await thumbUploadTask.whenComplete(() {});
      thumbUrl = await thumbTaskSnapshot.ref.getDownloadURL();
      pp('$mm thumbnail file url is available, meaning that upload is complete: \n$thumbUrl');
      _printSnapshot(thumbTaskSnapshot);
    } catch (e) {
      pp(e);
      await _saveFailedMedia(
          file: file,
          thumbnailFile: thumbnailFile,
          project: project,
          projectPosition: projectPosition,
          photo: null,
          video: null);
      listener.onError('Video file upload failed: $e');
      return uploadError;
    }
    //write to db
    pp('\n$mm adding video data to the database ... ');
    Video? video;
    try {
      var distance = await locationBloc.getDistanceFromCurrentPosition(
          latitude: projectPosition.coordinates[1],
          longitude: projectPosition.coordinates[0]);

        pp('$mm adding video ..... 😡😡 distance: '
            '${distance.toStringAsFixed(2)} metres 😡😡');
        var u = const Uuid();
        video = Video(
            url: url,
            caption: 'tbd',
            created: DateTime.now().toUtc().toIso8601String(),
            userId: _user!.userId,
            userName: _user!.name,
            projectPosition: projectPosition,
            distanceFromProjectPosition: distance,
            projectId: project.projectId,
            thumbnailUrl: thumbUrl,
            projectName: project.name,
            projectPositionId: projectPositionId,
            projectPolygonId: projectPolygonId,
            organizationId: _user!.organizationId,
            videoId: u.v4());

        await DataAPI.addVideo(video);

      pp('$mm video upload process completed, tell the faithful listener!.\n');
      listener.onFileUploadComplete(
          url, taskSnapshot.totalBytes, taskSnapshot.bytesTransferred);
      return uploadFinished;
    } catch (e) {
      pp('\n\n$mm 👿👿👿👿 Photo/Video write to database failed, We may have a database problem: 🔴🔴🔴 $e');
      await _saveFailedMedia(
          file: null,
          thumbnailFile: null,
          project: project,
          projectPosition: projectPosition,
          photo: null,
          video: video);

      listener.onError('We have a database problem $e');
      return uploadError;
    }

  }

  Future<void> _saveFailedMedia(
      {required File? file,
      required File? thumbnailFile,
      required Project project,
      required Position projectPosition,
      Photo? photo,
      Video? video}) async {

    var failedBag = FailedBag(
        filePath: file?.path,
        thumbnailPath: thumbnailFile?.path,
        project: project,
        projectPosition: projectPosition,
        photo: photo,
        video: video,
        date: DateTime.now().toUtc().toIso8601String());

    await cacheManager.addFailedBag(bag: failedBag);
    pp('\n$mm 🔴🔴🔴 failedBag cached in hive after upload or database failure 🔴🔴🔴');
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
      // var bt = '${(bytesTransferred / 1024).toStringAsFixed(2)} KB';
      // var tot = '${(totalByteCount / 1024).toStringAsFixed(2)} KB';
      //pp('️$mm _reportProgress:  💚 progress ******* 🧩 $bt KB of $tot KB 🧩 transferred');
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
    });
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

  onVideoReady(Video video);
  onAudioReady(Audio audio);

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
