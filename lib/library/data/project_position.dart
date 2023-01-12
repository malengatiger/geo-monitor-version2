import 'package:geocoding/geocoding.dart';
import 'package:hive/hive.dart';

import 'city.dart';
import '../data/position.dart';
import 'place_mark.dart';

part 'project_position.g.dart';

@HiveType(typeId: 6)
class ProjectPosition {
  @HiveField(0)
  String? projectName;
  @HiveField(1)
  String? projectId;
  @HiveField(2)
  String? caption;
  @HiveField(3)
  String? created;
  @HiveField(4)
  String? projectPositionId;
  @HiveField(5)
  String? organizationId;
  @HiveField(6)
  Position? position;
  @HiveField(7)
  PlaceMark? placemark;
  @HiveField(8)
  List<City>? nearestCities;

  ProjectPosition(
      {required this.projectName,
      required this.caption,
        required this.projectPositionId,
      required this.created,
      required this.position,
      this.placemark,
      required this.nearestCities,
        required this.organizationId,
      required this.projectId});

  ProjectPosition.fromJson(Map data) {
    //pp(' 💜 ProjectPosition.fromJson: log 0');
    projectName = data['projectName'];
    //pp(' 💜 ProjectPosition.fromJson: log 1');
    projectId = data['projectId'];
    projectPositionId = data['projectPositionId'];
    //pp(' 💜 ProjectPosition.fromJson: log 2');
    caption = data['caption'];
    projectId = data['projectId'];
    organizationId = data['organizationId'];
    created = data['created'];
    //pp(' 💜 ProjectPosition.fromJson: log 3');

    if (data['position'] != null) {
      position = Position.fromJson(data['position']);
    }
    //pp(' 💜 ProjectPosition.fromJson: log 4');
    if (data['placemark'] != null) {
      placemark = PlaceMark.fromJson(data['placemark']);
    }
    //pp(' 💜 ProjectPosition.fromJson: log 5');
    nearestCities = [];
    if (data['nearestCities'] != null) {
      List list = data['nearestCities'];
      for (var c in list) {
        nearestCities!.add(City.fromJson(c));
      }
    }
    //pp(' 💜 ProjectPosition.fromJson: log end');
  }

  Map<String, dynamic> toJson() {
    var list = [];
    for (var c in nearestCities!) {
      list.add(c.toJson());
    }
    Map<String, dynamic> map = {
      'projectName': projectName,
      'projectId': projectId,
      'organizationId': organizationId,
      'projectPositionId': projectPositionId,
      'caption': caption,
      'created': created,
      'position': position == null ? null : position!.toJson(),
      'placemark': placemark == null ? null : placemark!.toJson(),
      'nearestCities': list,
    };
    return map;
  }
}
