import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:geo_monitor/library/api/data_api.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/bloc/fcm_bloc.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../auth/app_auth.dart';
import '../cache_manager.dart';
import '../data/country.dart';
import '../data/data_bag.dart';
import '../data/project.dart';
import '../data/user.dart';
import '../emojis.dart';
import '../functions.dart';
import 'project_bloc.dart';
import 'user_bloc.dart';

DataRefresher dataRefresher = DataRefresher();

Random rand = Random(DateTime.now().millisecondsSinceEpoch);
late Directory directory;

/// Manages the uploading of media files to Cloud Storage using isolates
class DataRefresher {
  static const xx = '🌼🌼🌼🌼🌼🌼🌼🌼 DataRefresher: 🌼🌼 ';

  var numberOfDays = 30;
  var url = '';
  var token = '';
  var startDate = '';
  var endDate = '';
  User? user;

  Future<DataBag?> manageRefresh(
      {required int? numberOfDays,
      required String? organizationId,
      required String? projectId,
      required String? userId}) async {
    pp('\n\n\n$xx manageRefresh: inside Isolates: starting ... 🔵🔵🔵😡😡\n\n');
    var start = DateTime.now();
    if (numberOfDays == null) {
      var sett = await prefsOGx.getSettings();
      if (sett != null) {
        this.numberOfDays = sett.numberOfDays!;
      }
    } else {
      this.numberOfDays = numberOfDays;
    }
    directory = await getApplicationDocumentsDirectory();
    pp('$xz manageRefresh: 🔆🔆🔆 directory: ${directory.path}');
    await _setUp();
    DataBag? bag;
    try {
      bag = await _performWork(organizationId, bag, projectId, userId);
      _finish(bag, start);
    } catch (e) {
      pp('$xx Something went horribly wrong, will RETRY ...: $e');
      bag = await retry(
          numberOfDays: numberOfDays,
          organizationId: organizationId,
          projectId: projectId,
          userId: userId);
      _finish(bag, start);
    }

    pp('$xx Done with org data, refreshing projects and users if needed ...');
    final doRefresh = prefsOGx.shouldRefreshBePerformed();
    if (doRefresh) {
      var projects =
          await _startProjectsRefresh(organizationId: organizationId!);
      var users = await _startUsersRefresh(organizationId: organizationId);
      var countries = await _startCountryRefresh();
      bag!.projects = projects;
      bag.users = users;
      organizationBloc.dataBagController.sink.add(bag);
      await prefsOGx.setDateRefreshed(DateTime.now().toIso8601String());
      pp('$xx Done with refresh of projects: ${projects.length} '
          'and users: ${users.length} countries: ${countries.length}');
    }

    return bag;
  }

  DataBag? _finish(DataBag? bag, DateTime start) {
    var end = DateTime.now();
    if (bag != null) {
      pp('$xx manageRefresh: 🥬🥬🥬🥬🥬🥬 '
          'completed and data cached and sent to stream. 🥬🥬🥬 '
          '${end.difference(start).inSeconds} seconds elapsed');
    } else {
      pp('\n\n$xz Fucking bag is null! 🍎🍎🍎🍎🍎🍎');
      return DataBag(
          photos: [],
          videos: [],
          fieldMonitorSchedules: [],
          projectPositions: [],
          projects: [],
          audios: [],
          date: DateTime.now().toIso8601String(),
          users: [],
          projectPolygons: [],
          settings: []);
    }
  }

  Future<DataBag?> retry(
      {required int? numberOfDays,
      required String? organizationId,
      required String? projectId,
      required String? userId}) async {

    pp('$xx retrying the call after an error, will kick off after 5 seconds  ...');
    await Future.delayed(Duration(seconds: 5));
    DataBag? bag;
    try {
      bag = await _performWork(organizationId, bag, projectId, userId);
    } catch (e) {
      pp('$xx Something went horribly wrong on the RETRY, giving up!: $e');
    }

    return bag;
  }

  Future<DataBag?> _performWork(String? organizationId, DataBag? bag,
      String? projectId, String? userId) async {
    if (organizationId != null) {
      bag = await _startOrganizationDataRefresh(
          organizationId: organizationId, directoryPath: directory.path);
    }
    if (projectId != null) {
      bag = await _startProjectRefresh(
          projectId: projectId, directoryPath: directory.path);
    }
    if (userId != null) {
      bag = await _startUserDataRefresh(
          userId: userId, directoryPath: directory.path);
    }
    return bag;
  }

