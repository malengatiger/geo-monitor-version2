import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:geo_monitor/library/bloc/photo_for_upload.dart';
import 'package:geo_monitor/library/bloc/video_for_upload.dart';
import 'package:http/http.dart' as http;

import '../../l10n/translation_handler.dart';
import '../cache_manager.dart';
import '../data/audio.dart';
import '../data/photo.dart';
import '../data/video.dart';
import '../emojis.dart';
import '../functions.dart';
import 'audio_for_upload.dart';

///
///TOP LEVEL functions running inside an isolate
///
http.Client client = http.Client();

Future<Photo?> uploadPhotoFile(
    {required String objectName,
    required String url,
    required String token,
    required int height,
    required int width,
    required String mJson,
    required double distance}) async {
  pp('$xx 🍐🍐🍐🍐🍐🍐 _uploadPhotoFile: objectName: $objectName url: $url');

  var map = json.decode(mJson);
  var photoForUpload = PhotoForUpload.fromJson(map);
  var mPath = photoForUpload.filePath;
  var tPath = photoForUpload.thumbnailPath;
  //create multipart request for POST or PATCH method
  String? responseUrl =
      await _sendUploadRequest(token, url, objectName, mPath!);
  String? thumbUrl = await _sendUploadRequest(
      token, url, 'thumb_${DateTime.now().toUtc().toIso8601String()}', tPath!);
  pp('$xx 🍐🍐🍐🍐🍐🍐 photo and thumbnail uploaded; attempting to add photo to DB ...');
  if (responseUrl == null) {
    pp('$xx problems with uploading file, response url is null');
    return null;
  }
  final sett = await cacheManager.getSettings();
  final photoArrived =
      await translator.translate('photoArrived', sett!.locale!);
  final messageFromGeo =
      await translator.translate('messageFromGeo', sett!.locale!);

  var photo = Photo(
      url: responseUrl,
      userUrl: photoForUpload.userThumbnailUrl,
      caption: 'tbd',
      created: photoForUpload.date,
      userId: photoForUpload.userId,
      userName: photoForUpload.userName,
      translatedMessage: photoArrived,
      translatedTitle: messageFromGeo,
      projectPosition: photoForUpload.position!,
      distanceFromProjectPosition: distance,
      projectId: photoForUpload.project!.projectId,
      thumbnailUrl: thumbUrl,
      projectName: photoForUpload.project!.name,
      organizationId: photoForUpload.organizationId,
      height: height,
      width: width,
      projectPositionId: photoForUpload.projectPositionId,
      projectPolygonId: photoForUpload.projectPolygonId,
      photoId: photoForUpload.photoId,
      landscape: width > height ? 0 : 1);

  var mPhoto = await _addPhotoToDatabase(photo, url, token);
  return mPhoto;
}

Future<Audio?> uploadAudioFile(
    {required String objectName,
    required String url,
    required String token,
    required int height,
    required int width,
    required String mJson,
    required double distance}) async {
  pp('$xx 🍐🍐🍐🍐🍐🍐 _uploadAudioFile: objectName: $objectName url: $url');

  var map = json.decode(mJson);
  var audioForUpload = AudioForUpload.fromJson(map);
  var mPath = audioForUpload.filePath;
  //create multipart request for POST or PATCH method
  var mFile = File(mPath!);
  if (!mFile.existsSync()) {
    pp('$xx File does not exist. 🔴🔴🔴 Deplaning ...');
    return null;
  }
  String? responseUrl = await _sendUploadRequest(token, url, objectName, mPath);

  pp('$xx 🍐🍐🍐🍐🍐🍐 audio file uploaded; attempting to add audio to DB ...');
  if (responseUrl == null) {
    pp('$xx problems with uploading file, response url is null');
    return null;
  }

  final sett = await cacheManager.getSettings();
  final audioArrived =
      await translator.translate('audioArrived', sett!.locale!);
  final messageFromGeo =
      await translator.translate('messageFromGeo', sett!.locale!);

  var audio = Audio(
      url: responseUrl,
      userUrl: audioForUpload.userThumbnailUrl,
      caption: 'tbd',
      created: audioForUpload.date,
      userId: audioForUpload.userId,
      userName: audioForUpload.userName,
      translatedTitle: messageFromGeo,
      translatedMessage: audioArrived,
      projectPosition: audioForUpload.position!,
      distanceFromProjectPosition: distance,
      projectId: audioForUpload.project!.projectId,
      projectName: audioForUpload.project!.name,
      organizationId: audioForUpload.organizationId,
      durationInSeconds: audioForUpload.durationInSeconds,
      audioId: audioForUpload.audioId);
  var mAudio = await _addAudioToDatabase(audio, url, token);
  return mAudio;
}

