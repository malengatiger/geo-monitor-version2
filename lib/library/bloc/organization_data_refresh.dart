import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:geo_monitor/library/api/data_api.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/bloc/fcm_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../auth/app_auth.dart';
import '../cache_manager.dart';
import '../data/data_bag.dart';
import '../data/user.dart';
import '../emojis.dart';
import '../functions.dart';

OrganizationDataRefresh organizationDataRefresh = OrganizationDataRefresh();

Random rand = Random(DateTime.now().millisecondsSinceEpoch);


/// Manages the uploading of media files to Cloud Storage using isolates
class OrganizationDataRefresh {
  static const xx = '🌼🌼🌼🌼🌼🌼🌼🌼 OrganizationDataRefresh: 🌼🌼 ';

  Future manageRefresh(int dashboardDays) async {
    pp('\n\n\n$xx manageRefresh: starting ... 🔵🔵🔵😡😡\n\n');

    try {
      await startRefresh(dashboardDays);
      pp('\n\n$xx manageMediaUploads: 🥬🥬🥬🥬🥬🥬 '
          'completed and uploads done if needed. 🥬🥬🥬 '
          'should be Okey Dokey!\n');
    } catch (e) {
      pp('$xx Something went horribly wrong: $e');
      throw Exception('Upload Exception: $e');
    }
  }

  Future<DataBag?> startRefresh(int dashboardDays) async {
    pp('$xx startRefresh in an isolate ...');

    var url = await DataAPI.getUrl();
    var token = await AppAuth.getAuthToken();

    var sDate = DateTime.now()
        .subtract( Duration(days: dashboardDays)).toIso8601String();
    var eDate = DateTime.now().toUtc().toIso8601String();

    pp('$xx 🍎🍎🍎 check dates:startDate: $sDate endDate: $eDate 🍎🍎🍎');

    User? user;
    try {
      user = await prefsOGx.getUser();
      if (user == null) {
        throw Exception('User is null. What the FUCK!! 🍎🍎🍎🍎');
      } else {
        pp('$xx user is OK!!!! ${user!.name} - ${user!.organizationId} ');
      }
      if (url == null) {
        throw Exception('url is null. What the FUCK!! 🍎🍎🍎🍎');
      } else {
        pp('$xx url is OK!!!! $url');
      }
      if (token == null) {
        throw Exception('token is null. What the FUCK!! 🍎🍎🍎🍎');
      } else {
        pp('$xx token is OK!!!!');
      }
      if (user!.organizationId == null) {
        throw Exception('organizationId is null. What the FUCK!! 🍎🍎🍎🍎');
      } else {
        pp('$xx organizationId is OK!!!!');
      }
      var orgId = user!.organizationId!;
      var bag = await Isolate.run(() async => await refreshDataInIsolate(
          organizationId: orgId,
          startDate: sDate,
          endDate: eDate,
          token: token,
          url: url));

      pp('$xx isolate function completed, dataBag delivered; will be cached');
      if (bag != null) {
        _cacheTheData(bag, user);
      }
      return bag;
    } on StateError catch (e) {
      pp(e.message); // In a bad state!
    } on FormatException catch (e) {
      pp(e.message);
    }
    return null;
  }

  Future<void> _cacheTheData(DataBag? bag, User user) async {
    pp('\n$xx zipped Data returned from server, adding to Hive cache ...');

    await cacheManager.addProjects(projects: bag!.projects!);
    await cacheManager.addProjectPolygons(polygons: bag.projectPolygons!);
    await cacheManager.addProjectPositions(positions: bag.projectPositions!);
    await cacheManager.deleteUsers();
    await cacheManager.addUsers(users: bag.users!);
    await cacheManager.addPhotos(photos: bag.photos!);
    await cacheManager.addVideos(videos: bag.videos!);
    await cacheManager.addAudios(audios: bag.audios!);
    await cacheManager.addSettingsList(settings: bag.settings!);
    await cacheManager.addFieldMonitorSchedules(
        schedules: bag.fieldMonitorSchedules!);

    for (var element in bag.users!) {
      if (element.userId == user.userId) {
        await prefsOGx.saveUser(element);
        fcmBloc.userController.sink.add(element);
      }
    }

    pp('\n$xx Org Data saved in Hive cache ...');
  }
}