  Future _setUp() async {
    url = (await DataAPI.getUrl())!;
    token = (await AppAuth.getAuthToken())!;
    startDate =
        DateTime.now().subtract(Duration(days: numberOfDays)).toIso8601String();
    endDate = DateTime.now().toUtc().toIso8601String();
    pp('$xx 🍎🍎🍎 check dates:startDate: $startDate endDate: $endDate 🍎🍎🍎');
    user = await prefsOGx.getUser();
    if (user == null) {
      throw Exception('User is null');
    }
    _check();
  }

  Future<List<Project>> _startProjectsRefresh(
      {required String organizationId}) async {
    pp('$xx .......  _startProjectRefresh in an isolate ...');
    var list = await Isolate.run(() async => await getAllOrganizationProjects(
          token: token,
          mUrl: url,
          organizationId: organizationId,
        ));
    pp('$xz projects found: ${list.length}');
    await cacheManager.addProjects(projects: list);

    return list;
  }

  Future<List<User>> _startUsersRefresh(
      {required String organizationId}) async {
    pp('$xx .......  _startUsersRefresh in an isolate ...');
    var list = await Isolate.run(() async => await getUsers(
          token: token,
          mUrl: url,
          organizationId: organizationId,
        ));
    pp('$xz users found: ${list.length}');
    await cacheManager.addUsers(users: list);

    return list;
  }

  Future<List<Country>> _startCountryRefresh() async {
    pp('$xx .......  _startCountryRefresh in an isolate ...');
    var list = await Isolate.run(() async => await getCountries(
          token: token,
          mUrl: url,
        ));
    pp('$xz countries found: ${list.length}');
    for (var element in list) {
      await cacheManager.addCountry(country: element);
    }

    return list;
  }

  Future<DataBag?> _startOrganizationDataRefresh(
      {required String organizationId, required String directoryPath}) async {
    pp('$xx .......  startOrganizationRefresh in an isolate ...');
    DataBag? bag;
    try {
      bag = await Isolate.run(() async =>
          await refreshOrganizationDataInIsolate(
              token: token,
              directoryPath: directoryPath,
              organizationId: organizationId,
              startDate: startDate,
              endDate: endDate,
              url: url));

      pp('$xx startOrganizationRefresh: isolate function completed, dataBag delivered; '
          'will be cached and sent to streams ...');
      if (bag != null) {
        _sendOrganizationDataToStreams(bag);
        _cacheTheData(bag);
        pp('$xx startOrganizationRefresh: isolate function completed, dataBag cached.\n');
      } else {
        pp('$xx Yo! this bag be null ... someone not behaving!');
      }
      return bag;
    } on StateError catch (e) {
      pp(e.message); // In a bad state!
    } on FormatException catch (e) {
      pp(e.message);
    }
    return null;
  }

  Future<DataBag?> _startProjectRefresh(
      {required String projectId, required String directoryPath}) async {
    pp('$xx .......  startProjectRefresh in an isolate ...');
    await _setUp();
    DataBag? bag;
    try {
      bag = await Isolate.run(() async => await refreshProjectDataInIsolate(
          token: token,
          directoryPath: directoryPath,
          projectId: projectId,
          startDate: startDate,
          endDate: endDate,
          url: url));
      pp('$xx startProjectRefresh: isolate function completed, dataBag delivered; '
          'will be cached and sent to streams ...');
      if (bag != null) {
        _sendProjectDataToStreams(bag);
        _cacheTheData(bag);
        pp('$xx startProjectRefresh: isolate function completed, dataBag cached.\n');
      }
      return bag;
    } on StateError catch (e) {
      pp(e.message); // In a bad state!
    } on FormatException catch (e) {
      pp(e.message);
    }
    return bag;
  }

