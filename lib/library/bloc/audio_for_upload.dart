import 'package:hive/hive.dart';

import '../data/position.dart';
import '../data/project.dart';
part 'audio_for_upload.g.dart';

@HiveType(typeId: 35)
class AudioForUpload extends HiveObject {
  @HiveField(0)
  String? filePath;

  @HiveField(2)
  Project? project;

  @HiveField(5)
  Position? position;
  @HiveField(6)
  String? date;


  AudioForUpload(
      {required this.filePath,
      required this.project,
      required this.position,
      required this.date});

  AudioForUpload.fromJson(Map data) {
    filePath = data['filePath'];
    date = data['date'];

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
      'project': project == null ? null : project!.toJson(),
      'date': date,
      'position':
          position == null ? null : position!.toJson(),
    };
    return map;
  }
}
