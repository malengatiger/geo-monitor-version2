import 'package:location/location.dart';
import 'package:maps_toolkit/maps_toolkit.dart';

import '../emojis.dart';
import '../functions.dart';

// final LocationBloc locationBloc = LocationBloc();
final LocationBlocOG locationBlocOG = LocationBlocOG();

// class LocationBloc {
//   Future<Position> getLocation() async {
//     var result = await requestPermission();
//     pp(result);
//     var pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.best);
//     pp('🔆🔆🔆 Location has been found:  💜 latitude: ${pos.latitude} longitude: ${pos.longitude}');
//     return pos;
//   }
//
//   Future<LocationPermission> checkPermission() async {
//     var perm = await Geolocator.checkPermission();
//     return perm;
//   }
//
//   Future<LocationPermission> requestPermission() async {
//     var perm = await Geolocator.requestPermission();
//     return perm;
//   }
//
//   Future<double> getDistanceFromCurrentPosition(
//       {required double latitude, required double longitude}) async {
//     var pos = await getLocation();
//
//     return Geolocator.distanceBetween(
//         latitude, longitude, pos.latitude, pos.longitude);
//   }
//
//   Future<double> getDistance(
//       {required double latitude, required double longitude, required double toLatitude, required double toLongitude}) async {
//
//     return Geolocator.distanceBetween(
//         latitude, longitude, toLatitude, toLongitude);
//   }
// }

class LocationBlocOG {
  Location location = Location();
  final mm = '🍐🍐🍐🍐🍐🍐 LocationBlocOG: ';
  bool _serviceEnabled = false;
  PermissionStatus? _permissionGranted;
  LocationData? _locationData;

  Future requestPermission() async {
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
  }

  Future<LocationData?> getLocation() async {
    await requestPermission();
    _locationData = await location.getLocation();
    pp('$mm Location acquired: $_locationData');
    return _locationData;
  }

  Future<double> getDistanceFromCurrentPosition(
      {required double latitude, required double longitude}) async {
    var pos = await getLocation();

    if (pos != null) {
      var latLngFrom = LatLng(pos!.latitude!, pos.longitude!);
      var latLngTo = LatLng(latitude, longitude);

      var distanceBetweenPoints =
          SphericalUtil.computeDistanceBetween(latLngFrom, latLngTo);
      var m = distanceBetweenPoints.toDouble();
      pp('$mm getDistanceFromCurrentPosition calculated: $m metres');
      return m;
    }
    return 0.0;
  }

  Future<double> getDistance(
      {required double latitude,
      required double longitude,
      required double toLatitude,
      required double toLongitude}) async {
    var latLngFrom = LatLng(latitude, longitude);
    var latLngTo = LatLng(toLatitude, toLongitude);

    var distanceBetweenPoints =
        SphericalUtil.computeDistanceBetween(latLngFrom, latLngTo);
    var m = distanceBetweenPoints.toDouble();
    pp('$mm getDistance between 2 points calculated: $m metres');

    return m;
  }
}