  Future<DataBag?> _startUserDataRefresh(
      {required String userId, required String directoryPath}) async {
    pp('$xx .......  startUserRefresh in an isolate ...');
    await _setUp();
    DataBag? bag;
    try {
      bag = await Isolate.run(() async => await refreshUserDataInIsolate(
          token: token,
          directoryPath: directoryPath,
          userId: userId,
          startDate: startDate,
          endDate: endDate,
          url: url));
      pp('$xx startUserRefresh: isolate function completed, dataBag delivered; '
          'will be cached and sent to streams ...');
      if (bag != null) {
        _sendUserDataToStreams(bag);
        _cacheTheData(bag);
        pp('$xx startUserRefresh: isolate function completed, dataBag cached.\n');
      } else {
        pp('$xx bag is null. Fuck!!');
      }
      return bag;
    } on StateError catch (e) {
      pp(e.message); // In a bad state!
    } on FormatException catch (e) {
      pp(e.message);
    }
    return bag;
  }

  void _check() {
    if (user == null) {
      throw Exception('User is null. What the FUCK!! 🍎🍎🍎🍎');
    } else {
      pp('$xx user is OK!!!! ${user!.name} - ${user!.organizationId} ');
    }
    if (url.isEmpty) {
      throw Exception('url is null. What the FUCK!! 🍎🍎🍎🍎');
    } else {
      pp('$xx url is OK!!!! $url');
    }
    if (token.isEmpty) {
      throw Exception('token is null. What the FUCK!! 🍎🍎🍎🍎');
    } else {
      pp('$xx token is OK!!!!');
    }
    if (user!.organizationId == null) {
      throw Exception('organizationId is null. What the FUCK!! 🍎🍎🍎🍎');
    } else {
      pp('$xx organizationId is OK!!!!');
    }
  }

  void _sendOrganizationDataToStreams(DataBag bag) {
    organizationBloc.dataBagController.sink.add(bag);
    pp('$xx Organization Data sent to dataBagStream  ...');
  }

  void _sendProjectDataToStreams(DataBag bag) {
    projectBloc.dataBagController.sink.add(bag);
    pp('$xx Project Data sent to dataBagStream  ...');
  }

  void _sendUserDataToStreams(DataBag bag) {
    userBloc.dataBagController.sink.add(bag);
    pp('$xx User Data sent to dataBagStream  ...');
  }

  Future<void> _cacheTheData(DataBag? bag) async {
    pp('$xx zipped Data returned from server, adding to Hive cache ...');
    final start = DateTime.now();
    await cacheManager.addProjects(projects: bag!.projects!);
    await cacheManager.addProjectPolygons(polygons: bag.projectPolygons!);
    await cacheManager.addProjectPositions(positions: bag.projectPositions!);
    await cacheManager.addUsers(users: bag.users!);
    await cacheManager.addPhotos(photos: bag.photos!);
    await cacheManager.addVideos(videos: bag.videos!);
    await cacheManager.addAudios(audios: bag.audios!);
    await cacheManager.addSettingsList(settings: bag.settings!);
    await cacheManager.addFieldMonitorSchedules(
        schedules: bag.fieldMonitorSchedules!);

    for (var element in bag.users!) {
      if (element.userId == user!.userId) {
        await prefsOGx.saveUser(element);
        fcmBloc.userController.sink.add(element);
      }
    }
    final end = DateTime.now();

    pp('$xx Org Data saved in Hive cache ... 🍎 '
        '${end.difference(start).inSeconds} seconds elapsed');
  }
}

//
//
//
/// Isolate functions to get organization data from the cloud...
Future<DataBag?> refreshOrganizationDataInIsolate(
    {required String token,
    required String organizationId,
    required String startDate,
    required String endDate,
    required String url,
    required String directoryPath}) async {
  pp('$xz ............ refreshOrganizationDataInIsolate starting ....');
  DataBag? bag;
  try {
    bag = await getOrganizationDataZippedFile(
        url: url,
        directoryPath: directoryPath,
        organizationId: organizationId,
        startDate: startDate,
        endDate: endDate,
        token: token);
    if (bag == null) {
      pp('$xz Bag not returned from getOrganizationDataZippedFile ');
      throw Exception('$xz Hey Ho, no bag!');
    }
  } catch (e) {
    pp(e);
  }

  return bag;
}

Future<DataBag?> refreshProjectDataInIsolate(
    {required String token,
    required String projectId,
    required String startDate,
    required String endDate,
    required String url,
    required String directoryPath}) async {
  pp('$xz refreshProjectDataInIsolate starting ....');
  DataBag? bag;
  try {
    bag = await getProjectDataZippedFile(
        url: url,
        directoryPath: directoryPath,
        projectId: projectId,
        startDate: startDate,
        endDate: endDate,
        token: token);
  } catch (e) {
    pp(e);
  }

  return bag;
}

