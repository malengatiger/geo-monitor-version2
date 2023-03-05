import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 30)
class SettingsModel {
  @HiveField(0)
  int? distanceFromProject;
  @HiveField(1)
  int? photoSize;
  @HiveField(2)
  int? maxVideoLengthInSeconds;
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
  @HiveField(9)
  int? activityStreamHours;

  SettingsModel(
      {required this.distanceFromProject,
      required this.photoSize,
      required this.maxVideoLengthInSeconds,
      required this.maxAudioLengthInMinutes,
      required this.themeIndex,
      required this.settingsId,
      required this.created,
      required this.organizationId,
      required this.projectId,
      required this.activityStreamHours});

  SettingsModel.fromJson(Map data) {
    // pp('🌀🌀🌀🌀 data json from server $data');
    distanceFromProject = data['distanceFromProject'];
    photoSize = data['photoSize'];
    settingsId = data['settingsId'];
    created = data['created'];
    activityStreamHours = data['activityStreamHours'];
    organizationId = data['organizationId'];

    if (data['projectId'] != null) {
      projectId = data['projectId'];
    }

    themeIndex = 0;
    if (data['themeIndex'] != null) {
      themeIndex = data['themeIndex'];
    }
    if (data['maxVideoLengthInSeconds'] == null) {
      maxVideoLengthInSeconds = 15;
    } else {
      maxVideoLengthInSeconds = data['maxVideoLengthInSeconds'];
    }
    maxAudioLengthInMinutes = data['maxAudioLengthInMinutes'];
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'distanceFromProject': distanceFromProject,
      'photoSize': photoSize,
      'projectId': projectId,
      'organizationId': organizationId,
      'created': created,
      'activityStreamHours': activityStreamHours,
      'settingsId': settingsId,
      'themeIndex': themeIndex,
      'maxVideoLengthInSeconds': maxVideoLengthInSeconds,
      'maxAudioLengthInMinutes': maxAudioLengthInMinutes,
    };
    return map;
  }
}
