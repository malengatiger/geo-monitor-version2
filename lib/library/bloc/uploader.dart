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

final Uploader uploader = Uploader._instance;

class Uploader {
  final mm = '️☕️☕️☕️☕️☕️☕️☕️ 🍎Uploader: 🍎 ';
  static final Uploader _instance = Uploader._internal();

  factory Uploader() {
    return _instance;
  }

  Uploader._internal();

  Random rand = Random(DateTime.now().millisecondsSinceEpoch);
  final photoStorageName = 'geoPhotos3';
  final videoStorageName = 'geoVideos3';
  final audioStorageName = 'geoAudios3';

  AudioPlayer audioPlayer = AudioPlayer();
  ur.User? user;

  final photosUploaded = <PhotoForUpload>[];
  final videosUploaded = <VideoForUpload>[];
  final audiosUploaded = <AudioForUpload>[];

  bool photoHasBeenUploaded(PhotoForUpload photo) {
    for (var value in photosUploaded) {
      if (photo.photoId == value.photoId) {
        return true;
      }
    }
    return false;
  }

  bool videoHasBeenUploaded(VideoForUpload video) {
    for (var value in videosUploaded) {
      if (video.videoId == value.videoId) {
        return true;
      }
    }
    return false;
  }

  bool audioHasBeenUploaded(AudioForUpload audio) {
    for (var value in audiosUploaded) {
      if (audio.audioId == value.audioId) {
        return true;
      }
    }
    return false;
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

  Future<void> startTimer(Duration duration) async {
    pp('$mm Uploader timer starting .... duration in seconds: ${duration.inSeconds}');
    bool iAmBusy = false;
    photosUploaded.clear();
    videosUploaded.clear();
    audiosUploaded.clear();

    user = await prefsOGx.getUser();
    if (user == null) return;
    Timer.periodic(duration, (timer) async {
      pp('$mm ......... Timer tick: 🍎🍎🍎🍎🍎🍎🍎 ${timer.tick} 🍎 at: '
          '${DateTime.now().toIso8601String()}');

      if (photosUploaded.isNotEmpty) {
        pp('$mm photos uploaded so far: ${photosUploaded.length}');
      }
      if (videosUploaded.isNotEmpty) {
        pp('$mm videos uploaded so far: ${videosUploaded.length}');
      }
      if (audiosUploaded.isNotEmpty) {
        pp('$mm audios uploaded so far: ${audiosUploaded.length}');
      }
      if (!iAmBusy) {
        pp('$mm upload process not busy,  🎽 🎽 🎽 will start uploads ...iAmBusy: $iAmBusy');
        iAmBusy = true;
        await _uploadPhotos();
        await _uploadAudios();
        await _uploadVideos();
        iAmBusy = false;
      } else {
        pp('$mm upload process iAmBusy, will wait for next timer tick');
      }
    });
  }

  Future _uploadPhotos() async {
    final list = await cacheManager.getPhotosForUpload();
    if (list.isNotEmpty) {
      pp('$mm photos to be uploaded: ${list.length} .... ');
    }
    var cnt = 0;
    for (var photoForUpload in list) {
      var positions = await cacheManager
          .getProjectPositions(photoForUpload.project!.projectId!);
      for (var projectPosition in positions) {
        var dist = await getDistance(
            latitude: photoForUpload.position!.coordinates[1],
            longitude: photoForUpload.position!.coordinates[0],
            toLatitude: projectPosition.position!.coordinates[1],
            toLongitude: projectPosition.position!.coordinates[0]);

        if (dist <= photoForUpload.project!.monitorMaxDistanceInMetres!) {
          pp('$mm photo was taken within project boundary .... will be uploaded.');
          var result = await _sendPhotoToCloud(photoForUpload);
          if (result == 0) {
            cnt++;
          }
          break;
        }
      }
      var polygons = await cacheManager.getProjectPolygons(
          projectId: photoForUpload.project!.projectId!);

      var isWithin = checkIfLocationIsWithinPolygons(
          polygons: polygons,
          latitude: photoForUpload.position!.coordinates[1],
          longitude: photoForUpload.position!.coordinates[0]);

      if (isWithin) {
        pp('$mm photo was taken within project area boundary .... will be uploaded.');
        var result = await _sendPhotoToCloud(photoForUpload);
        if (result == 0) {
          cnt++;
        }
      }
    }
    if (cnt > 0) {
      pp('\n\n$mm ................. 🍎🍎photos uploaded: $cnt\n');
    }
  }

  Future<double> getDistance(
      {required double latitude,
      required double longitude,
      required double toLatitude,
      required double toLongitude}) async {
    var dist = await locationBlocOG.getDistance(
        latitude: latitude,
        longitude: longitude,
        toLatitude: toLatitude,
        toLongitude: toLongitude);

    return dist;
  }

  Future<int> _sendPhotoToCloud(PhotoForUpload value) async {
    var isUploaded = photoHasBeenUploaded(value);
    if (isUploaded) {
      pp('$mm isUploaded duplicate of this photo was found on uploaded list, already uploaded; quit!');
      return 9;
    }
    var url = 'unknown';
    var thumbUrl = 'unknown';
    late UploadTask uploadTask;
    late TaskSnapshot taskSnapshot;
    try {
      //upload main file
      var fileName =
          'photo@${value.project!.projectId}@${DateTime.now().toUtc().toIso8601String()}.${'jpg'}';
      var firebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child(photoStorageName)
          .child(fileName);
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
      final thumbName =
          'thumbnail@${value.project!.projectId}@${DateTime.now().toUtc().toIso8601String()}.${'jpg'}';
      final firebaseStorageRef2 = FirebaseStorage.instance
          .ref()
          .child(photoStorageName)
          .child(thumbName);

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
          photoId: value.photoId,
          landscape: width > height ? 0 : 1);

      await DataAPI.addPhoto(photo);
      await cacheManager.removeUploadedPhoto(photo: value);
      photosUploaded.add(value);
      await organizationBloc.addPhotoToStream(photo);
      pp('\n$mm photo upload process completed OK');

      return 0;
    } catch (e) {
      pp('\n\n$mm 👿👿👿👿 Photo write to database failed, We may have isUploaded database problem: 🔴🔴🔴 $e');
      return 9;
    }
  }