Future<DataBag?> refreshUserDataInIsolate(
    {required String token,
    required String userId,
    required String startDate,
    required String endDate,
    required String url,
    required String directoryPath}) async {
  pp('$xz refreshUserDataInIsolate starting ....');
  DataBag? bag;
  try {
    bag = await getUserDataZippedFile(
        url: url,
        directoryPath: directoryPath,
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        token: token);
  } catch (e) {
    pp(e);
  }

  return bag;
}

Future<DataBag?> getOrganizationDataZippedFile(
    {required String organizationId,
    required String startDate,
    required String endDate,
    required String token,
    required String url,
    required String directoryPath}) async {
  pp('$xz getOrganizationDataZippedFile  🔆🔆🔆 organizationId : 💙  $organizationId  💙');
  var start = DateTime.now();
  var mUrl =
      '${url}getOrganizationDataZippedFile?organizationId=$organizationId&startDate=$startDate&endDate=$endDate';

  var bag =
      await _getDataBag(mUrl: mUrl, token: token, directoryPath: directoryPath);
  if (bag == null) {
    pp('$xz This is a problem, Boss! - null bag!');
  }
  var end = DateTime.now();
  pp('$xz getOrganizationDataZippedFile: ${end.difference(start).inSeconds} seconds elapsed');
  return bag;
}

Future<DataBag?> getProjectDataZippedFile({
  required String projectId,
  required String startDate,
  required String endDate,
  required String token,
  required String url,
  required String directoryPath,
}) async {
  pp('$xz getProjectDataZippedFile  🔆🔆🔆 projectId : 💙  $projectId  💙');
  final start = DateTime.now();
  ;
  var mUrl =
      '${url}getProjectDataZippedFile?projectId=$projectId&startDate=$startDate&endDate=$endDate';

  var bag =
      await _getDataBag(mUrl: mUrl, token: token, directoryPath: directoryPath);
  final end = DateTime.now();
  pp('$xz getProjectDataZippedFile: ${end.difference(start).inSeconds} seconds elapsed');

  return bag;
}

Future<DataBag?> getUserDataZippedFile(
    {required String userId,
    required String startDate,
    required String endDate,
    required String token,
    required String url,
    required String directoryPath}) async {
  pp('$xz getUserDataZippedFile  🔆🔆🔆 orgId : 💙  $userId  💙');
  final start = DateTime.now();
  var mUrl =
      '${url}getUserDataZippedFile?userId=$userId&startDate=$startDate&endDate=$endDate';

  var bag =
      await _getDataBag(mUrl: mUrl, token: token, directoryPath: directoryPath);
  var end = DateTime.now();
  pp('$xz getUserDataZippedFile: ${end.difference(start).inSeconds} seconds elapsed');

  return bag;
}

Future<List<Project>> getAllOrganizationProjects(
    {required String organizationId,
    required String mUrl,
    required String token}) async {
  final client = http.Client();
  var start = DateTime.now();

  var list = <Project>[];
  Map<String, String> headers = {
    'Content-type': 'application/json',
    'Accept': '*/*',
    'Content-Encoding': 'application/json',
    'Authorization': 'Bearer $token'
  };
  try {
    mUrl = '${mUrl}getAllOrganizationProjects?organizationId=$organizationId';
    var uri = Uri.parse(mUrl);

    http.Response httpResponse = await client
        .get(
          uri,
          headers: headers,
        )
        .timeout(const Duration(seconds: 120));
    pp('$xz getAllOrganizationProjects: RESPONSE: .... : 💙 statusCode: 👌👌👌 '
        '${httpResponse.statusCode} 👌👌👌  for $mUrl');
    var end = DateTime.now();
    pp('$xz getAllOrganizationProjects: elapsed time: ${end.difference(start).inSeconds} seconds');
    if (httpResponse.statusCode == 200) {
      List mList = jsonDecode(httpResponse.body);
      for (var value in mList) {
        list.add(Project.fromJson(value));
      }
      return list;
    } else {
      pp('$xz Bad status; ${httpResponse.statusCode} ${httpResponse.body}');
      return [];
    }
  } catch (e) {
    pp('$xz Problem getting projects: $e');
  }

  return [];
}

