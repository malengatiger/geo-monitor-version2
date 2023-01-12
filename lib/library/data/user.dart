import 'package:hive/hive.dart';
import '../data/position.dart';

part 'user.g.dart';

@HiveType(typeId: 11)
class User {
  @HiveField(0)
  String? name;
  @HiveField(1)
  String? userId;
  @HiveField(2)
  String? email;
  @HiveField(3)
  String? gender;
  @HiveField(4)
  String? cellphone;
  @HiveField(5)
  String? created;
  @HiveField(6)
  String? userType;
  @HiveField(7)
  String? organizationName;
  @HiveField(8)
  String? fcmRegistration;
  @HiveField(9)
  String? countryId;
  @HiveField(10)
  String? organizationId;
  @HiveField(11)
  Position? position;

  User(
      {required this.name,
      required this.email,
      required this.userId,
      required this.cellphone,
      required this.created,
      required this.userType,
      required this.gender,
      required this.organizationName,
      required this.organizationId,
      required this.countryId,
      this.position,
      this.fcmRegistration});

  User.fromJson(Map data) {
    name = data['name'];
    userId = data['userId'];
    countryId = data['countryId'];
    gender = data['gender'];
    fcmRegistration = data['fcmRegistration'];
    email = data['email'];
    cellphone = data['cellphone'];
    created = data['created'];
    userType = data['userType'];
    organizationId = data['organizationId'];
    organizationName = data['organizationName'];
    if (data['position'] != null) {
      position = Position.fromJson(data['position']);
    }
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'name': name,
      'userId': userId,
      'countryId': countryId,
      'gender': gender,
      'fcmRegistration': fcmRegistration,
      'email': email,
      'cellphone': cellphone,
      'created': created,
      'userType': userType,
      'organizationId': organizationId,
      'organizationName': organizationName,
      'position': position == null ? null : position!.toJson(),
    };
    return map;
  }
}

const FIELD_MONITOR = 'FIELD_MONITOR';
const ORG_ADMINISTRATOR = 'ORG_ADMINISTRATOR';
const ORG_EXECUTIVE = 'ORG_EXECUTIVE';
const NETWORK_ADMINISTRATOR = 'NETWORK_ADMINISTRATOR';
const ORG_OWNER = 'ORG_OWNER';

const MONITOR_ONCE_A_DAY = 'Once Every Day';
const MONITOR_TWICE_A_DAY = 'Twice A Day';
const MONITOR_THREE_A_DAY = 'Three Times A Day';
const MONITOR_ONCE_A_WEEK = 'Once A Week';

const labels = [
  'Once Every Day',
  'Twice A Day',
  'Three Times A Day',
  'Once A Week',
  'Once A Month',
  'Whenever Necessary'
];



class UserType {
  static const String fieldMonitor = 'FIELD_MONITOR';
  static const String orgAdministrator = 'ORG_ADMINISTRATOR';
  static const String orgExecutive = 'ORG_EXECUTIVE';
  static const String networkAdministrator = 'NETWORK_ADMINISTRATOR';
  static const String orgOwner = 'ORG_OWNER';
}
