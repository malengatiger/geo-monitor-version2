import 'package:hive/hive.dart';

import '../data/position.dart';
import '../data/project.dart';

part 'video_for_upload.g.dart';

@HiveType(typeId: 34)
class VideoForUpload extends HiveObject {
  @HiveField(0)
  String? filePath;
  @HiveField(1)
  String? thumbnailPath;
  @HiveField(2)
  Project? project;
  @HiveField(3)
  String? projectPositionId;
  @HiveField(4)
  String? projectPolygonId;
  @HiveField(5)
  Position? position;
  @HiveField(6)
  String? date;
  @HiveField(7)
  String? videoId;
  @HiveField(8)
  int? durationInSeconds;

  @HiveField(9)
  double? height;
  @HiveField(10)
  double? width;

  VideoForUpload(
      {required this.filePath,
      required this.videoId,
      required this.thumbnailPath,
      this.projectPositionId,
      this.projectPolygonId,
      required this.project,
      required this.position,
      required this.durationInSeconds,
      required this.height,
      required this.width,
      required this.date});

  VideoForUpload.fromJson(Map data) {
    videoId = data['videoId'];
    filePath = data['filePath'];
    thumbnailPath = data['thumbnailPath'];
    durationInSeconds = data['durationInSeconds'];
    date = data['date'];
    height = data['height'];
    width = data['width'];

    projectPolygonId = data['projectPolygonId'];
    projectPositionId = data['projectPositionId'];

    if (data['project'] != null) {
      project = Project.fromJson(data['project']);
    }

    if (data['position'] != null) {
      position = Position.fromJson(data['position']);
    }
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'filePath': filePath,
      'videoId': videoId,
      'height': height,
      'width': width,
      'durationInSeconds': durationInSeconds,
      'thumbnailPath': thumbnailPath,
      'project': project == null ? null : project!.toJson(),
      'projectPositionId': projectPositionId,
      'projectPolygonId': projectPolygonId,
      'date': date,
      'position': position == null ? null : position!.toJson(),
    };
    return map;
  }
}