Future<List<User>> getUsers(
    {required String organizationId,
    required String mUrl,
    required String token}) async {
  final client = http.Client();
  var start = DateTime.now();

  var list = <User>[];
  Map<String, String> headers = {
    'Content-type': 'application/json',
    'Accept': '*/*',
    'Content-Encoding': 'application/json',
    'Authorization': 'Bearer $token'
  };
  try {
    mUrl = '${mUrl}getAllOrganizationUsers?organizationId=$organizationId';
    var uri = Uri.parse(mUrl);

    http.Response httpResponse = await client
        .get(
          uri,
          headers: headers,
        )
        .timeout(const Duration(seconds: 120));
    pp('$xz getUsers: RESPONSE: .... : 💙 statusCode: 👌👌👌 '
        '${httpResponse.statusCode} 👌👌👌  for $mUrl');
    var end = DateTime.now();
    pp('$xz getUsers: elapsed time: ${end.difference(start).inSeconds} seconds');
    if (httpResponse.statusCode == 200) {
      List mList = jsonDecode(httpResponse.body);
      for (var value in mList) {
        list.add(User.fromJson(value));
      }
      return list;
    } else {
      pp('$xz getUsers: Bad status; ${httpResponse.statusCode} ${httpResponse.body}');
      return [];
    }
  } catch (e) {
    pp('$xz Problem getting users: $e');
  }

  return [];
}

Future<List<Country>> getCountries(
    {required String mUrl, required String token}) async {
  final client = http.Client();
  var start = DateTime.now();

  var list = <Country>[];
  Map<String, String> headers = {
    'Content-type': 'application/json',
    'Accept': '*/*',
    'Content-Encoding': 'application/json',
    'Authorization': 'Bearer $token'
  };
  try {
    mUrl = '${mUrl}getCountries';
    var uri = Uri.parse(mUrl);

    http.Response httpResponse = await client
        .get(
          uri,
          headers: headers,
        )
        .timeout(const Duration(seconds: 120));
    pp('$xz getCountries: RESPONSE: .... : 💙 statusCode: 👌👌👌 '
        '${httpResponse.statusCode} 👌👌👌  for $mUrl');
    var end = DateTime.now();
    pp('$xz getCountries: elapsed time: ${end.difference(start).inSeconds} seconds');
    if (httpResponse.statusCode == 200) {
      List mList = jsonDecode(httpResponse.body);
      for (var value in mList) {
        list.add(Country.fromJson(value));
      }
      return list;
    } else {
      pp('$xz getCountries: Bad status; ${httpResponse.statusCode} ${httpResponse.body}');
      return [];
    }
  } catch (e) {
    pp('$xz Problem getting countries: $e');
  }

  return [];
}

Future<DataBag?> _getDataBag(
    {required String mUrl,
    required String token,
    required String directoryPath}) async {
  pp('$xz _getDataBag: 🔆🔆🔆 get zipped data ...');

  DataBag? dataBag;
  try {
    http.Response response = await _sendRequestToBackend(mUrl, token);
    pp('$xz _getDataBag: 🔆🔆🔆 get zipped data, response: ${response.contentLength} bytes ...');

    File zipFile =
        File('$directoryPath/zip${DateTime.now().millisecondsSinceEpoch}.zip');
    zipFile.writeAsBytesSync(response.bodyBytes);

    pp('$xz _getDataBag: 🔆🔆🔆 handle file inside zip: ${await zipFile.length()}');

    //create zip archive
    final inputStream = InputFileStream(zipFile.path);
    final archive = ZipDecoder().decodeBuffer(inputStream);

    pp('$xz _getDataBag: 🔆🔆🔆 handle file inside zip archive');
    for (var file in archive.files) {
      if (file.isFile) {
        var fileName = '$directoryPath/${file.name}';
        pp('$xz _getDataBag: file from inside archive ... ${file.size} bytes 🔵 isCompressed: ${file.isCompressed} 🔵 zipped file name: ${file.name}');
        var outFile = File(fileName);
        outFile = await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content);
        pp('$xz _getDataBag: file after decompress ... ${await outFile.length()} bytes  🍎 path: ${outFile.path} 🍎');

        if (outFile.existsSync()) {
          pp('$xz decompressed file exists and has length of 🍎 ${await outFile.length()} bytes');
          var m = outFile.readAsStringSync(encoding: utf8);
          var mJson = json.decode(m);
          dataBag = DataBag.fromJson(mJson);
          _printDataBag(dataBag);
          var end = DateTime.now().millisecondsSinceEpoch;
          var ms = (end - start) / 1000;
          pp('$xz getOrganizationDataZippedFile 🍎🍎🍎🍎 work is done!, elapsed seconds: $ms\n\n');
        } else {
          pp('$xz ERROR: could not find file');
        }
      }
    }
    if (dataBag == null) {
      pp('$xz _getDataBag: dataBag is null');
      throw 'Bad Bag!! why null?';
    }
    return dataBag;
  } catch (e) {
    pp('$xz What the fuck is wrong? $e');
    throw 'This is not acceptable';
  }
}

