import 'package:hive/hive.dart';
import '../data/position.dart';

part 'location_response.g.dart';

@HiveType(typeId: 27)
class LocationResponse extends HiveObject {
  
  @HiveField(0)
  String? date;
  @HiveField(1)
  String? userId;
  @HiveField(2)
  String? organizationId;
  @HiveField(3)
  String? userName;
  @HiveField(4)
  String? locationResponseId;
  @HiveField(5)
  String? organizationName;
  @HiveField(6)
  Position? position;
  


  LocationResponse(
      {
      required this.position,
      required this.date,
      required this.userId,
      required this.userName,
      required this.locationResponseId,
      required this.organizationId,
      required this.organizationName,
      });

  LocationResponse.fromJson(Map data) {
   
    date = data['date'];
    organizationId = data['organizationId'];
    userId = data['userId'];
    locationResponseId = data['locationResponseId'];
    userName = data['userName'];
    organizationName = data['organizationName'];
    if (data['position'] != null) {
      position = Position.fromJson(data['position']);
    }
  
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'date': date,
      'userId': userId,
      'organizationId': organizationId,
      'userName': userName,
      'locationResponseId': locationResponseId,
      'organizationName': organizationName,
      'position':
      position == null ? null : position!.toJson()
    };
    return map;
  }
}
