import 'package:hive/hive.dart';

part 'location_request.g.dart';

@HiveType(typeId: 23)
class LocationRequest extends HiveObject {
  @HiveField(0)
  String? organizationId;
  @HiveField(1)
  String? requesterId;
  @HiveField(2)
  String? created;
  @HiveField(3)
  String? requesterName;
  @HiveField(4)
  String? userId;
  @HiveField(5)
  String? userName;
  @HiveField(6)
  String? organizationName;

  //private String , , , ;
  //     private String , userName, organizationName;

  LocationRequest(
      {required this.organizationId,
      this.requesterId,
      required this.created,
      required this.requesterName,
      required this.userName,
      required this.userId,
      required this.organizationName}); // LocationRequest({required this.organizationId, this.userId, required this.created});

  LocationRequest.fromJson(Map data) {
    // pp(data);
    organizationId = data['organizationId'];
    requesterId = data['requesterId'];

    userId = data['userId'];
    userName = data['userName'];
    organizationName = data['organizationName'];
    created = data['created'];
    requesterName = data['requesterName'];
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'organizationId': organizationId,
      'requesterId': requesterId,
      'created': created,
      'requesterName': requesterName,
    };
    return map;
  }
}
