import 'dart:async';

import 'package:geo_monitor/library/api/sharedprefs.dart';
import 'package:geo_monitor/library/bloc/failed_audio.dart';
import 'package:geo_monitor/library/bloc/failed_bag.dart';
import 'package:geo_monitor/library/data/audio.dart';
import 'package:geo_monitor/library/data/location_request.dart';
import 'package:geo_monitor/library/hive_util.dart';

import '../api/data_api.dart';
import '../data/photo.dart';
import '../data/video.dart';
import '../functions.dart';

final LocationRequestHandler locationRequestHandler = LocationRequestHandler();

class LocationRequestHandler {
  final mm = '️🌀🌀🌀🌀LocationRequestHandler: 🍎 ';
  late Timer _timer;
  bool isStarted = false;

  void startTimer() {
    pp('$mm starting Timer to send out location requests');
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      pp('\n\n$mm ... Timer tick: ${timer.tick} at ${DateTime.now().toIso8601String()}');
      await sendLocationRequest();
    });

    isStarted = true;
  }
  void stopTimer() {
    if (isStarted) {
      _timer.cancel();
    }
  }

  Future sendLocationRequest() async {
    pp('$mm sending location request ....');
    var user = await Prefs.getUser();
    var req = LocationRequest(
        organizationId: user!.organizationId,
        administratorId: user.organizationId,
        created: DateTime.now().toUtc().toIso8601String(),
        response: '');

    var result = await DataAPI.sendLocationRequest(req);
    pp('$mm  LocationRequest sent to cloud messaging: ${result.toJson()}');
  }

}