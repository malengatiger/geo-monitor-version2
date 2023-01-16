import 'package:geo_monitor/library/data/position.dart';
import 'package:hive/hive.dart';

import '../data/project.dart';
import '../data/project_position.dart';
part 'failed_bag.g.dart';

@HiveType(typeId: 20)
class FailedBag extends HiveObject {
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
  bool? isLandscape;
  @HiveField(6)
  Position? projectPosition;
  @HiveField(7)
  bool? isVideo;
  @HiveField(8)
  String? date;

  FailedBag(
      {required this.filePath,
      required this.thumbnailPath,
      this.projectPositionId,
      required this.project,
      required this.projectPosition,
      required this.isLandscape,
      this.projectPolygonId,
      required this.isVideo, required this.date});

  FailedBag.fromJson(Map data) {
    filePath = data['filePath'];
    thumbnailPath = data['thumbnailPath'];
    date = data['date'];
    isLandscape = data['isLandscape'];
    isVideo = data['isVideo'];

    projectPolygonId = data['projectPolygonId'];
    projectPositionId = data['projectPositionId'];

    if (data['project'] != null) {
      project = Project.fromJson(data['project']);
    }
    if (data['projectPosition'] != null) {
      projectPosition = Position.fromJson(data['projectPosition']);
    }
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'filePath': filePath,
      'thumbnailPath': thumbnailPath,
      'project': project == null ? null : project!.toJson(),
      'projectPositionId': projectPositionId,
      'projectPolygonId': projectPolygonId,
      'isLandscape': isLandscape,
      'isVideo': isVideo,
      'date': date,
      'projectPosition':
          projectPosition == null ? null : projectPosition!.toJson(),
    };
    return map;
  }
}
