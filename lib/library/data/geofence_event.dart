import 'package:hive/hive.dart';
import '../data/user.dart';

part 'geofence_event.g.dart';

@HiveType(typeId: 3)
class GeofenceEvent {
  @HiveField(0)
  String? status;

  @HiveField(1)
  String? geofenceEventId;

  @HiveField(2)
  String? date;

  @HiveField(3)
  String? projectPositionId;

  @HiveField(4)
  String? projectName;

  @HiveField(5)
  String? userId;

  @HiveField(6)
  User? user;

  GeofenceEvent(
      {required this.status,
        required this.user,
        required this.geofenceEventId,
        required this.projectPositionId,
        required this.projectName, this.userId,
        required this.date});

  GeofenceEvent.fromJson(Map data) {
    this.status = data['status'];
    this.userId = data['userId'];
    this.geofenceEventId = data['geofenceEventId'];
    this.projectPositionId = data['projectPositionId'];
    this.projectName = data['projectName'];
    this.date = data['date'];
    if (data['user'] != null) {
      this.user = User.fromJson(data['user']);
    } 
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'status': status,
      'userId': userId,
      'geofenceEventId': geofenceEventId,
      'projectPositionId': projectPositionId,
      'projectName': projectName,
      'date': date,
      'user': user == null? null : user!.toJson(),
    };
    return map;
  }
}
