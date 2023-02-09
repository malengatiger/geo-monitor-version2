
import 'package:hive/hive.dart';
part 'activity_type_enum.g.dart';

@HiveType(typeId: 61)
enum ActivityType {
  @HiveField(0)
  projectAdded,
  @HiveField(1)
  photoAdded,
  @HiveField(2)
  videoAdded,
  @HiveField(3)
  audioAdded,
  @HiveField(4)
  messageAdded,
  @HiveField(5)
  userAddedOrModified,
  @HiveField(6)
  positionAdded,
  @HiveField(7)
  polygonAdded,
  @HiveField(8)
  settingsChanged,
  @HiveField(9)
  geofenceEventAdded,
  @HiveField(10)
  conditionAdded,
  @HiveField(11)
  locationRequest,
  @HiveField(12)
  locationResponse,
  @HiveField(13)
  kill,
}
