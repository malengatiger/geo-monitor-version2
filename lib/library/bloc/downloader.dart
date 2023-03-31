import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:geo_monitor/library/api/data_api.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/auth/app_auth.dart';
import 'package:geo_monitor/library/bloc/organization_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:stream_channel/isolate_channel.dart';

import '../cache_manager.dart';
import '../data/data_bag.dart';
import '../emojis.dart';
import '../functions.dart';

final DownloaderService downloaderService = DownloaderService._instance;

/// downloads org data in isolate
class DownloaderService {
  static final DownloaderService _instance = DownloaderService._internal();

  factory DownloaderService() {
    return _instance;
  }
  DownloaderService._internal() {
    // initialization logic
  }
  static const mm = '🌎🌎🌎🌎🌎🌎 DownloaderService: ';

  late SendPort sendPort;
  static final client = http.Client();
  Map<String, String> headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
  };
  late DownloadParameters cacheParameters;

  Future start({required DownloadParameters params}) async {
    pp('\n\n$mm .... starting Downloader ISOLATE for downloading organization data\n');
    sendPort = params.sendPort;
    cacheParameters = params;

    var msgStart = DownloaderMessage(
        message: 'Download started',
        statusCode: statusBusy,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: 0.0,
        type: typeMessage,
        dataBagJson: null);

    sendPort.send(msgStart.toJson());
    var start = DateTime.now().millisecondsSinceEpoch;
    try {
      var bag = await getOrganizationData();

      var end = DateTime.now().millisecondsSinceEpoch;
      var elapsedSeconds = (end - start) / 1000;
      var msg = DownloaderMessage(
          message: 'Download complete',
          statusCode: statusDone,
          date: DateTime.now().toIso8601String(),
          elapsedSeconds: elapsedSeconds,
          type: typeOrgData,
          dataBagJson: bag.toJson());

      pp('$mm Organization Data downloaded OK; time elapsed: 🔵🔵🔵 $elapsedSeconds seconds');
      pp('$mm Organization Data downloaded OK; sending dataBag over sendPort');

      sendPort.send(msg.toJson());
    } catch (e) {
      pp(e);
      _handleError(start);
    }
  }

  void _handleError(int start) {
    var end = DateTime.now().millisecondsSinceEpoch;
    var elapsedSeconds = (end - start) / 1000;
    var msg = DownloaderMessage(
        message: 'Download ERROR',
        statusCode: statusError,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsedSeconds,
        type: typeError,
        dataBagJson: null);

    sendPort.send(msg.toJson());
  }

  Future<DataBag> getOrganizationData() async {
    try {
      var url = cacheParameters.url;
      var mUrl =
          '$url/getOrganizationData?organizationId=${cacheParameters.organizationId}';

      var result = await _sendHttpGET(mUrl);
      final bag = DataBag.fromJson(result);
      pp('\n$mm Organization Data returned from server, ...');
      return bag;
    } catch (e) {
      pp('$mm getOrganizationData: $e');
      rethrow;
    }
  }

  Future _sendHttpGET(String mUrl) async {
    pp('$mm GET call: 🔆🔆🔆 💙 $mUrl 💙');
    var start = DateTime.now();

    headers['Authorization'] = 'Bearer ${cacheParameters.token}';

    try {
      var resp = await client
          .get(
            Uri.parse(mUrl),
            headers: headers,
          )
          .timeout(const Duration(seconds: 90));
      pp('$mm GET call RESPONSE: 💙 statusCode: 👌👌👌 ${resp.statusCode} 👌👌👌 💙 for $mUrl');
      var end = DateTime.now();
      pp('$mm GET call: 🔆 elapsed time for http: ${end.difference(start).inSeconds} seconds 🔆 \n\n');

      if (resp.body.contains('not found')) {
        return false;
      }
      if (resp.statusCode != 200) {
        var msg =
            '😡😡The response is not 200; it is 🔴  ${resp.statusCode}  🔴,'
            ' NOT GOOD, throwing up !! 🥪🥙🌮😡 ${resp.body}';
        pp(msg);
        throw HttpException(msg);
      }
      var mJson = json.decode(resp.body);
      return mJson;
    } on SocketException {
      pp('$mm No Internet connection, really means that server cannot be reached 😑');
      throw 'GeoMonitor server cannot be reached at this time. Please try later';
    } on HttpException {
      pp("$mm HttpException occurred 😱");
      throw 'HttpException';
    } on FormatException {
      pp("$mm Bad response format 👎");
      throw 'Bad response format';
    } on TimeoutException {
      pp("$mm GET Request has timed out in 90 seconds 👎");
      throw 'Request has timed out in 90 seconds';
    }
  }
}

