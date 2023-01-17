import 'package:geo_monitor/library/data/position.dart';
import 'package:hive/hive.dart';

import 'organization.dart';
import 'project.dart';
import 'project_position.dart';
import 'user.dart';
part 'organization_registration_bag.g.dart';


@HiveType(typeId: 21)
class OrganizationRegistrationBag extends HiveObject {
  @HiveField(0)
  Organization? organization;
  @HiveField(1)
  ProjectPosition? sampleProjectPosition;
  @HiveField(2)
  List<User>? sampleUsers;
  @HiveField(3)
  String? date;
  @HiveField(4)
  Project? sampleProject;
  @HiveField(5)
  double? latitude;
  @HiveField(6)
  double? longitude;

  OrganizationRegistrationBag(
      {required this.organization,
      required this.sampleProjectPosition,
      required this.sampleUsers,
      required this.sampleProject,
      required this.date, required this.latitude, required this.longitude});

  OrganizationRegistrationBag.fromJson(Map data) {
    latitude = data['latitude'];
    longitude = data['longitude'];
    sampleUsers = [];
    if (data['sampleUsers'] != null) {
      List list = data['sampleUsers'];
      for (var element in list) {
        sampleUsers!.add(User.fromJson(element));
      }
    }

    date = data['date'];
    if (data['sampleProject'] != null) {
      sampleProject = Project.fromJson( data['sampleProject']);
    }
    if (data['sampleProjectPosition'] != null) {
      sampleProjectPosition = ProjectPosition.fromJson( data['sampleProjectPosition']);
    }
    if (data['organization'] != null) {
      organization = Organization.fromJson( data['organization']);
    }

  }
  Map<String, dynamic> toJson() {
    List mList = [];
    if (sampleUsers != null) {
      for (var value in sampleUsers!) {
        mList.add(value.toJson());
      }
    }
    Map<String, dynamic> map = {
      'organization': organization == null? null: organization!.toJson(),
      'sampleProjectPosition': sampleProjectPosition == null? null: sampleProjectPosition!.toJson(),
      'sampleUsers': mList,
      'latitude': latitude,
      'longitude': longitude,
      'date': date,
      'sampleProject': sampleProject == null? null : sampleProject!.toJson(),
    };
    return map;
  }
}
