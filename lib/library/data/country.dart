import 'package:hive/hive.dart';

part 'country.g.dart';

@HiveType(typeId: 1)
class Country {
  @HiveField(0)
  String? name;

  @HiveField(1)
  String? countryId;

  @HiveField(2)
  String? countryCode;

  @HiveField(3)
  int population = 0;

  Country(
      {required this.name,
        required this.population,
        required this.countryCode});

  Country.fromJson(Map data) {
    this.name = data['name'];
    this.countryId = data['countryId'];
    this.countryCode = data['countryCode'];
    if (data['population'] != null) {
      this.population = data['population'];
    } else {
      this.population = 0;
    }
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'name': name,
      'countryId': countryId,
      'countryCode': countryCode,
      'population': population == null? 0 : population,
    };
    return map;
  }
}
