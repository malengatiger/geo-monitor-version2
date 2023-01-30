import 'package:hive/hive.dart';

import '../data/photo.dart';
import '../data/position.dart';
import '../data/project.dart';
import '../data/video.dart';
part 'photo_for_upload.g.dart';

@HiveType(typeId: 33)
class PhotoForUpload extends HiveObject {
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


  PhotoForUpload(
      {required this.filePath,
      required this.thumbnailPath,
      this.projectPositionId,
        this.projectPolygonId,
      required this.project,
      required this.position,
      required this.date});

  PhotoForUpload.fromJson(Map data) {
    filePath = data['filePath'];
    thumbnailPath = data['thumbnailPath'];
    date = data['date'];

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
      'thumbnailPath': thumbnailPath,
      'project': project == null ? null : project!.toJson(),
      'projectPositionId': projectPositionId,
      'projectPolygonId': projectPolygonId,
      'date': date,
      'position':
          position == null ? null : position!.toJson(),
    };
    return map;
  }
}
