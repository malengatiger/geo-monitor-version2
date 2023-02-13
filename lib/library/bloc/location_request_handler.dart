import 'dart:async';

import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/data/location_request.dart';
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

  Future sendLocationRequest(
      {required String requesterId,
      required String requesterName,
      required String userId,
      required String userName}) async {
    pp('$mm sendLocationRequest ... getting user');
    var user = await prefsOGx.getUser();
    if (user == null) {
      pp('$mm ..... user is null, cannot send location request ....');
      return;
    }
    pp('$mm ..... sending user location request ....');
    var req = LocationRequest(
      organizationId: user.organizationId,
      requesterId: requesterId,
      requesterName: requesterName,
      userName: userName,
      userId: userId,
      organizationName: user.organizationName,
      created: DateTime.now().toUtc().toIso8601String(),
    );

    var result = await DataAPI.sendLocationRequest(req);
    pp('$mm  LocationRequest sent to cloud backend, result: ${result.toJson()}');
  }

  /// user response to a locationRequest
  Future sendLocationResponse(
      {required String requesterId, required String requesterName}) async {
    pp('$mm sendLocationResponse ... getting user');
    var user = await prefsOGx.getUser();
    if (user == null) return;
    pp('$mm ..... sending user location response ....');
    var loc = await locationBlocOG.getLocation();
    if (loc != null) {
      var locResp = LocationResponse(
          position: Position(
              coordinates: [loc.longitude, loc.latitude], type: 'Point'),
          date: DateTime.now().toUtc().toIso8601String(),
          userId: user.userId,
          userName: user.name,
          requesterName: requesterName,
          requesterId: requesterId,
          locationResponseId: const Uuid().v4(),
          organizationId: user.organizationId,
          organizationName: user.organizationName);

      var result = await DataAPI.addLocationResponse(locResp);
      pp('$mm  LocationResponse sent to database, result: ${result.toJson()}');
    }
  }
}
