import 'dart:async';

import 'package:geo_monitor/library/hive_util.dart';

import '../api/data_api.dart';
import '../data/photo.dart';
import '../data/video.dart';
import '../functions.dart';

final WriteFailedMedia writeFailedMedia = WriteFailedMedia();

class WriteFailedMedia {
  final mm = '️🌀🌀🌀🌀WriteFailedMedia: 🍎 ';
  late Timer _timer;
  bool isStarted = false;

  void startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 3), (timer) async {
      pp('$mm Timer tick: ${timer.tick} at ${DateTime.now().toIso8601String()}');
      await writeFailedPhotos();
      await writeFailedVideos();
    });
    isStarted = true;
  }
  void stopTimer() {
    if (isStarted) {
      _timer.cancel();
    }
  }
  Future writeFailedPhotos() async {
    var photos = await hiveUtil.getFailedPhotos();
    pp('$mm write ${photos.length} photos to database');
    if (photos.isEmpty) {
      pp('$mm No failed photo to process');
      return;
    }
    for (var photo in photos) {
      var isOK = await writePhoto(photo: photo);
      if (isOK) {
        await _deletePhoto(photo);
      }
    }
    pp('$mm failed photos written to database');
  }
  Future writeFailedVideos() async {
    var videos = await hiveUtil.getFailedVideos();
    pp('$mm write ${videos.length} videos to database');
    if (videos.isEmpty) {
      pp('$mm No failed video to process');
      return;
    }
    for (var video in videos) {
      var isOK = await writeVideo(video: video);
      if (isOK) {
        await _deleteVideo(video);
      }
    }
    pp('$mm failed videos written to database');
  }

  Future writePhoto({required Photo photo}) async  {
    await DataAPI.addPhoto(photo);
    pp('$mm failed photo written to DB');
    return true;
  }
  Future writeVideo({required Video video}) async {
    await DataAPI.addVideo(video);
    pp('$mm failed video written to DB');
    return true;
  }
  Future _deletePhoto(Photo photo) async {
    pp('$mm delete failed photo from cache ...');
    await hiveUtil.removeFailedPhoto(photo: photo);
  }
  Future _deleteVideo(Video video) async {
    pp('$mm delete failed video from cache ...');
    await hiveUtil.removeFailedVideo(video: video);
  }
}