  Future _uploadVideos() async {
    final list = await cacheManager.getVideosForUpload();
    if (list.isNotEmpty) {
      pp('$mm videos to be uploaded: ${list.length} .... ');
    }

    var cnt = 0;
    for (var videoForUpload in list) {
      var positions = await cacheManager
          .getProjectPositions(videoForUpload.project!.projectId!);
      for (var projectPosition in positions) {
        var dist = await getDistance(
            latitude: videoForUpload.position!.coordinates[1],
            longitude: videoForUpload.position!.coordinates[0],
            toLatitude: projectPosition.position!.coordinates[1],
            toLongitude: projectPosition.position!.coordinates[0]);
        if (dist <= videoForUpload.project!.monitorMaxDistanceInMetres!) {
          pp('$mm video was taken within project boundary .... will be uploaded.');
          var result = await _sendVideoToCloud(videoForUpload);
          if (result == 0) {
            cnt++;
          }
          break;
        }
      }
      var polygons = await cacheManager.getProjectPolygons(
          projectId: videoForUpload.project!.projectId!);
      var isWithin = checkIfLocationIsWithinPolygons(
          polygons: polygons,
          latitude: videoForUpload.position!.coordinates[1],
          longitude: videoForUpload.position!.coordinates[0]);
      if (isWithin) {
        pp('$mm video was taken within project area boundary .... will be uploaded.');
        var result = await _sendVideoToCloud(videoForUpload);
        if (result == 0) {
          cnt++;
        }
      }
      if (cnt > 0) {
        pp('\n\n$mm .................. 🍎🍎 videos uploaded: $cnt \n');
      }
    }
  }

  Future<int> _sendVideoToCloud(VideoForUpload value) async {
    var isUploaded = videoHasBeenUploaded(value);
    if (isUploaded) {
      pp('$mm a duplicate of this video was found on uploaded list, already uploaded; quit!');
      return 9;
    }
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
      var fileName =
          'video@${value.project!.projectId}@${DateTime.now().toUtc().toIso8601String()}.${'mp4'}';
      var firebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child(videoStorageName)
          .child(fileName);
      uploadTask = firebaseStorageRef.putFile(file);

      taskSnapshot = await uploadTask.whenComplete(() {});
      url = await taskSnapshot.ref.getDownloadURL();
      pp('$mm file url is available, meaning that upload is complete: \n$url');
      _printSnapshot(taskSnapshot, 'VIDEO');
      // upload thumbnail here
      final thumbName =
          'thumbnail@${value.project!.projectId}@${DateTime.now().toUtc().toIso8601String()}.${'jpg'}';
      final firebaseStorageRef2 = FirebaseStorage.instance
          .ref()
          .child(videoStorageName)
          .child(thumbName);
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
          videoId: value.videoId);

      await DataAPI.addVideo(video);
      await cacheManager.removeUploadedVideo(video: value);
      videosUploaded.add(value);
      await cacheManager.addVideo(video: video);
      await organizationBloc.addVideoToStream(video);

      pp('\n$mm video upload process completed OK.\n');

      return 0;
    } catch (e) {
      pp('\n\n$mm 👿👿👿👿 Video write to database failed, We may have a database problem: 🔴🔴🔴 $e');
      return 9;
    }
  }

  Future _uploadAudios() async {
    final list = await cacheManager.getAudioForUpload();
    var cnt = 0;
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
    var isUploaded = audioHasBeenUploaded(value);
    if (isUploaded) {
      pp('$mm a duplicate of this audio was found on uploaded list, already uploaded; quit!');
      return 9;
    }

    String url = 'unknown';
    UploadTask? uploadTask;
    var fileName =
        'audio@${value.project!.organizationId}@${value.project!.projectId}@${DateTime.now().toUtc().toIso8601String()}.mp3';
    var firebaseStorageRef =
        FirebaseStorage.instance.ref().child(audioStorageName).child(fileName);
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
        audioId: value.audioId,
        organizationId: value.project!.organizationId,
        projectName: value.project!.name,
        durationInSeconds: dur!.inSeconds);

    try {
      var result = await DataAPI.addAudio(audio);
      await cacheManager.addAudio(audio: audio);
      await organizationBloc.addAudioToStream(result);
      await cacheManager.removeUploadedAudio(audio: value);
      audiosUploaded.add(value);
      pp('\n$mm audio upload process completed OK');
    } catch (e) {
      pp(e);
      return 9;
    }
    return 0;
  }
}
