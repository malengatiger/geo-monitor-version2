import 'package:hive/hive.dart';
import '../data/position.dart';
part 'location_request.g.dart';
/*
private String organizationId, created, administratorId, response;
 */
@HiveType(typeId: 23)
class LocationRequest extends HiveObject {
  @HiveField(0)
  String? organizationId;
  @HiveField(1)
  String? administratorId;
  @HiveField(2)
  String? created;
  @HiveField(3)
  String? response;
 
  LocationRequest(
      {required this.organizationId,
        this.administratorId,
        required this.created,
        required this.response,}); // LocationRequest({required this.organizationId, this.userId, required this.created});

  LocationRequest.fromJson(Map data) {
    // pp(data);
    organizationId = data['organizationId'];
    administratorId = data['administratorId'];
    created = data['created'];
    response = data['response'];

  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'organizationId': organizationId,
      'administratorId': administratorId,
      'created': created,
      'response': response,

    };
    return map;
  }
}