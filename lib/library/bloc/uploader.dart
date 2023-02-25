import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../device_location/device_location_bloc.dart';
import '../api/data_api.dart';
import '../api/prefs_og.dart';
import '../cache_manager.dart';
import '../data/audio.dart';
import '../data/photo.dart';
import '../data/user.dart' as ur;
import '../data/video.dart';
import '../functions.dart';
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

  VideoPlayerController? _videoPlayerController;
  var videoHeight = 0.0;
  var videoWidth = 0.0;
  var videoDurationInSeconds = 0;
  var videoDurationInMinutes = 0.0;

  Future<bool> photoHasBeenUploaded(PhotoForUpload photo) async {
    var deleteList = <PhotoForUpload>[];
    for (var value in photosUploaded) {
      if (photo.photoId == value.photoId) {
        deleteList.add(value);
      }
    }
    for (var value1 in deleteList) {
      await cacheManager.removeUploadedPhoto(photo: photo);
    }
    if (deleteList.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<bool> videoHasBeenUploaded(VideoForUpload video) async {
    var deleteList = <VideoForUpload>[];

    for (var value in videosUploaded) {
      if (video.videoId == value.videoId) {
        deleteList.add(value);
      }
    }
    for (var value1 in deleteList) {
      await cacheManager.removeUploadedVideo(video: video);
    }
    if (deleteList.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<bool> audioHasBeenUploaded(AudioForUpload audio) async {
    var deleteList = <AudioForUpload>[];

    for (var value in audiosUploaded) {
      if (audio.audioId == value.audioId) {
        deleteList.add(value);
      }
    }
    for (var value1 in deleteList) {
      await cacheManager.removeUploadedAudio(audio: audio);
    }
    if (deleteList.isNotEmpty) {
      return true;
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

  late Timer timer;
  Future<void> startTimer(Duration duration) async {
    pp('$mm Uploader timer starting .... duration in seconds: ${duration.inSeconds}');
    //todo - use SettingsModel to govern timer ticks ....
    bool iAmBusy = false;
    photosUploaded.clear();
    videosUploaded.clear();
    audiosUploaded.clear();

    user = await prefsOGx.getUser();
    if (user == null) return;
    timer = Timer.periodic(duration, (timer) async {
      pp('$mm ......... Timer tick: 🍎🍎🍎🍎🍎🍎🍎 ${timer.tick} 🍎 at: '
          '${DateTime.now().toIso8601String()} 🔵🔵🔵');

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
        // pp('$mm upload process not busy,  🎽 🎽 🎽 will start uploads ...iAmBusy: $iAmBusy');
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
      pp('\n\n$mm photos to be uploaded: ${list.length} .... ');
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

      if (cnt > 0) {
        return;
      }
      var polygons = await cacheManager.getProjectPolygons(
          projectId: photoForUpload.project!.projectId!);

      if (polygons.isNotEmpty) {
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
        } else {
          pp('\n\n$mm  photo was taken outside project boundary, will be removed');
          await cacheManager.removeUploadedPhoto(photo: photoForUpload);
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
    var dist = locationBloc.getDistance(
        latitude: latitude,
        longitude: longitude,
        toLatitude: toLatitude,
        toLongitude: toLongitude);

    pp('$mm distance calculated: $dist metres');
    return dist;
  }

  Future<int> _sendPhotoToCloud(PhotoForUpload photoForUploading) async {
    pp('$mm sending photo to cloud ...');
    var isUploaded = photoHasBeenUploaded(photoForUploading);
    if (await isUploaded) {
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
          'photo@${photoForUploading.project!.projectId}@${DateTime.now().toUtc().toIso8601String()}.${'jpg'}';
      var firebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child(photoStorageName)
          .child(fileName);
      var file = File(photoForUploading.filePath!);
      if (!file.existsSync()) {
        await cacheManager.removeUploadedPhoto(photo: photoForUploading);
        return 9;
      }
      pp('$mm️ uploadPhoto ☕️☕️☕️☕️☕️☕️☕️file path: \n${file.path}');

      uploadTask = firebaseStorageRef.putFile(file);
      _reportProgress(uploadTask);
      taskSnapshot = await uploadTask.whenComplete(() {});
      url = await taskSnapshot.ref.getDownloadURL();
      pp('$mm file url is available, meaning that upload is complete: \n$url');
      _printSnapshot(taskSnapshot, 'PHOTO');
      // upload thumbnail here
      final thumbName =
          'thumbnail@${photoForUploading.project!.projectId}@${DateTime.now().toUtc().toIso8601String()}.${'jpg'}';
      final firebaseStorageRef2 = FirebaseStorage.instance
          .ref()
          .child(photoStorageName)
          .child(thumbName);

      var thumbnailFile = File(photoForUploading.thumbnailPath!);
      if (!thumbnailFile.existsSync()) {
        await cacheManager.removeUploadedPhoto(photo: photoForUploading);
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
      var distance = await locationBloc.getDistanceFromCurrentPosition(
          latitude: photoForUploading.position!.coordinates[1],
          longitude: photoForUploading.position!.coordinates[0]);

      var height = 0, width = 0;
      var file = File(photoForUploading.filePath!);
      decodeImageFromList(file.readAsBytesSync(), (image) {
        height = image.height;
        width = image.width;
      });
      pp('$mm the famous photo ========> 🌀 height: $height 🌀 width: $width');

      pp('$mm adding photo ..... 😡😡 distance: '
          '${distance.toStringAsFixed(2)} metres 😡😡');
      photo = Photo(
          url: url,
          userUrl: user!.imageUrl,
          caption: 'tbd',
          created: photoForUploading.date,
          userId: user!.userId,
          userName: user!.name,
          projectPosition: photoForUploading.position!,
          distanceFromProjectPosition: distance,
          projectId: photoForUploading.project!.projectId,
          thumbnailUrl: thumbUrl,
          projectName: photoForUploading.project!.name,
          organizationId: user!.organizationId,
          height: height,
          width: width,
          projectPositionId: photoForUploading.projectPositionId,
          projectPolygonId: photoForUploading.projectPolygonId,
          photoId: photoForUploading.photoId,
          landscape: width > height ? 0 : 1);

      await DataAPI.addPhoto(photo);
      await cacheManager.removeUploadedPhoto(photo: photoForUploading);
      photosUploaded.add(photoForUploading);
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
      } else {
        pp('\n\n$mm  video was taken outside project boundary, will be removed');
        await cacheManager.removeUploadedVideo(video: videoForUpload);
      }
      if (cnt > 0) {
        pp('\n\n$mm .................. 🍎🍎 videos uploaded: $cnt \n');
      }
    }
  }

  Future _getVideoMetadata(
      {required VideoForUpload videoForUpload, required String url}) async {
    pp('\n\n$mm _processVideo:  ... ️💛️💛 getting duration .... ');

    try {
      _videoPlayerController = VideoPlayerController.network(url);
      if (_videoPlayerController != null) {
        pp('\n\n$mm _processVideo:  ... ️💛️💛 videoPlayerController!.initialize .... ');
        await _videoPlayerController!.initialize();
        pp('$mm _processVideo: doing shit with videoController ... getting duration .... '
            ' 🍎DURATION: ${_videoPlayerController!.value.duration} seconds!');

        var size = _videoPlayerController?.value.size;
        videoHeight = size!.height;
        videoWidth = size.width;
        pp('$mm  size of video ... ️💛️💛 '
            'videoHeight: $videoHeight videoWidth: $videoWidth .... ');
        if (_videoPlayerController != null) {
          videoDurationInSeconds =
              _videoPlayerController!.value.duration.inSeconds;

          videoForUpload.durationInSeconds = videoDurationInSeconds;
          videoForUpload.height = videoHeight;
          videoForUpload.width = videoWidth;
        }
      }
    } catch (e) {
      pp('\n\n$mm _processVideo:  ... we down with the video controller, Boss? could not get metadata : $e \n');
    }
  }

  Future<int> _sendVideoToCloud(VideoForUpload videoForUpload) async {
    var isUploaded = videoHasBeenUploaded(videoForUpload);
    if (await isUploaded) {
      pp('$mm a duplicate of this video was found on uploaded list, already uploaded; quit!');
      return 9;
    }
    var url = 'unknown';
    var thumbUrl = 'unknown';
    late UploadTask uploadTask;
    late TaskSnapshot taskSnapshot;
    var file = File(videoForUpload.filePath!);
    try {
      if (!file.existsSync()) {
        await cacheManager.removeUploadedVideo(video: videoForUpload);
        return 9;
      }
      pp('$mm️ uploadVideo: file path: ${file.path}');
      //upload main file
      var fileName =
          'video@${videoForUpload.project!.projectId}@${DateTime.now().toUtc().toIso8601String()}.${'mp4'}';
      var firebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child(videoStorageName)
          .child(fileName);
      uploadTask = firebaseStorageRef.putFile(file);
      _reportProgress(uploadTask);
      taskSnapshot = await uploadTask.whenComplete(() {});
      url = await taskSnapshot.ref.getDownloadURL();
      pp('$mm file url is available, meaning that upload is complete: \n$url');
      _printSnapshot(taskSnapshot, 'VIDEO');
      // upload thumbnail here
      final thumbName =
          'thumbnail@${videoForUpload.project!.projectId}@${DateTime.now().toUtc().toIso8601String()}.${'jpg'}';
      final firebaseStorageRef2 = FirebaseStorage.instance
          .ref()
          .child(videoStorageName)
          .child(thumbName);
      var thumbnailFile = File(videoForUpload.thumbnailPath!);
      if (!thumbnailFile.existsSync()) {
        await cacheManager.removeUploadedVideo(video: videoForUpload);
        return 9;
      }
      final thumbUploadTask = firebaseStorageRef2.putFile(thumbnailFile);
      final thumbTaskSnapshot = await thumbUploadTask.whenComplete(() {});
      thumbUrl = await thumbTaskSnapshot.ref.getDownloadURL();
      pp('$mm thumbnail file url is available, meaning that upload is complete: \n$thumbUrl');
      _printSnapshot(thumbTaskSnapshot, 'VIDEO THUMBNAIL');
      await _getVideoMetadata(videoForUpload: videoForUpload, url: url);
    } catch (e) {
      pp(e);
      return 9;
    }
    //write to db
    pp('\n$mm adding video data to the database ... ');
    Video? video;
    try {
      var distance = await locationBloc.getDistanceFromCurrentPosition(
          latitude: videoForUpload.position!.coordinates[1],
          longitude: videoForUpload.position!.coordinates[0]);

      pp('$mm adding video ..... 😡😡 distance: '
          '${distance.toStringAsFixed(2)} metres 😡😡');
      var u = const Uuid();

      video = Video(
          url: url,
          userUrl: user!.imageUrl,
          caption: 'tbd',
          created: videoForUpload.date,
          durationInSeconds: videoForUpload.durationInSeconds,
          width: videoForUpload.width,
          height: videoForUpload.height,
          userId: user!.userId,
          userName: user!.name,
          projectPosition: videoForUpload.position,
          distanceFromProjectPosition: distance,
          projectId: videoForUpload.project!.projectId,
          thumbnailUrl: thumbUrl,
          projectName: videoForUpload.project!.name,
          projectPositionId: videoForUpload.projectPositionId,
          projectPolygonId: videoForUpload.projectPolygonId,
          organizationId: user!.organizationId,
          videoId: videoForUpload.videoId);

      await DataAPI.addVideo(video);
      await cacheManager.removeUploadedVideo(video: videoForUpload);
      videosUploaded.add(videoForUpload);
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

  Future<int> _sendAudioToCloud(AudioForUpload audioForUploading) async {
    var isUploaded = audioHasBeenUploaded(audioForUploading);
    if (await isUploaded) {
      pp('$mm a duplicate of this audio was found on uploaded list, already uploaded; quit!');
      return 9;
    }

    String url = 'unknown';
    UploadTask? uploadTask;
    var fileName =
        'audio@${audioForUploading.project!.organizationId}@${audioForUploading.project!.projectId}@${DateTime.now().toUtc().toIso8601String()}.mp3';
    var firebaseStorageRef =
        FirebaseStorage.instance.ref().child(audioStorageName).child(fileName);
    var file = File(audioForUploading.filePath!);
    if (!file.existsSync()) {
      await cacheManager.removeUploadedAudio(audio: audioForUploading);
      return 9;
    }
    uploadTask = firebaseStorageRef.putFile(file);
    _reportProgress(uploadTask);
    var taskSnapshot = await uploadTask.whenComplete(() {});
    url = await taskSnapshot.ref.getDownloadURL();
    pp('$mm file url is available, meaning that upload is complete: \n$url');
    _printSnapshot(taskSnapshot, 'AUDIO');
    var dur = await audioPlayer.setUrl(url);
    var audio = Audio(
        url: url,
        userUrl: user!.imageUrl,
        created: audioForUploading.date,
        userId: user!.userId,
        userName: user!.name,
        projectPosition: null,
        distanceFromProjectPosition: 0.0,
        projectId: audioForUploading.project!.projectId,
        audioId: audioForUploading.audioId,
        organizationId: audioForUploading.project!.organizationId,
        projectName: audioForUploading.project!.name,
        durationInSeconds: dur!.inSeconds);

    try {
      var result = await DataAPI.addAudio(audio);
      await cacheManager.addAudio(audio: audio);
      await organizationBloc.addAudioToStream(result);
      await cacheManager.removeUploadedAudio(audio: audioForUploading);
      audiosUploaded.add(audioForUploading);
      pp('\n$mm audio upload process completed OK');
    } catch (e) {
      pp(e);
      return 9;
    }
    return 0;
  }

  void _reportProgress(UploadTask uploadTask) {
    uploadTask.snapshotEvents.listen((event) {
      var totalByteCount = event.totalBytes;
      var bytesTransferred = event.bytesTransferred;
      var bt = '${(bytesTransferred / 1024).toStringAsFixed(2)} KB';
      var tot = '${(totalByteCount / 1024).toStringAsFixed(2)} KB';
      pp('️$mm  💚💚💚 progress ******* 🧩 $bt KB of $tot KB 🧩 transferred 💚');
    });
  }
}