Future<Video?> uploadVideoFile(
    {required String objectName,
    required String url,
    required String token,
    required double size,
    required String mJson,
    required double distance}) async {
  pp('\n\n$xx 🍐🍐🍐🍐🍐🍐 _uploadVideoFile: objectName: $objectName '
      ' size : $size MB');
  var map = json.decode(mJson);
  var videoForUpload = VideoForUpload.fromJson(map);

  var mPath = videoForUpload.filePath;
  var tPath = videoForUpload.thumbnailPath;
  String? responseUrl =
      await _sendUploadRequest(token, url, objectName, mPath!);
  String? thumbUrl =
      await _sendUploadRequest(token, url, 'thumb_$objectName', tPath!);

  pp('\n$xx video mp4 and thumbnail jpg uploaded OK! 👋🏽👋🏽👋🏽👋🏽👋🏽\n');

  if (responseUrl == null) {
    pp('$xx problems with uploading file');
    return null;
  }
  pp('$xx 🍐🍐🍐🍐🍐🍐 attempting to add video to DB ... size: $size MB');
  final messageTitle = await getFCMMessageTitle();
  final videoArrived = await getFCMMessage('videoArrived');

  var video = Video(
      url: responseUrl,
      userUrl: videoForUpload.userThumbnailUrl,
      caption: 'tbd',
      created: videoForUpload.date,
      userId: videoForUpload.userId,
      userName: videoForUpload.userName,
      projectPosition: videoForUpload.position!,
      distanceFromProjectPosition: distance,
      translatedMessage: videoArrived,
      translatedTitle: messageTitle,
      projectId: videoForUpload.project!.projectId,
      thumbnailUrl: thumbUrl,
      projectName: videoForUpload.project!.name,
      organizationId: videoForUpload.organizationId,
      size: size,
      durationInSeconds: videoForUpload.durationInSeconds,
      projectPositionId: videoForUpload.projectPositionId,
      projectPolygonId: videoForUpload.projectPolygonId,
      videoId: videoForUpload.videoId);

  var mVideo = await _addVideoToDatabase(video, url, token);
  return mVideo;
}

Future<Photo> _addPhotoToDatabase(Photo photo, String url, String token) async {
  try {
    var result = await _callPost('${url}addPhoto', photo.toJson(), token);
    pp('\n\n\n$xx 🔴🔴🔴  addPhoto succeeded. Everything OK?? 🔴🔴🔴');
    var photoBack = Photo.fromJson(result);
    pp('$xx addPhoto has added photo to DB \n');
    return photoBack;
  } catch (e) {
    pp('\n\n\n$xx 🔴🔴🔴  addPhoto failed. Something fucked up here! ... 🔴🔴🔴\n\n');
    pp(e);
    rethrow;
  }
}

Future<Video> _addVideoToDatabase(Video video, String url, String token) async {
  try {
    var result = await _callPost('${url}addVideo', video.toJson(), token);
    pp('\n\n\n$xx 🔴🔴🔴  addVideo succeeded. Everything OK?? 🔴🔴🔴');
    var videoBack = Video.fromJson(result);
    pp('$xx addVideo has added video to DB \n');
    return videoBack;
  } catch (e) {
    pp('\n\n\n$xx 🔴🔴🔴  addVideo failed. Something fucked up here! ... 🔴🔴🔴\n\n');
    pp(e);
    rethrow;
  }
}

Future<Audio> _addAudioToDatabase(Audio audio, String url, String token) async {
  try {
    var result = await _callPost('${url}addAudio', audio.toJson(), token);
    pp('\n\n\n$xx 🔴🔴🔴  addAudio succeeded. Everything OK?? 🔴🔴🔴');
    var audioBack = Audio.fromJson(result);
    pp('$xx addAudio has added audio to DB \n');
    return audioBack;
  } catch (e) {
    pp('\n\n\n$xx 🔴🔴🔴  addAudio failed. Something fucked up here! ... 🔴🔴🔴\n\n');
    pp(e);
    rethrow;
  }
}

Future _callPost(String mUrl, Map? bag, String token) async {
  pp('$xx _callPost: 🔆 🔆 🔆  calling : 💙  $mUrl  💙 ');
  Map<String, String> headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
  };
  String? mBag;
  if (bag != null) {
    mBag = json.encode(bag);
  }
  var start = DateTime.now();
  headers['Authorization'] = 'Bearer $token';
  try {
    var resp = await client
        .post(
          Uri.parse(mUrl),
          body: mBag,
          headers: headers,
        )
        .timeout(const Duration(seconds: 120));
    if (resp.statusCode == 200) {
      pp('$xx http POST call RESPONSE: 💙💙 statusCode: 👌👌👌 ${resp.statusCode} 👌👌👌 💙 for $mUrl');
    } else {
      pp('👿👿👿 ._callWebAPIPost: 🔆 statusCode: 👿👿👿 ${resp.statusCode} 🔆🔆🔆 for $mUrl');
      pp(resp.body);
      throw Exception('🚨🚨 Status Code 🚨 ${resp.statusCode} 🚨 ${resp.body}');
    }
    var end = DateTime.now();
    pp('$xx http POST call: 🔆 elapsed time: ${end.difference(start).inSeconds} seconds 🔆');
    try {
      var mJson = json.decode(resp.body);
      return mJson;
    } catch (e) {
      pp("👿👿👿👿👿👿👿 json.decode failed, returning response body");
      return resp.body;
    }
  } on SocketException {
    pp('\n\n$xx ${E.redDot}${E.redDot} ${E.redDot} '
        'GeoMonitor Server not available. ${E.redDot} Possible Internet Connection issue '
        '${E.redDot} ${E.redDot} ${E.redDot}\n');
    throw 'GeoMonitor Server not available. Possible Internet Connection issue';
  } on HttpException {
    pp("$xx Couldn't find the post 😱");
    throw 'Could not find the post';
  } on FormatException {
    pp("$xx Bad response format 👎");
    throw 'Bad response format';
  } on TimeoutException {
    pp("$xx POST Request has timed out in 120 seconds 👎");
    throw 'Request has timed out in 120 seconds';
  }
}

