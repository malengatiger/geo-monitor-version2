import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';

import '../api/data_api.dart';
import '../api/prefs_og.dart';
import '../data/audio.dart';
import '../data/photo.dart';
import '../data/user.dart' as ur;
import '../data/video.dart';
import '../functions.dart';
import '../hive_util.dart';
import '../location/loc_bloc.dart';
import 'audio_for_upload.dart';
import 'organization_bloc.dart';
import 'photo_for_upload.dart';
import 'video_for_upload.dart';

final Uploader uploader = Uploader();
class Uploader {
  final mm = '️☕️☕️☕️☕️☕️☕️☕️ Uploader: 🍎 ';

  bool isStarted = false;
  Random rand = Random(DateTime.now().millisecondsSinceEpoch);
  final photoStorageName = 'geoPhotos';
  final videoStorageName = 'geoVideos';
  final audioStorageName = 'geoAudios';
  AudioPlayer audioPlayer = AudioPlayer();
  ur.User? user;

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

  Future<void> startTimer(Duration duration) async {
    pp('$mm Uploader timer starting .... duration in seconds: ${duration.inSeconds}');

    user = await prefsOGx.getUser();
    Timer.periodic(duration, (timer) async {
      pp('\n\n$mm ......... Timer tick:  🍎🍎🍎🍎🍎🍎🍎 ${timer.tick} 🍎 at: '
          '${DateTime.now().toIso8601String()}');
      await _uploadPhotos();
      await _uploadAudios();
      await _uploadVideos();
    });
    isStarted = true;
  }

