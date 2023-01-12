import 'package:geocoding/geocoding.dart';
import 'package:hive/hive.dart';

import 'city.dart';
import '../data/position.dart';
import 'place_mark.dart';

part 'project_polygon.g.dart';

@HiveType(typeId: 19)
class ProjectPolygon {
  @HiveField(0)
  String? projectName;
  @HiveField(1)
  String? projectId;
  @HiveField(2)
  String? created;
  @HiveField(3)
  String? projectPolygonId;
  @HiveField(4)
  String? organizationId;
  @HiveField(5)
  List<Position> positions = <Position>[];

  @HiveField(6)
  List<City>? nearestCities;

  ProjectPolygon(
      {required this.projectName,
        required this.projectPolygonId,
      required this.created,
      required this.positions,
      required this.nearestCities,
        required this.organizationId,
      required this.projectId});

  ProjectPolygon.fromJson(Map data) {
    projectName = data['projectName'];
    projectId = data['projectId'];
    projectPolygonId = data['projectPolygonId'];
    projectId = data['projectId'];
    organizationId = data['organizationId'];
    created = data['created'];

    positions = [];
    if (data['positions'] != null) {
      List list = data['positions'];
      for (var value in list) {
        var position = Position.fromJson(value);
        positions.add(position);
      }
    }

    nearestCities = [];
    if (data['nearestCities'] != null) {
      List list = data['nearestCities'];
      for (var c in list) {
        nearestCities!.add(City.fromJson(c));
      }
    }
  }

  Map<String, dynamic> toJson() {
    var cityList = [];
    for (var c in nearestCities!) {
      cityList.add(c.toJson());
    }
    var positionList = [];
    for (var c in positions) {
      positionList.add(c.toJson());
    }
    Map<String, dynamic> map = {
      'projectName': projectName,
      'projectId': projectId,
      'organizationId': organizationId,
      'projectPolygonId': projectPolygonId,
      'created': created,
      'positions': positionList,
      'nearestCities': cityList,
    };
    return map;
  }
}
