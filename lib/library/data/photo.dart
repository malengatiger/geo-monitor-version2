import 'package:hive/hive.dart';
import '../data/position.dart';
import '../functions.dart';

part 'photo.g.dart';

@HiveType(typeId: 4)
class Photo {
  @HiveField(0)
  String? url;
  @HiveField(1)
  String? thumbnailUrl;
  @HiveField(2)
  String? caption;
  @HiveField(3)
  String? created;
  @HiveField(4)
  String? photoId;
  @HiveField(5)
  String? projectPositionId;
  @HiveField(6)
  String? userId;
  @HiveField(7)
  String? organizationId;
  @HiveField(8)
  String? userName;
  @HiveField(9)
  Position? projectPosition;
  @HiveField(10)
  double? distanceFromProjectPosition;
  @HiveField(11)
  String? projectId;
  @HiveField(12)
  String? projectName;
  @HiveField(13)
  int? height;
  @HiveField(14)
  int? width;

  @HiveField(15)
  int? landscape;

  Photo(
      {required this.url,
      required this.caption,
      required this.created,
      required this.userId,
      required this.userName,
      required this.projectPosition,
      required this.distanceFromProjectPosition,
      required this.projectId,
      required this.thumbnailUrl,
      required this.photoId,
      required this.organizationId,
      required this.projectName,
      required this.height,
      required this.projectPositionId,
      required this.width,
      required this.landscape});

  Photo.fromJson(Map data) {
    // pp('😡 😡 😡😡 😡 😡😡 😡 😡');
    // prettyPrint(data, "Photo from json");
    projectPositionId = data['projectPositionId'];
    url = data['url'];
    thumbnailUrl = data['thumbnailUrl'];
    caption = data['caption'];
    height = data['height'];
    width = data['width'];
    created = data['created'];
    organizationId = data['organizationId'];
    landscape = data['landscape'];

    userId = data['userId'];
    photoId = data['photoId'];
    userName = data['userName'];
    distanceFromProjectPosition = data['distanceFromProjectPosition'];
    projectId = data['projectId'];
    projectName = data['projectName'];
    if (data['projectPosition'] != null) {
      projectPosition = Position.fromJson(data['projectPosition']);
    }
    height ??= -5;
    width ??= -10;
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'url': url,
      'landscape': landscape,
      'projectPositionId': projectPositionId,
      'caption': caption,
      'created': created,
      'width': width,
      'height': height,
      'userId': userId,
      'organizationId': organizationId,
      'photoId': photoId,
      'userName': userName,
      'distanceFromProjectPosition': distanceFromProjectPosition,
      'projectId': projectId,
      'projectName': projectName,
      'thumbnailUrl': thumbnailUrl,
      'projectPosition':
          projectPosition == null ? null : projectPosition!.toJson()
    };
    return map;
  }
}