/// Isolate functions to get organization data from the cloud...
Future<DataBag?> refreshDataInIsolate(
    {required String token,
    required String organizationId,
    required String startDate,
    required String endDate,
    required String url}) async {
  pp('$xz refreshDataInIsolate starting ....');
  DataBag? bag;
  try {
    bag = await getOrganizationDataZippedFile(
        url: url,
        organizationId: organizationId,
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
    required String url}) async {
  pp('\n\n$xz getOrganizationDataZippedFile  🔆🔆🔆 orgId : 💙  $organizationId  💙');
  start = DateTime.now().millisecondsSinceEpoch;
  var mUrl =
      '${url!}getOrganizationDataZippedFile?organizationId=$organizationId&startDate=$startDate&endDate=$endDate';

  var bag = await _getDataBag(mUrl, token);
  return bag;
}

Future<DataBag?> _getDataBag(String mUrl, String token) async {
  http.Response response = await _sendRequestToBackend(mUrl, token);
  var dir = await getApplicationDocumentsDirectory();
  File zipFile =
      File('${dir.path}/zip${DateTime.now().millisecondsSinceEpoch}.zip');
  zipFile.writeAsBytesSync(response.bodyBytes);

  //create zip archive
  final inputStream = InputFileStream(zipFile.path);
  final archive = ZipDecoder().decodeBuffer(inputStream);

  DataBag? dataBag;
  //handle file inside zip archive
  for (var file in archive.files) {
    if (file.isFile) {
      var fileName = '${dir.path}/${file.name}';
      pp('$xz file from inside archive ... ${file.size} bytes 🔵 isCompressed: ${file.isCompressed} 🔵 zipped file name: ${file.name}');
      var outFile = File(fileName);
      outFile = await outFile.create(recursive: true);
      await outFile.writeAsBytes(file.content);
      pp('$xz file after decompress ... ${await outFile.length()} bytes  🍎 path: ${outFile.path} 🍎');

      if (outFile.existsSync()) {
        pp('$xz decompressed file exists and has length of 🍎 ${await outFile.length()} bytes');
        var m = outFile.readAsStringSync(encoding: utf8);
        var mJson = json.decode(m);
        dataBag = DataBag.fromJson(mJson);
        _printDataBag(dataBag);

        var end = DateTime.now().millisecondsSinceEpoch;
        var ms = (end - start) / 1000;
        pp('$xz getOrganizationDataZippedFile 🍎🍎🍎🍎 work is done!, elapsed seconds: $ms\n\n');
      }
    }
  }

  return dataBag;
}

final client = http.Client();
int start = 0;

Future<http.Response> _sendRequestToBackend(String mUrl, String token) async {
  pp('$xz _sendRequestToBackend call:  🔆 🔆 🔆 calling : 💙  $mUrl  💙');
  var start = DateTime.now();

  Map<String, String> headers = {
    'Content-type': 'application/zip',
    'Accept': '*/*',
    'Content-Encoding': 'gzip',
    'Accept-Encoding': 'gzip, deflate',
    'Authorization': 'Bearer $token'
  };

  try {
    http.Response resp = await client
        .get(
          Uri.parse(mUrl),
          headers: headers,
        )
        .timeout(const Duration(seconds: 120));
    pp('$xz _sendRequestToBackend RESPONSE: .... : 💙 statusCode: 👌👌👌 '
        '${resp.statusCode} 👌👌👌  for $mUrl');

    var end = DateTime.now();
    pp('$xz http GET call: 🔆 elapsed time for http: '
        '${end.difference(start).inSeconds} seconds 🔆 \n\n');

    if (resp.statusCode != 200) {
      var msg =
          '😡😡😡😡 The response is not 200; it is ${resp.statusCode}, '
          'NOT GOOD, throwing up !! 😡 ${resp.body}';
      pp(msg);
      throw HttpException(msg);
    }
    return resp;
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