class DownloaderMessage {
  late String message;
  late int statusCode;
  late int type;
  late String date;
  late double? elapsedSeconds;
  late Map<String, dynamic>? dataBagJson;

  DownloaderMessage({
    required this.message,
    required this.statusCode,
    required this.date,
    required this.elapsedSeconds,
    required this.type,
    this.dataBagJson,
  });

  DownloaderMessage.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    type = json['type'];
    statusCode = json['statusCode'];
    date = json['date'];
    elapsedSeconds = json['elapsedSeconds'];
    dataBagJson = json['dataBagJson'];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'elapsedSeconds': elapsedSeconds,
        'message': message,
        'date': date,
        'type': type,
        'statusCode': statusCode,
        'dataBagJson': dataBagJson,
      };
}

class DownloadParameters {
  late SendPort sendPort;
  late String url;
  late int limit;
  late String organizationId, token;

  DownloadParameters({
    required this.sendPort,
    required this.url,
    required this.organizationId,
    required this.limit,
    required this.token,
  });
}

final DownloaderStarter downloaderStarter = DownloaderStarter();

/// starts the DownloaderService isolate to download org data
///

class DownloaderStarter {
  late SendPort sendPort;
  final ReceivePort receivePort = ReceivePort();
  late Isolate isolate;
  IsolateChannel? channel;
  static const mm = '🥬🥬🥬🥬🥬🥬 DownloaderStarter: ';
  DataBag? dataBag;
  final StreamController<DataBag> _streamController =
      StreamController.broadcast();
  Stream<DataBag> get dataBagStream => _streamController.stream;

  void start() async {
    pp('\n$mm ... starting DownloaderStarter ....');
    var user = await prefsOGx.getUser();
    if (user == null) {
      throw Exception('User not found in cache');
    }
    var url = await DataAPI.getUrl();
    var token = await AppAuth.getAuthToken();
    sendPort = receivePort.sendPort;

    var params = DownloadParameters(
        sendPort: sendPort,
        url: url!,
        organizationId: user.organizationId!,
        limit: 2000,
        token: token!);
    await _createIsolate(params);
    pp('$mm isolate has been created ...');
  }

  void _handleDataBag(DataBag bag) async {
    pp('\n$mm Data returned from server, adding to Hive cache ...');

    await cacheManager.addProjects(projects: bag.projects!);
    await cacheManager.addProjectPolygons(polygons: bag.projectPolygons!);
    await cacheManager.addProjectPositions(positions: bag.projectPositions!);
    await cacheManager.addUsers(users: bag.users!);
    await cacheManager.addPhotos(photos: bag.photos!);
    await cacheManager.addVideos(videos: bag.videos!);
    await cacheManager.addAudios(audios: bag.audios!);
    bag.settings!.sort((a, b) => DateTime.parse(b.created!)
        .millisecondsSinceEpoch
        .compareTo(DateTime.parse(a.created!).millisecondsSinceEpoch));
    if (bag.settings!.isNotEmpty) {
      await cacheManager.addSettings(settings: bag.settings!.first);
    }
    await cacheManager.addFieldMonitorSchedules(
        schedules: bag.fieldMonitorSchedules!);

    pp('\n$mm Organization Data returned from server, cached on local Hive store ...');
    pp('\n$mm Organization Data returned from server, putting on dataBagStream ...');

    _putContentsOfBagIntoStreams(bag);

    pp('\n\n$mm DownloaderStarter has refreshed the org data in cache and streams ...\n\n');
  }

