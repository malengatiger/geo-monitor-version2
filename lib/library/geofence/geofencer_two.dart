import 'dart:async';

import 'package:geo_monitor/library/data/position.dart';
import 'package:geofence_service/geofence_service.dart';
import 'package:geofence_service/models/geofence.dart' as geo;
import 'package:uuid/uuid.dart';

import '../../device_location/device_location_bloc.dart';
import '../../l10n/translation_handler.dart';
import '../api/data_api.dart';
import '../api/prefs_og.dart';
import '../bloc/organization_bloc.dart';
import '../data/geofence_event.dart';
import '../data/project_position.dart';
import '../data/user.dart';
import '../functions.dart';

final geofenceService = GeofenceService.instance.setup(
    interval: 5000,
    accuracy: 100,
    loiteringDelayMs: 60000,
    statusChangeDelayMs: 10000,
    useActivityRecognition: true,
    allowMockLocations: false,
    printDevLog: false,
    geofenceRadiusSortType: GeofenceRadiusSortType.DESC);

final TheGreatGeofencer theGreatGeofencer = TheGreatGeofencer();

class TheGreatGeofencer {
  static const mm = '💦 💦 💦 💦 💦 TheGreatGeofencer: 💦 💦 ';
  final xx = '😡😡😡😡😡😡😡 TheGreatGeofencer: 😡😡 ';
  final StreamController<GeofenceEvent> _streamController =
      StreamController.broadcast();
  Stream<GeofenceEvent> get geofenceEventStream => _streamController.stream;

  final _geofenceList = <geo.Geofence>[];
  User? _user;

  // Future initialize() async {
  //   pp('$mm Create a [GeofenceService] instance and set options.....');
  //   var geofenceService = GeofenceService.instance.setup(
  //       interval: 5000,
  //       accuracy: 100,
  //       loiteringDelayMs: 30000,
  //       statusChangeDelayMs: 10000,
  //       useActivityRecognition: true,
  //       allowMockLocations: false,
  //       printDevLog: true,
  //       geofenceRadiusSortType: GeofenceRadiusSortType.DESC);
  //
  //   pp('\n\n$mm GeofenceService initialized .... 🌺 🌺 🌺 ');
  //
  //   _user = await prefsOGx.getUser();
  //   if (_user != null) {
  //     pp('$mm Geofences for Organization: ${_user!.organizationId} name: ${_user!.organizationName} .... 🌺 🌺 🌺 ');
  //     pp('$mm Geofences for User: ${_user!.toJson()}');
  //   }
  // }

  Future<List<ProjectPosition>> _findProjectPositionsByLocation(
      {required String organizationId,
      required double latitude,
      required double longitude,
      required double radiusInKM}) async {
    var mList = await DataAPI.findProjectPositionsByLocation(
        organizationId: organizationId,
        latitude: latitude,
        longitude: longitude,
        radiusInKM: radiusInKM);
    // var mList = await cacheManager.getOrganizationProjectPositions(organizationId: organizationId);
    pp('$mm _getProjectPositionsByLocation: found ${mList.length}\n');
    return mList;
  }

  Future buildGeofences({double? radiusInKM}) async {
    pp('$xx buildGeofences .... build geofences for the organization started ... 🌀 ');
    _user ??= await prefsOGx.getUser();
    if (_user == null) {
      return;
    }

    pp('$xx buildGeofences .... build geofences for the organization 🌀 ${_user!.organizationName}  🌀');

    await locationBloc.requestPermission();
    var startDate = DateTime.now()
        .subtract(const Duration(days: (365 * 2)))
        .toUtc()
        .toIso8601String();
    var endDate = DateTime.now().toUtc().toIso8601String();

    var mList = await organizationBloc.getProjectPositions(
        organizationId: _user!.organizationId!,
        forceRefresh: false,
        startDate: startDate,
        endDate: endDate);
    try {
      if (mList.isEmpty || mList.length > 98) {
        var loc = await locationBloc.getLocation();
        mList = await _findProjectPositionsByLocation(
            organizationId: _user!.organizationId!,
            latitude: loc!.latitude!,
            longitude: loc!.longitude!,
            radiusInKM: radiusInKM ?? 5);
        pp('$xx buildGeofences .... project positions found by location: ${mList
            .length} ');
      }
    } catch (e) {
      pp(e);
    }

    int cnt = 0;
    for (var pos in mList) {
      await addGeofence(projectPosition: pos);
      cnt++;
      if (cnt > 98) {
        break;
      }
    }
    pp('$xx ${_geofenceList.length} geofences added to list');
    geofenceService.addGeofenceList(_geofenceList);
    geofenceService.addGeofenceStatusChangeListener(
        (geofence, geofenceRadius, geofenceStatus, location) async {
      pp('$xx Geofence Listener 💠 FIRED!! '
          '🔵🔵🔵 geofenceStatus: ${geofenceStatus.name}  at 🔶 ${geofence.data['projectName']}');

      await _processGeofenceEvent(
          geofence: geofence,
          geofenceRadius: geofenceRadius,
          geofenceStatus: geofenceStatus,
          location: location);
    });

    try {
      pp('$xx  🔶🔶🔶🔶🔶🔶 Starting GeofenceService ...... 🔶🔶🔶🔶🔶🔶 ');
      await geofenceService.start().onError((error, stackTrace) => {
            pp('\n\n\n$mm $reds GeofenceService failed to start, onError: 🔴 $error 🔴 \n\n\n')
            //todo - navigate user to system settings - explain why activity permission required
            //todo - see ErrorCodes.ACTIVITY_RECOGNITION_PERMISSION_PERMANENTLY_DENIED
          });

      pp('$xx ✅✅✅✅✅✅ geofences 🍐🍐🍐 STARTED OK 🍐🍐🍐 '
          '🔆🔆🔆 will wait for geofence status change 🔵🔵🔵🔵🔵 ');
    } catch (e) {
      pp('\n\n$xx GeofenceService failed to start: 🔴 $e 🔴 }');
    }

  }

