import 'dart:async';

import 'package:geo_monitor/library/bloc/failed_bag.dart';
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

  void startTimer(Duration duration) {
    _timer = Timer.periodic(duration, (timer) async {
      pp('\n\n$mm ... Timer tick: ${timer.tick} at ${DateTime.now().toIso8601String()}');
      await writeFailedMedia();
    });
    isStarted = true;
  }
  void stopTimer() {
    if (isStarted) {
      _timer.cancel();
    }
  }

  Future writeFailedMedia() async {
    var bags = await hiveUtil.getFailedBags();
    for (var bag in bags) {
      if (bag.photo != null) {
        var isOK = await writePhoto(photo: bag.photo!);
        if (isOK) {
          await _deleteBag(bag);
        }
      }
      if (bag.video != null) {
        var isOK = await writeVideo(video: bag.video!);
        if (isOK) {
          await _deleteBag(bag);
        }
      }
    }
    pp('$mm ${bags.length} failed bags written to database');
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

  Future _deleteBag(FailedBag bag) async {
    pp('$mm delete failed bag from cache ...');
    await hiveUtil.removeFailedBag(bag: bag);
  }

}