  void _putContentsOfBagIntoStreams(DataBag bag) {
    pp('$mm _putContentsOfBagIntoStreams: .................................... '
        '🔵 send org data to streams ...');
    try {
      try {
        if (bag.photos != null) {
          bag.photos!.sort((a, b) => b.created!.compareTo(a.created!));
          organizationBloc.photoController.sink.add(bag.photos!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams photos ERROR - $e');
      }
      try {
        if (bag.videos != null) {
          bag.videos!.sort((a, b) => b.created!.compareTo(a.created!));
          organizationBloc.videoController.sink.add(bag.videos!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams videos ERROR - $e');
      }
      try {
        if (bag.audios != null) {
          bag.audios!.sort((a, b) => b.created!.compareTo(a.created!));
          organizationBloc.audioController.sink.add(bag.audios!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams audios ERROR - $e');
      }
      try {
        if (bag.fieldMonitorSchedules != null) {
          bag.fieldMonitorSchedules!.sort((a, b) => b.date!.compareTo(a.date!));
          organizationBloc.fieldMonitorScheduleController.sink
              .add(bag.fieldMonitorSchedules!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams fieldMonitorSchedules ERROR - $e');
      }
      try {
        if (bag.users != null) {
          bag.users!.sort((a, b) => a.name!.compareTo(b.name!));
          organizationBloc.userController.sink.add(bag.users!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams users ERROR - $e');
      }
      try {
        if (bag.projects != null) {
          bag.projects!.sort((a, b) => a.name!.compareTo(b.name!));
          organizationBloc.projController.sink.add(bag.projects!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams projects ERROR - $e');
      }
      try {
        if (bag.projectPositions != null) {
          // bag.projectPositions!
          //     .sort((a, b) => b.created!.compareTo(a.created!));
          organizationBloc.projPositionsController.sink
              .add(bag.projectPositions!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams projectPositions ERROR - $e');
      }
      try {
        if (bag.projectPolygons != null) {
          bag.projectPolygons!.sort((a, b) => b.created!.compareTo(a.created!));
          organizationBloc.projPolygonsController.sink
              .add(bag.projectPolygons!);
        }
      } catch (e) {
        pp('$mm _putContentsOfBagIntoStreams projectPolygons ERROR - $e');
      }

      pp('$mm _putContentsOfBagIntoStreams: .................................... '
          '🔵🔵🔵🔵 send data to streams completed...');
    } catch (e) {
      pp('$mm _putContentsOfBagIntoStreams ERROR - $e');
    }
  }

  Future _createIsolate(DownloadParameters cacheParameters) async {
    try {
      var errorReceivePort = ReceivePort();
      if (channel == null) {
        channel = IsolateChannel(receivePort, cacheParameters.sendPort);
        pp('$mm about to listen to isolate channel ... suspect error occurs here');
        channel!.stream.listen((data) async {
          if (data != null) {
            pp('$mm '
                'Received downloader result ${E.appleRed} DownloaderMessage '
                'statusCode: ${data['statusCode']} '
                'type: ${data['type']} msg: ${data['message']} elapsed: ${data['elapsedSeconds']}');
            try {
              var msg = DownloaderMessage.fromJson(data);
              switch (msg.type) {
                case typeMessage:
                  pp('$mm message from isolate: 🔵🔵🔵${msg.toJson()}');
                  break;
                case typeError:
                  pp('$mm error from isolate: 🔴🔴🔴${msg.toJson()}');
                  break;
                case typeOrgData:
                  dataBag = DataBag.fromJson(msg.dataBagJson!);
                  _handleDataBag(dataBag!);
                  isolate.kill();
                  pp('\n\n$mm 🔴🔴🔴 isolate killed: 🔴🔴🔴\n\n');
                  break;
                default:
                  pp('$mm ${E.redDot}${E.redDot}${E.redDot}${E.redDot}'
                      ' ........... type not available! wtf? ${E.redDot}');
                  break;
              }
            } catch (e) {
              //
            }
          }
        });
      } else {
        pp('$mm Isolate channel is not null ...');
      }

      isolate = await Isolate.spawn<DownloadParameters>(
          heavyTask, cacheParameters,
          paused: true,
          onError: errorReceivePort.sendPort,
          onExit: receivePort.sendPort);

      isolate.addErrorListener(errorReceivePort.sendPort);
      isolate.resume(isolate.pauseCapability!);
      isolate.addOnExitListener(receivePort.sendPort);

      errorReceivePort.listen((e) {
        pp('$mm ${E.redDot}${E.redDot} exception occurred: $e');
      });
    } catch (e) {
      pp('$mm ${E.redDot} we have a problem: $e ${E.redDot} ${E.redDot}');
    }
  }
}

Future<void> heavyTask(DownloadParameters params) async {
  pp('\n\n 🔆🔆🔆🔆🔆🔆🔆🔆 '
      'Starting heavyTask in the famous Isolate! ..........');
  downloaderService.start(params: params);
}

const typeUsers = 1,
    typeError = 2,
    typeOrgData = 3,
    typeMessage = 4,
    typeProjects = 5,
    typePhotos = 6,
    typeVideos = 7,
    typeAudios = 8,
    typeSettings = 9,
    typePositions = 10,
    typePolygons = 11,
    typeSchedules = 12;

const statusBusy = 200, statusDone = 201, statusError = 500;