  final reds = '🔴 🔴 🔴 🔴 🔴 🔴 TheGreatGeofencer: ';
  void onError() {}

  Future _processGeofenceEvent(
      {required Geofence geofence,
      required GeofenceRadius geofenceRadius,
      required GeofenceStatus geofenceStatus,
      required Location location}) async {
    // pp('$xx _processing new GeofenceEvent; 🔵 ${geofence.data['projectName']} '
    //     '🔵geofenceStatus: ${geofenceStatus.toString()}');

    var loc = await locationBloc.getLocation();

    final sett = await prefsOGx.getSettings();
    String message = 'A member has arrived at ${ geofence.data['projectName']}';
    String title = 'Message from Geo';
    if (sett != null) {
      final arr = await mTx.translate('arrivedAt', sett.locale!);
      message = arr.replaceAll('\$project', geofence.data['projectName']);
    }

    if (loc != null) {
      var event = GeofenceEvent(
          status: geofenceStatus.toString(),
          organizationId: geofence.data['organizationId'],
          translatedMessage: message,
          user: _user,
          position: Position(
              coordinates: [loc.longitude, loc.latitude], type: 'Point'),
          geofenceEventId: const Uuid().v4(),
          projectPositionId: geofence.id,
          projectId: geofence.data['projectId'],
          projectName: geofence.data['projectName'],
          date: DateTime.now().toUtc().toIso8601String(),
          translatedTitle: title);

      String status = geofenceStatus.toString();
      switch (status) {
        case 'GeofenceStatus.ENTER':
          event.status = 'ENTER';
          pp('$xx IGNORING geofence ENTER event for ${event.projectName}');
          break;
        case 'GeofenceStatus.DWELL':
          event.status = 'DWELL';
          var gfe = await DataAPI.addGeofenceEvent(event);
          pp('$xx geofence event added to database for ${event.projectName}');
          _streamController.sink.add(gfe);
          break;
        case 'GeofenceStatus.EXIT':
          event.status = 'EXIT';
          var gfe = await DataAPI.addGeofenceEvent(event);
          pp('$xx geofence event added to database for ${event.projectName}');
          _streamController.sink.add(gfe);
          break;
      }
    } else {
      pp('$mm $reds UNABLE TO PROCESS GEOFENCE - location not available');
      throw Exception('No location available');
    }
  }

  Future addGeofence({required ProjectPosition projectPosition}) async {
    projectPosition.nearestCities = [];
    if (projectPosition.position != null) {
      var fence = Geofence(
        id: '${projectPosition.projectId!}_${DateTime.now().microsecondsSinceEpoch}',
        data: projectPosition.toJson(),
        latitude: projectPosition.position!.coordinates[1],
        longitude: projectPosition.position!.coordinates[0],
        radius: [
          GeofenceRadius(id: 'radius_150m', length: 150),
          // GeofenceRadius(id: 'radius_100m', length: 100),
        ],
      );

      _geofenceList.add(fence);
      pp('$mm added Geofence : 👽👽👽 ${projectPosition.projectName} 👽👽👽👽 '
          '_geofenceList now has ${_geofenceList.length} fences 🍎 ');
    } else {
      pp('🔴🔴🔴🔴🔴🔴 project position is null, WTF??? ${projectPosition.projectName}');
    }
  }

  var defaultRadiusInKM = 100.0;
  var defaultRadiusInMetres = 150.0;
  var defaultDwellInMilliSeconds = 30;

  close() {
    _streamController.close();
  }
}