final client = http.Client();
int start = 0;

Future<http.Response> _sendRequestToBackend(String mUrl, String token) async {
  pp('$xz _sendRequestToBackend call:  🔆 🔆 🔆 calling : 💙  $mUrl  💙');
  var start = DateTime.now();

  Map<String, String> headers = {
    'Content-type': 'application/json',
    'Accept': '*/*',
    'Content-Encoding': 'gzip',
    'Accept-Encoding': 'gzip, deflate',
    'Authorization': 'Bearer $token'
  };

  try {
    pp('$xz _sendRequestToBackend call:  🔆 🔆 🔆 '
        'just about to call http client ....');
    try {
      final client = http.Client();
      var uri = Uri.parse(mUrl);

      http.Response httpResponse = await client
          .get(
            uri,
            headers: headers,
          )
          .timeout(const Duration(seconds: 120));
      pp('$xz _sendRequestToBackend: RESPONSE: .... : 💙 statusCode: 👌👌👌 '
          '${httpResponse.statusCode} 👌👌👌  for $mUrl');
      var end = DateTime.now();
      pp('$xz _sendRequestToBackend: RESPONSE: 🔆 elapsed time for backend http request: '
          '${end.difference(start).inSeconds} seconds 🔆');

      if (httpResponse.statusCode != 200) {
        var msg =
            '$xz 😡😡😡😡 The response is not 200; it is ${httpResponse.statusCode}, '
            'NOT GOOD, throwing up !! 😡 ${httpResponse.body}';
        pp(msg);
        throw HttpException(msg);
      } else {
        pp('$xz status is 200,  🍎 Return the httpResponse: ${httpResponse.contentLength} bytes  🍎');
      }
      return httpResponse;
    } catch (e) {
      pp('$xz Problem with http call: $e');
      throw Exception('$e');
    }
  } on SocketException {
    pp('\n\n$xz SocketException: ${E.redDot}${E.redDot}${E.redDot} '
        'No Internet connection, really means that server cannot be reached; 😑'
        ' ${E.redDot} this looks like a fuck up of some kind!!');
    throw 'GeoMonitor server cannot be reached at this time. Please try again!';
  } on HttpException {
    pp("$xz HttpException occurred 😱");
    throw 'HttpException';
  } on FormatException {
    pp("$xz Bad response format 👎");
    throw 'Bad response format';
  } on TimeoutException {
    pp("$xz GET Request has timed out in 120 seconds 👎");
    throw 'Request has timed out in 120 seconds';
  }
}

void _printDataBag(DataBag bag) {
  final projects = bag.projects!.length;
  final users = bag.users!.length;
  final positions = bag.projectPositions!.length;
  final polygons = bag.projectPolygons!.length;
  final photos = bag.photos!.length;
  final videos = bag.videos!.length;
  final audios = bag.audios!.length;
  final schedules = bag.fieldMonitorSchedules!.length;

  pp('\n\n$xz _printDataBag: all org data extracted from zipped file on: 🔵🔵🔵${bag.date}');
  pp('$xz projects: $projects');
  pp('$xz users: $users');
  pp('$xz positions: $positions');
  pp('$xz polygons: $polygons');
  pp('$xz photos: $photos');
  pp('$xz videos: $videos');
  pp('$xz audios: $audios');
  pp('$xz schedules: $schedules');
  pp('$xz data from backend listed above: 🔵🔵🔵 ${bag.date}');
}

const xz = '🦀🦀🦀🦀🦀 Refresher Isolate ';

onError() {
  pp('http threw onError');
  throw Exception('dunno!');
}
