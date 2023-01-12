import 'package:hive/hive.dart';


part 'position.g.dart';

@HiveType(typeId: 16)
class Position {

  @HiveField(0)
  String? type = 'Point';
  @HiveField(1)
  List coordinates = [];
  Position({
    required this.coordinates,
    required this.type,
  });

  Position.fromJson(Map data) {
    this.coordinates = data['coordinates'];
    this.type = data['type'];
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'type': type,
      'coordinates': coordinates,
    };
    return map;
  }
}
