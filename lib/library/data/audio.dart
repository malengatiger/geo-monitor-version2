import 'package:hive/hive.dart';
import '../data/position.dart';
part 'audio.g.dart';

@HiveType(typeId: 23)
class Audio extends HiveObject {
  @HiveField(0)
  String? url;
  @HiveField(1)
  String? caption;
  @HiveField(2)
  String? created;
  @HiveField(3)
  String? audioId;
  @HiveField(4)
  String? projectPositionId;
  @HiveField(5)
  String? userId;
  @HiveField(6)
  String? userName;
  @HiveField(7)
  String? organizationId;
  @HiveField(8)
  Position? projectPosition;
  @HiveField(9)
  double? distanceFromProjectPosition;
  @HiveField(10)
  String? projectId;
  @HiveField(11)
  String? projectName;
  @HiveField(12)
  String? projectPolygonId;
  @HiveField(13)
  int? durationInSeconds = 0;

  Audio(
      {required this.url,
        this.caption,
        this.projectPositionId,
        this.projectPolygonId,
        required this.created,
        required this.userId,
        required this.userName,
        required this.projectPosition,
        required this.distanceFromProjectPosition,
        required this.projectId,
        required this.audioId,
        required this.durationInSeconds,
        required this.organizationId,
        required this.projectName}); // Audio({required this.url, this.userId, required this.created});

  Audio.fromJson(Map data) {
    url = data['url'];
    projectPositionId = data['projectPositionId'];
    projectPolygonId = data['projectPolygonId'];
    caption = data['caption'];
    durationInSeconds = data['durationInSeconds'];

    created = data['created'];
    userId = data['userId'];
    organizationId = data['organizationId'];
    audioId = data['audioId'];
    userName = data['userName'];
    distanceFromProjectPosition = data['distanceFromProjectPosition'];
    projectId = data['projectId'];
    projectName = data['projectName'];
    if (data['projectPosition'] != null) {
      projectPosition = Position.fromJson(data['projectPosition']);
    }
    durationInSeconds = 0;
    if (data['durationInSeconds'] != null) {
      durationInSeconds = data['projectPosition'];
    }
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'url': url,
      'projectPositionId': projectPositionId,
      'projectPolygonId': projectPolygonId,
      'caption': caption,
      'created': created,
      'durationInSeconds': durationInSeconds,
      'userId': userId,
      'audioId': audioId,
      'organizationId': organizationId,
      'userName': userName,
      'distanceFromProjectPosition': distanceFromProjectPosition,
      'projectId': projectId,
      'projectName': projectName,
      'projectPosition': projectPosition == null ? null : projectPosition!.toJson()
    };
    return map;
  }
}