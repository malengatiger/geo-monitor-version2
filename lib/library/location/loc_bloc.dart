import 'package:geolocator/geolocator.dart';

import '../functions.dart';

final LocationBloc locationBloc = LocationBloc();

class LocationBloc {
  Future<Position> getLocation() async {
    var result = await requestPermission();
    pp(result);
    var pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    pp('🔆🔆🔆 Location has been found:  💜 latitude: ${pos.latitude} longitude: ${pos.longitude}');
    return pos;
  }

  Future<LocationPermission> checkPermission() async {
    var perm = await Geolocator.checkPermission();
    return perm;
  }

  Future<LocationPermission> requestPermission() async {
    var perm = await Geolocator.requestPermission();
    return perm;
  }

  Future<double> getDistanceFromCurrentPosition(
      {required double latitude, required double longitude}) async {
    var pos = await getLocation();

    return Geolocator.distanceBetween(
        latitude, longitude, pos.latitude, pos.longitude);
  }

  Future<double> getDistance(
      {required double latitude, required double longitude, required double toLatitude, required double toLongitude}) async {

    return Geolocator.distanceBetween(
        latitude, longitude, toLatitude, toLongitude);
  }
}