  Future _uploadPhotos() async {
    final list = await cacheManager.getPhotoForUpload();
    if (list.isNotEmpty) {
      pp('$mm photos to be uploaded: ${list.length} .... ');
    }
    var cnt = 0;
    for (var m in list) {
      var result = await _sendPhotoToCloud(m);
      if (result == 0) {
        cnt++;
      }
    }
    if (cnt > 0) {
      pp('$mm photos uploaded: $cnt');
    }
  }
  Future<int> _sendPhotoToCloud(PhotoForUpload value) async {
    var url = 'unknown';
    var thumbUrl = 'unknown';
    late UploadTask uploadTask;
    late TaskSnapshot taskSnapshot;
    try {
      //upload main file
      var fileName =  'photo@${value.project!.projectId}@${DateTime.now().toUtc().toIso8601String()}.${'jpg'}';
      var firebaseStorageRef =
      FirebaseStorage.instance.ref().child(photoStorageName).child(fileName);
      var file = File(value.filePath!);
      if (!file.existsSync()) {
        await cacheManager.removeUploadedPhoto(photo: value);
        return 9;
      }
      pp('$mm️ uploadPhoto ☕️☕️☕️☕️☕️☕️☕️file path: \n${file.path}');

      uploadTask = firebaseStorageRef.putFile(file);
      taskSnapshot = await uploadTask.whenComplete(() {});
      url = await taskSnapshot.ref.getDownloadURL();
      pp('$mm file url is available, meaning that upload is complete: \n$url');
      _printSnapshot(taskSnapshot, 'PHOTO');
      // upload thumbnail here
      final thumbName = 'thumbnail@${value.project!.projectId}@${DateTime.now().toUtc().toIso8601String()}.${'jpg'}';
      final firebaseStorageRef2 =
      FirebaseStorage.instance.ref().child(photoStorageName).child(thumbName);

      var thumbnailFile = File(value.thumbnailPath!);
      if (!thumbnailFile.existsSync()) {
        await cacheManager.removeUploadedPhoto(photo: value);
        return 9;
      }
      final thumbUploadTask = firebaseStorageRef2.putFile(thumbnailFile);
      final thumbTaskSnapshot = await thumbUploadTask.whenComplete(() {});
      thumbUrl = await thumbTaskSnapshot.ref.getDownloadURL();
      pp('$mm thumbnail file url is available, meaning that upload is complete: \n$thumbUrl');
      _printSnapshot(thumbTaskSnapshot, 'PHOTO THUMBNAIL');
    } catch (e) {
      pp(e);
      return 9;
    }
    //write to db
    pp('\n$mm adding photo data to the database ...o');
    Photo? photo;
    try {
      var distance = await locationBlocOG.getDistanceFromCurrentPosition(
          latitude: value.position!.coordinates[1],
          longitude: value.position!.coordinates[0]);

      var height = 0, width = 0;
      var file = File(value.filePath!);
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
          userId: user!.userId,
          userName: user!.name,
          projectPosition: value.position!,
          distanceFromProjectPosition: distance,
          projectId: value.project!.projectId,
          thumbnailUrl: thumbUrl,
          projectName: value.project!.name,
          organizationId: user!.organizationId,
          height: height,
          width: width,
          projectPositionId: value.projectPositionId,
          projectPolygonId: value.projectPolygonId,
          photoId: const Uuid().v4(),
          landscape: width > height ? 0 : 1);

      await DataAPI.addPhoto(photo);
      await cacheManager.removeUploadedPhoto(photo: value);
      pp('\n$mm upload process completed, tell the faithful listener!.');
      return 0;
    } catch (e) {
      pp('\n\n$mm 👿👿👿👿 Photo write to database failed, We may have a database problem: 🔴🔴🔴 $e');
      return 9;
    }
  }
  Future _uploadVideos() async {
    final list = await cacheManager.getVideoForUpload();
    if (list.isNotEmpty) {
      pp('$mm videos to be uploaded: ${list.length} .... ');
    }

    var cnt = 0;
    for (var value in list) {
      var result = await _sendVideoToCloud(value);
      if (result == 0) {
        cnt++;
      }
    }
    if (cnt > 0) {
      pp('$mm videos uploaded: $cnt');
    }

  }

  Future<int> _sendVideoToCloud(VideoForUpload value) async {
    var url = 'unknown';
    var thumbUrl = 'unknown';
    late UploadTask uploadTask;
    late TaskSnapshot taskSnapshot;
    try {
      var file = File(value.filePath!);
      if (!file.existsSync()) {
        await cacheManager.removeUploadedVideo(video: value);
        return 9;
      }
      pp('$mm️ uploadVideo file path: \n${file.path}');
      //upload main file
      var fileName = 'video@${value.project!.projectId}@${DateTime.now().toUtc().toIso8601String()}.${'mp4'}';
      var firebaseStorageRef =
      FirebaseStorage.instance.ref().child(videoStorageName).child(fileName);
      uploadTask = firebaseStorageRef.putFile(file);

      taskSnapshot = await uploadTask.whenComplete(() {});
      url = await taskSnapshot.ref.getDownloadURL();
      pp('$mm file url is available, meaning that upload is complete: \n$url');
      _printSnapshot(taskSnapshot, 'VIDEO');
      // upload thumbnail here
      final thumbName = 'thumbnail@${value.project!.projectId}@${DateTime.now().toUtc().toIso8601String()}.${'jpg'}';
      final firebaseStorageRef2 =
      FirebaseStorage.instance.ref().child(videoStorageName).child(thumbName);
      var thumbnailFile = File(value.thumbnailPath!);
      if (!thumbnailFile.existsSync()) {
        await cacheManager.removeUploadedVideo(video: value);
        return 9;
      }
      final thumbUploadTask = firebaseStorageRef2.putFile(thumbnailFile);
      final thumbTaskSnapshot = await thumbUploadTask.whenComplete(() {});
      thumbUrl = await thumbTaskSnapshot.ref.getDownloadURL();
      pp('$mm thumbnail file url is available, meaning that upload is complete: \n$thumbUrl');
      _printSnapshot(thumbTaskSnapshot, 'VIDEO THUMBNAIL');
    } catch (e) {
      pp(e);
      return 9;
    }
    //write to db
    pp('\n$mm adding video data to the database ... ');
    Video? video;
    try {
      var distance = await locationBlocOG.getDistanceFromCurrentPosition(
          latitude: value.position!.coordinates[1],
          longitude: value.position!.coordinates[0]);

      pp('$mm adding video ..... 😡😡 distance: '
          '${distance.toStringAsFixed(2)} metres 😡😡');
      var u = const Uuid();
      video = Video(
          url: url,
          caption: 'tbd',
          created: DateTime.now().toUtc().toIso8601String(),
          userId: user!.userId,
          userName: user!.name,
          projectPosition: value.position,
          distanceFromProjectPosition: distance,
          projectId: value.project!.projectId,
          thumbnailUrl: thumbUrl,
          projectName: value.project!.name,
          projectPositionId: value.projectPositionId,
          projectPolygonId: value.projectPolygonId,
          organizationId: user!.organizationId,
          videoId: u.v4());

      await DataAPI.addVideo(video);
      await cacheManager.removeUploadedVideo(video: value);
      pp('$mm video upload process completed, tell the faithful listener!.\n');

      return 0;
    } catch (e) {
      pp('\n\n$mm 👿👿👿👿 Video write to database failed, We may have a database problem: 🔴🔴🔴 $e');
      return 9;
    }

  }

  Future _uploadAudios() async {
    final list = await cacheManager.getAudioForUpload(); var cnt = 0;
    if (list.isNotEmpty) {
      pp('$mm audios to be uploaded: ${list.length} .... ');
    }

    for (var value in list) {
      try {
        var result = await _sendAudioToCloud(value);
        if (result == 0) {
          cnt++;
        }
      } catch (e) {
        pp('$mm Upload failed save the details ...');
      }
    }
    if (cnt > 0) {
      pp('$mm audios uploaded: $cnt');
    }

  }

  Future<int> _sendAudioToCloud(AudioForUpload value) async {
    String url = 'unknown';
    UploadTask? uploadTask;
    var fileName =
        'audio@${value.project!.organizationId}@${value.project!.projectId}@${DateTime.now().toUtc().toIso8601String()}.mp3';
    var firebaseStorageRef = FirebaseStorage.instance
        .ref()
        .child(audioStorageName)
        .child(fileName);
    var file = File(value.filePath!);
    if (!file.existsSync()) {
      await cacheManager.removeUploadedAudio(audio: value);
      return 9;
    }
    uploadTask = firebaseStorageRef.putFile(file);
    var taskSnapshot = await uploadTask.whenComplete(() {});
    url = await taskSnapshot.ref.getDownloadURL();
    pp('$mm file url is available, meaning that upload is complete: \n$url');
    _printSnapshot(taskSnapshot, 'AUDIO');
    var dur = await audioPlayer.setUrl(url);
    var audio = Audio(
        url: url,
        created: DateTime.now().toUtc().toIso8601String(),
        userId: user!.userId,
        userName: user!.name,
        projectPosition: null,
        distanceFromProjectPosition: 0.0,
        projectId: value.project!.projectId,
        audioId: const Uuid().v4(),
        organizationId: value.project!.organizationId,
        projectName: value.project!.name,
        durationInSeconds: dur!.inSeconds);

    try {
      var result = await DataAPI.addAudio(audio);
      await organizationBloc.addAudioToStream(result);
      await cacheManager.removeUploadedAudio(audio: value);
    } catch (e) {
      pp(e);
      return 9;
    }
    return 0;
  }
}
