import 'package:hive/hive.dart';
import '../data/position.dart';

part 'condition.g.dart';

@HiveType(typeId: 12)
class Condition {
  @HiveField(0)
  String? url;
  @HiveField(1)
  String? caption;
  @HiveField(2)
  String? created;
  @HiveField(3)
  String? conditionId;
  @HiveField(4)
  String? projectPositionId;
  @HiveField(5)
  String? userId;
  @HiveField(6)
  String? userName;
  @HiveField(7)
  Position? projectPosition;
  @HiveField(8)
  int? rating;
  @HiveField(9)
  String? projectId;
  @HiveField(10)
  String? projectName;

  Condition(
      {required this.url,
        this.caption,
        required this.created,
        required this.conditionId,
        required this.userId,
        required this.userName,
        required this.projectPosition,
        required this.rating,
        required this.projectPositionId,
        required this.projectId,
        required this.projectName}); // Video({required this.url, this.userId, required this.created});

  Condition.fromJson(Map data) {
    this.url = data['url'];
    this.projectPositionId = data['projectPositionId'];
    this.caption = data['caption'];
    this.created = data['created'];
    this.userId = data['userId'];
    this.conditionId = data['conditionId'];

    this.userName = data['userName'];
    this.rating = data['rating'];
    this.projectId = data['projectId'];
    this.projectName = data['projectName'];
    if (data['projectPosition'] != null) {
      this.projectPosition = Position.fromJson(data['projectPosition']);
    }
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'url': url,
      'projectPositionId': projectPositionId,
      'caption': caption,
      'conditionId': conditionId,
      'created': created,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'projectId': projectId,
      'projectName': projectName,
      'projectPosition': projectPosition == null ? null : projectPosition!.toJson()
    };
    return map;
  }
}