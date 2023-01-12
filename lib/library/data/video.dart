import 'package:hive/hive.dart';
import '../data/position.dart';
part 'video.g.dart';

@HiveType(typeId: 10)
class Video {
  @HiveField(0)
  String? url;
  @HiveField(1)
  String? caption;
  @HiveField(2)
  String? created;
  @HiveField(3)
  String? thumbnailUrl;
  @HiveField(4)
  String? videoId;
  @HiveField(5)
  String? projectPositionId;
  @HiveField(6)
  String? userId;
  @HiveField(7)
  String? userName;
  @HiveField(8)
  String? organizationId;
  @HiveField(9)
  Position? projectPosition;
  @HiveField(10)
  double? distanceFromProjectPosition;
  @HiveField(11)
  String? projectId;
  @HiveField(12)
  String? projectName;

  Video(
      {required this.url,
        this.caption,
        required this.projectPositionId,
        required this.created,
        required this.userId,
        required this.userName,
        required this.projectPosition,
        required this.distanceFromProjectPosition,
        required this.projectId,
        required this.thumbnailUrl,
        required this.videoId,
        required this.organizationId,
        required this.projectName}); // Video({required this.url, this.userId, required this.created});

  Video.fromJson(Map data) {
    this.url = data['url'];
    this.projectPositionId = data['projectPositionId'];
    this.caption = data['caption'];
    this.created = data['created'];
    this.userId = data['userId'];
    this.organizationId = data['organizationId'];
    this.thumbnailUrl = data['thumbnailUrl'];
    this.videoId = data['videoId'];
    this.userName = data['userName'];
    this.distanceFromProjectPosition = data['distanceFromProjectPosition'];
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
      'created': created,
      'userId': userId,
      'videoId': videoId,
      'organizationId': organizationId,
      'userName': userName,
      'thumbnailUrl': thumbnailUrl,
      'distanceFromProjectPosition': distanceFromProjectPosition,
      'projectId': projectId,
      'projectName': projectName,
      'projectPosition': projectPosition == null ? null : projectPosition!.toJson()
    };
    return map;
  }
}