import 'dart:async';

import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/data/location_request.dart';
import 'package:geo_monitor/library/data/user.dart';
import 'package:uuid/uuid.dart';
import '../api/data_api.dart';
import '../data/location_response.dart';
import '../data/position.dart';
import '../functions.dart';
import '../location/loc_bloc.dart';

final LocationRequestHandler locationRequestHandler = LocationRequestHandler();

class LocationRequestHandler {
  final mm = '️🌀🌀🌀🌀LocationRequestHandler: 🍎 ';
  bool isStarted = false;

  Future<void> startLocationRequestTimer() async {
    pp('$mm starting Timer to send out location requests');
    var user = await prefsOGx.getUser();
    if (user == null) {
      pp('$mm Not ready to make location requests');
      return;
    }
    if (user.userType! == UserType.fieldMonitor) {
      pp('$mm FieldMonitors are not allowed to make location requests');
      return;
    }
    Timer.periodic(const Duration(minutes: 60), (timer) async {
      pp('\n\n$mm ........................ Timer tick: ${timer.tick} '
          'at ${DateTime.now().toIso8601String()}');
      await sendLocationRequest();
    });

    isStarted = true;
  }

  Future sendLocationRequest() async {
    pp('$mm sendLocationRequest ... getting user');
    var user = await prefsOGx.getUser();
    if (user == null) {
      pp('$mm ..... user is null, cannot send location request ....');
      return;
    }
    pp('$mm ..... sending user location request ....');
    var req = LocationRequest(
        organizationId: user.organizationId,
        administratorId: user.organizationId,
        created: DateTime.now().toUtc().toIso8601String(),
        response: '');

    var result = await DataAPI.sendLocationRequest(req);
    pp('$mm  LocationRequest sent to cloud messaging, result: ${result.toJson()}');
  }

  Future<void> startLocationResponseTimer() async {
    pp('$mm starting Timer to send out location requests');
    var user = await prefsOGx.getUser();
    if (user == null) {
      pp('$mm Not ready to make location requests');
      return;
    }
    if (user.userType! != UserType.fieldMonitor) {
      pp('$mm Only field monitors are allowed to automatically send location response');
      return;
    }
    Timer.periodic(const Duration(minutes: 60), (timer) async {
      pp('\n\n$mm ........................ LocationResponse Timer tick: ${timer.tick} '
          'at ${DateTime.now().toIso8601String()}');
      await sendLocationResponse();
    });

    isStarted = true;
  }

  Future sendLocationResponse() async {

    pp('$mm sendLocationResponse ... getting user');
    var user = await prefsOGx.getUser();
    if (user == null) return;
    pp('$mm ..... sending user location response ....');
    var loc = await locationBlocOG.getLocation();
    if (loc != null) {
      var locResp = LocationResponse(
          position: Position(coordinates: [loc.longitude, loc.latitude],
              type: 'Point'),
          date: DateTime.now().toUtc().toIso8601String(),
          userId: user.userId,
          userName: user.name,
          locationResponseId: const Uuid().v4(),
          organizationId: user.organizationId,
          organizationName: user.organizationName);

      var result = await DataAPI.addLocationResponse(locResp);
      pp('$mm  LocationResponse sent to database, result: ${result.toJson()}');
    }
  }
}

