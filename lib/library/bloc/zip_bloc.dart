import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:geo_monitor/library/api/data_api.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';


import '../auth/app_auth.dart';
import '../data/data_bag.dart';
import '../functions.dart';

final ZipBloc zipBloc = ZipBloc();
class ZipBloc {

  static const xz = '🌎🌎🌎🌎🌎🌎ZipBloc: ';
  static final client = http.Client();
  static int start = 0;


  Future<DataBag?> getOrganizationDataZippedFile(String organizationId) async {
    pp('\n\n$xz getOrganizationDataZippedFile  🔆🔆🔆 orgId : 💙  $organizationId  💙');
    start = DateTime.now().millisecondsSinceEpoch;
    var url = await DataAPI.getUrl();
    var mUrl = '${url!}getOrganizationDataZippedFile?organizationId=$organizationId';

    pp('$xz url for getting zipped file: mUrl: $mUrl');
    http.Response response = await _sendHttpGET(mUrl);
    var dir = await getApplicationDocumentsDirectory();
    File zipFile = File('${dir.path}/zip${DateTime.now().millisecondsSinceEpoch}.zip');
    zipFile.writeAsBytesSync(response.bodyBytes);
    pp('$xz zipFile has been written? 🔵🔵🔵 ${await zipFile.length()} bytes in zipFile');
    final inputStream = InputFileStream(zipFile.path);
    final archive = ZipDecoder().decodeBuffer(inputStream);
    pp('$xz archive anyone? archive.files: ${archive.files.length} numberOfFiles: ${archive.numberOfFiles()}');
    for (var file in archive.files) {
      if (file.isFile) {
        var fileName = '${dir.path}/${file.name}';
        pp('$xz file from inside archive ... ${file.size} bytes 🔵 isCompressed: ${file.isCompressed} 🔵 zipped file name: ${file.name}');
        var outFile = File(fileName);
        pp('$xz file to write zipped content; path: ${outFile.path}');
        outFile = await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content);
        pp('$xz file after decompress ... ${await outFile.length()} bytes and 🍎 isCompressed: ${outFile.path} 🍎 uri: ${outFile.uri}');

        if (outFile.existsSync()) {
          pp('$xz outFile exists and has length of 🍎 ${await outFile.length()} bytes');
          var m = outFile.readAsStringSync(encoding: utf8);
          var mJson = json.decode(m);
          var bag = DataBag.fromJson(mJson);
          pp('$xz getOrganizationDataZippedFile 🍎🍎🍎🍎 work may be done!');
          _printDataBag(bag);
          var end = DateTime.now().millisecondsSinceEpoch;
          var ms = (end - start)/1000;
          pp('$xz getOrganizationDataZippedFile 🍎🍎🍎🍎 work is done!, elapsed seconds: $ms\n\n');

          return bag;
        }
      }
    }
     return null;
  }

  static Map<String, String> headers = {
    'Content-type': 'application/zip',
    'Accept': '*/*',
    'Content-Encoding': 'gzip',
    'Accept-Encoding': 'gzip, deflate'
  };
  static Future<http.Response> _sendHttpGET(String mUrl) async {
    pp('$xz http GET call:  🔆 🔆 🔆 calling : 💙  $mUrl  💙');
    var start = DateTime.now();
    var token = await AppAuth.getAuthToken();
    if (token != null) {
      pp('$xz http GET call: 😡😡😡 Firebase Auth Token: 💙️ Token is GOOD! 💙 ');
    }

    headers['Authorization'] = 'Bearer $token';

    try {
      http.Response resp = await client.get(
        Uri.parse(mUrl),
        headers: headers,
      ).timeout( const Duration(seconds: 120));
      pp('$xz http GET call RESPONSE: .... : 💙 statusCode: 👌👌👌 ${resp.statusCode} 👌👌👌 💙 for $mUrl');
      // pp(resp);
      var end = DateTime.now();
      pp('$xz http GET call: 🔆 elapsed time for http: ${end.difference(start).inSeconds} seconds 🔆 \n\n');

      if (resp.statusCode != 200) {
        var msg =
            '😡 😡 The response is not 200; it is ${resp.statusCode}, NOT GOOD, throwing up !! 🥪 🥙 🌮  😡 ${resp.body}';
        pp(msg);
        throw HttpException(msg);
      }
      return resp;
    } on SocketException {
      pp('$xz No Internet connection, really means that server cannot be reached 😑');
      throw 'GeoMonitor server cannot be reached at this time. Please try later';
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
    pp('\n\n$xz all org data extracted from zipped file on: 🔵🔵🔵${bag.date}');
    pp('$xz projects: $projects');
    pp('$xz users: $users');
    pp('$xz positions: $positions');
    pp('$xz polygons: $polygons');
    pp('$xz photos: $photos');
    pp('$xz videos: $videos');
    pp('$xz audios: $audios');
    pp('$xz schedules: $schedules');
    pp('$xz all org data listed above: 🔵🔵🔵 ${bag.date}');
  }

}