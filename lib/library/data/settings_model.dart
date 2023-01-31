import 'package:hive/hive.dart';


part 'settings_model.g.dart';

@HiveType(typeId: 30)
class SettingsModel {
  @HiveField(0)
  int? distanceFromProject;
  @HiveField(1)
  int? photoSize;
  @HiveField(2)
  int? maxVideoLengthInMinutes;
  @HiveField(3)
  int? maxAudioLengthInMinutes;
  @HiveField(4)
  int? themeIndex;
  @HiveField(5)
  String? settingsId;
  @HiveField(6)
  String? created;
  @HiveField(7)
  String? organizationId;
  @HiveField(8)
  String? projectId;

  SettingsModel(
      {required this.distanceFromProject,
        required this.photoSize,
        required this.maxVideoLengthInMinutes,
        required this.maxAudioLengthInMinutes,
        required this.themeIndex,
        required this.settingsId,
        required this.created,
        required this.organizationId,
        required this.projectId});

  SettingsModel.fromJson(Map data) {
    // pp('🌀🌀🌀🌀 data json from server $data');
    distanceFromProject = data['distanceFromProject'];
    photoSize = data['photoSize'];
    settingsId = data['settingsId'];
    created = data['created'];
    organizationId = data['organizationId'];

    if (data['projectId'] != null) {
      projectId = data['projectId'];
    }

    themeIndex = 0;
    if (data['themeIndex'] != null) {
      themeIndex = data['themeIndex'];
    }
    maxVideoLengthInMinutes = data['maxVideoLengthInMinutes'];
    maxAudioLengthInMinutes = data['maxAudioLengthInMinutes'];
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'distanceFromProject': distanceFromProject,
      'photoSize': photoSize,
      'projectId': projectId,
      'organizationId': organizationId,
      'created': created,
      'settingsId': settingsId,
      'themeIndex': themeIndex,
      'maxVideoLengthInMinutes': maxVideoLengthInMinutes,
      'maxAudioLengthInMinutes': maxAudioLengthInMinutes,
    };
    return map;
  }
}