const xx = '😎😎😎😎😎😎😎😎 Isolate Uploader Functions : 😎😎😎 ';

Future<String?> _sendUploadRequest(
    String token, String url, String objectName, String path) async {
  Map<String, String> headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token'
  };

  var mUrl = '${url}uploadFile';
  var request = http.MultipartRequest("POST", Uri.parse(mUrl));
  request.fields["objectName"] = objectName;
  var multiPartFile = await http.MultipartFile.fromPath("document", path);
  request.files.add(multiPartFile);
  request.headers.addAll(headers);

  String? responseString;
  try {
    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.toBytes();
      responseString = String.fromCharCodes(responseData);
    } else {
      pp('\n\n$xx We have a problem, Boss! 🔴🔴🔴 statusCode: ${response.statusCode} '
          '- ${response.reasonPhrase}');
    }
  } catch (e) {
    pp('$xx Possible network problem with request.send() 🔴🔴🔴 $e');
  }

  return responseString;
}

Future<String?> getSignedUploadUrl(
    {required String mUrl,
    required String token,
    required String objectName,
    required String contentType}) async {
  pp('$xx getSignedUploadUrl:  🔆 🔆 🔆 calling : 💙  $mUrl  💙');
  Map<String, String> headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
  };

  var u = 'getSignedUrl?objectName=$objectName&contentType=$contentType';
  var finalUrl = '$mUrl$u';
  pp(finalUrl);
  var start = DateTime.now();
  headers['Authorization'] = 'Bearer $token';
  try {
    var resp = await client
        .get(
          Uri.parse(finalUrl),
          headers: headers,
        )
        .timeout(const Duration(seconds: 120));
    pp('$xx http GET call RESPONSE: .... : 💙 statusCode: 👌👌👌'
        ' ${resp.statusCode} 👌👌👌 💙 for $finalUrl');
    var end = DateTime.now();
    pp('$xx getSignedUploadUrl call: 🔆 elapsed time for http: '
        '${end.difference(start).inSeconds} seconds 🔆');
    if (resp.statusCode != 200) {
      var msg = '😡 😡 The response is not 200; it is ${resp.statusCode}, '
          'NOT GOOD, throwing up !! 🥪 🥙 🌮  😡 ${resp.body}';
      pp(msg);
      throw HttpException(msg);
    }
    // var mJson = json.decode(resp.body);
    return resp.body;
  } on SocketException {
    pp('$xx No Internet connection, really means that server cannot be reached 😑');
    throw 'GeoMonitor server cannot be reached at this time. Please try again!';
  } on HttpException {
    pp("$xx HttpException occurred 😱");
    throw 'HttpException';
  } on FormatException {
    pp("$xx Bad response format 👎");
    throw 'Bad response format';
  } on TimeoutException {
    pp("$xx GET Request has timed out in 120 seconds 👎");
    throw 'Request has timed out in 120 seconds';
  }
}

Future uploadUsingSignedUrl(
    {required String mUrl, required File file, required String token}) async {
  Map<String, String> headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
  };
  headers['Authorization'] = 'Bearer $token';
  pp('$xx uploadUsingSignedUrl starting ... 🔆🔆🔆🔆🔆🔆🔆🔆🔆🔆🔆 ');

  var start = DateTime.now();
  Uint8List m = await file.readAsBytes();
  var resp = await client
      .post(
        Uri.parse(mUrl),
        headers: headers,
      )
      .timeout(const Duration(seconds: 120));
  var end = DateTime.now();
  pp('$xx uploadUsingSignedUrl call: 🔆 elapsed time: ${end.difference(start).inSeconds} '
      'seconds 🔆 \n\n');
  pp(resp);
  if (resp.statusCode == 200) {
    pp('$xx uploadUsingSignedUrl: RESPONSE: 💙💙 statusCode: 👌👌👌 '
        '${resp.statusCode} 👌👌👌 💙 for $mUrl');
  } else {
    pp('$xx 👿👿👿 DataAPI._callWebAPIPost: 🔆 statusCode: 👿👿👿 '
        '${resp.statusCode} 🔆🔆🔆 for $mUrl');
    pp(resp.body);
    throw Exception('🚨 🚨 Status Code 🚨 ${resp.statusCode} 🚨 ${resp.body}');
  }
  return null;
}
