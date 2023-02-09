import 'package:hive/hive.dart';
import '../data/position.dart';
import 'activity_type_enum.dart';

part 'activity_model.g.dart';

@HiveType(typeId: 60)
class ActivityModel extends HiveObject {
  @HiveField(0)
  String? activityTypeId;

  @HiveField(1)
  ActivityType? activityType;

  @HiveField(2)
  String? date;

  @HiveField(3)
  String? userId;
  @HiveField(4)
  String? userName;
  @HiveField(5)
  String? projectId;
  @HiveField(6)
  String? projectName;
  @HiveField(7)
  String? typeId;

  ActivityModel({
    required this.activityTypeId,
    required this.activityType,
    required this.date,
    required this.userId,
    required this.userName,
    required this.projectId,
    required this.projectName,
    required this.typeId,
  });

  ActivityModel.fromJson(Map data) {
    date = data['date'];
    activityTypeId = data['activityTypeId'];
    activityType = data['activityType'];
    userId = data['userId'];
    userName = data['userName'];
    projectId = data['projectId'];
    projectName = data['projectName'];
    typeId = data['typeId'];

  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'activityTypeId': activityTypeId,
      'date': date,
      'typeId': typeId,
      'userId': userId,
      'userName': userName,
      'projectId': projectId,
      'projectName': projectName,
      'activityType': activityType
    };
    return map;
  }
}
