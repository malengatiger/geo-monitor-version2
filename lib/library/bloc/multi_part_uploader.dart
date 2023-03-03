import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:geo_monitor/library/api/data_api.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/bloc/photo_for_upload.dart';
import 'package:geo_monitor/library/bloc/video_for_upload.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../../device_location/device_location_bloc.dart';
import '../auth/app_auth.dart';
import '../cache_manager.dart';
import '../data/audio.dart';
import '../data/photo.dart';
import '../data/user.dart';
import '../data/video.dart';
import '../emojis.dart';
import '../functions.dart';
import 'audio_for_upload.dart';

MultiPartUploader multiPartUploader = MultiPartUploader();

Random rand = Random(DateTime.now().millisecondsSinceEpoch);
const photoStorageName = 'geoPhotos3';
const videoStorageName = 'geoVideos3';
const audioStorageName = 'geoAudios3';
late http.Client client = http.Client();
late PhotoForUpload photoForUpload;
User? user;

class MultiPartUploader {
  static const mm = '🌿🌿🌿🌿🌿🌿 MultiPartUploader 🌿🌿🌿: ';

  Future<String?> startPhotoUpload(PhotoForUpload photoForUploading) async {
    String? resultUrl;

    user = await prefsOGx.getUser();
    try {
      String? url = await DataAPI.getUrl();
      var token = await AppAuth.getAuthToken();
      if (token != null) {
        pp('$mm http POST call: 😡😡😡 Firebase Auth Token: 💙️ Token is GOOD! 💙 ');
      }

      String path = photoForUploading.filePath!;
      var height = 0, width = 0;
      var file = File(path);
      decodeImageFromList(file.readAsBytesSync(), (image) {
        height = image.height;
        width = image.width;
      });
      var distance = await locationBloc.getDistanceFromCurrentPosition(
          latitude: photoForUpload.position!.coordinates[1],
          longitude: photoForUpload.position!.coordinates[0]);

      if (user == null) {
        pp('🔴🔴🔴🔴🔴🔴🔴🔴 user is null. WTF? 🔴🔴');
        throw Exception('Fuck it! - User is NULL!!');
      } else {
        pp('$xx 🍐🍐🍐🍐🍐🍐The user is OK');
      }

      var mJson = json.encode(photoForUpload.toJson());

      resultUrl = await Isolate.run(() async => await _uploadPhotoFile(
          objectName: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
          url: url!,
          token: token!,
          height: height,
          width: width,
          mJson: mJson,
          distance: distance));

      return resultUrl;
    } on StateError catch (e, s) {
      pp(e.message); // In a bad state!
    } on FormatException catch (e, s) {
      pp(e.message);
    }
    return null;
  }

  Future<String?> startVideoUpload(VideoForUpload videoForUploading) async {
    String? resultUrl;
    user = await prefsOGx.getUser();
    try {
      String? url = await DataAPI.getUrl();
      var token = await AppAuth.getAuthToken();
      if (token != null) {
        pp('$mm 😡😡😡 Firebase Auth Token: 💙️ Token is GOOD! 💙 ');
      }

      var height = 0, width = 0;

      var distance = await locationBloc.getDistanceFromCurrentPosition(
          latitude: photoForUpload.position!.coordinates[1],
          longitude: photoForUpload.position!.coordinates[0]);

      if (user == null) {
        pp('🔴🔴🔴🔴🔴🔴🔴🔴 user is null. WTF? 🔴🔴');
        throw Exception('Fuck it! - User is NULL!!');
      } else {
        pp('$xx 🍐🍐🍐🍐🍐🍐The user is OK');
      }

      var mJson = json.encode(videoForUploading.toJson());

      resultUrl = await Isolate.run(() async => await _uploadVideoFile(
          objectName: 'video${DateTime.now().millisecondsSinceEpoch}.mp4',
          url: url!,
          token: token!,
          height: height,
          width: width,
          mJson: mJson,
          distance: distance));

      return resultUrl;
    } on StateError catch (e, s) {
      pp(e.message); // In a bad state!
    } on FormatException catch (e, s) {
      pp(e.message);
    }
    return null;
  }

  Future<String?> startAudioUpload(AudioForUpload audioForUploading) async {
    String? resultUrl;
    user = await prefsOGx.getUser();
    try {
      String? url = await DataAPI.getUrl();
      var token = await AppAuth.getAuthToken();
      if (token != null) {
        pp('$mm 😡😡😡 Firebase Auth Token: 💙️ Token is GOOD! 💙 ');
      }

      var height = 0, width = 0;

      var distance = await locationBloc.getDistanceFromCurrentPosition(
          latitude: photoForUpload.position!.coordinates[1],
          longitude: photoForUpload.position!.coordinates[0]);

      if (user == null) {
        pp('🔴🔴🔴🔴🔴🔴🔴🔴 user is null. WTF? 🔴🔴');
        throw Exception('Fuck it! - User is NULL!!');
      } else {
        pp('$xx 🍐🍐🍐🍐🍐🍐The user is OK');
      }

      var mJson = json.encode(audioForUploading.toJson());

      resultUrl = await Isolate.run(() async => await _uploadAudioFile(
          objectName: 'audio${DateTime.now().millisecondsSinceEpoch}.mp3',
          url: url!,
          token: token!,
          height: height,
          width: width,
          mJson: mJson,
          distance: distance));

      return resultUrl;
    } on StateError catch (e, s) {
      pp(e.message); // In a bad state!
    } on FormatException catch (e, s) {
      pp(e.message);
    }
    return null;
  }

}

///TOP LEVEL functions running inside an isolate
Future<String> _uploadPhotoFile(
    {required String objectName,
      required String url,
      required String token,
      required int height,
      required int width,
      required String mJson,
      required double distance}) async {

  pp('$xx 🍐🍐🍐🍐🍐🍐 _uploadPhotoFile: objectName: $objectName url: $url');

  var map = json.decode(mJson);
  photoForUpload = PhotoForUpload.fromJson(map);
  var mPath = photoForUpload.filePath;
  var tPath = photoForUpload.thumbnailPath;
  //create multipart request for POST or PATCH method
  String responseUrl = await _sendRequest(token, url, objectName, mPath!);
  String thumbUrl =
  await _sendRequest(token, url, 'thumb_$objectName', tPath!);
  pp('🍐🍐🍐🍐🍐🍐 attempt to add photo to DB ...');

  var photo = Photo(
      url: responseUrl,
      userUrl: photoForUpload.userThumbnailUrl,
      caption: 'tbd',
      created: photoForUpload.date,
      userId: photoForUpload.userId,
      userName: photoForUpload.userName,
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

  await _addPhoto(photo, url, token);
  await cacheManager.removeUploadedPhoto(photo: photoForUpload);

  return responseUrl;
}

Future<String> _uploadAudioFile(
    {required String objectName,
      required String url,
      required String token,
      required int height,
      required int width,
      required String mJson,
      required double distance}) async {

  pp('$xx 🍐🍐🍐🍐🍐🍐 _uploadVideoFile: objectName: $objectName url: $url');

  var map = json.decode(mJson);
  var audioForUpload = AudioForUpload.fromJson(map);
  var mPath = audioForUpload.filePath;
  //create multipart request for POST or PATCH method
  String responseUrl = await _sendRequest(token, url, objectName, mPath!);

  pp('🍐🍐🍐🍐🍐🍐 attempt to add audio to DB ...');
  Duration? dur;
  try {
    AudioPlayer audioPlayer = AudioPlayer();
    dur = await audioPlayer.setUrl(url);
  } catch (e) {
    pp('$xx cannot get audio duration');
  }

  var audio = Audio(
      url: responseUrl,
      userUrl: audioForUpload.userThumbnailUrl,
      caption: 'tbd',
      created: audioForUpload.date,
      userId: audioForUpload.userId,
      userName: audioForUpload.userName,
      projectPosition: audioForUpload.position!,
      distanceFromProjectPosition: distance,
      projectId: audioForUpload.project!.projectId,
      projectName: audioForUpload.project!.name,
      organizationId: audioForUpload.organizationId,

      durationInSeconds: dur == null? 0: dur.inSeconds,
      audioId: audioForUpload.audioId);

  await _addAudio(audio, url, token);
  await cacheManager.removeUploadedAudio(audio: audioForUpload);

  return responseUrl;
}

Future<String> _uploadVideoFile(
    {required String objectName,
      required String url,
      required String token,
      required int height,
      required int width,
      required String mJson,
      required double distance}) async {

  pp('$xx 🍐🍐🍐🍐🍐🍐 _uploadVideoFile: objectName: $objectName url: $url');

  var map = json.decode(mJson);
  var videoForUpload = VideoForUpload.fromJson(map);
  var mPath = videoForUpload.filePath;
  var tPath = videoForUpload.thumbnailPath;
  //create multipart request for POST or PATCH method
  String responseUrl = await _sendRequest(token, url, objectName, mPath!);
  String thumbUrl =
  await _sendRequest(token, url, 'thumb_$objectName', tPath!);
  pp('🍐🍐🍐🍐🍐🍐 attempt to add video to DB ...');
  await _getVideoMetadata(videoForUpload: videoForUpload, videoUrl: responseUrl);

  var video = Video(
      url: responseUrl,
      userUrl: videoForUpload.userThumbnailUrl,
      caption: 'tbd',
      created: videoForUpload.date,
      userId: videoForUpload.userId,
      userName: videoForUpload.userName,
      projectPosition: videoForUpload.position!,
      distanceFromProjectPosition: distance,
      projectId: videoForUpload.project!.projectId,
      thumbnailUrl: thumbUrl,
      projectName: videoForUpload.project!.name,
      organizationId: videoForUpload.organizationId,
      height: videoForUpload.height,
      width: videoForUpload.width,
      durationInSeconds: videoForUpload.durationInSeconds,
      projectPositionId: videoForUpload.projectPositionId,
      projectPolygonId: videoForUpload.projectPolygonId,
      videoId: videoForUpload.videoId);

  await _addVideo(video, url, token);
  await cacheManager.removeUploadedVideo(video: videoForUpload);

  return responseUrl;
}

VideoPlayerController? _videoPlayerController;
var videoHeight = 0.0;
var videoWidth = 0.0;
var videoDurationInSeconds = 0;
var videoDurationInMinutes = 0.0;

Future _getVideoMetadata(
    {required VideoForUpload videoForUpload, required String videoUrl}) async {
  pp('$xx _processVideo:  ... ️💛️💛 getting duration .... ');

  try {
    _videoPlayerController = VideoPlayerController.network(videoUrl);
    if (_videoPlayerController != null) {
      pp('\n\n$xx _processVideo:  ... ️💛️💛 videoPlayerController!.initialize .... ');
      await _videoPlayerController!.initialize();
      pp('$xx _processVideo: doing shit with videoController ... getting duration .... '
          ' 🍎DURATION: ${_videoPlayerController!.value.duration} seconds!');

      var size = _videoPlayerController?.value.size;
      videoHeight = size!.height;
      videoWidth = size.width;
      pp('$xx  size of video ... ️💛️💛 '
          'videoHeight: $videoHeight videoWidth: $videoWidth .... ');
      if (_videoPlayerController != null) {
        videoDurationInSeconds =
            _videoPlayerController!.value.duration.inSeconds;

        videoForUpload.durationInSeconds = videoDurationInSeconds;
        videoForUpload.height = videoHeight;
        videoForUpload.width = videoWidth;
      }
    }
  } catch (e) {
    pp('\n\n$xx _processVideo:  ... we down with the video controller, Boss? could not get metadata : $e \n');
  }
}

Future<Photo> _addPhoto(Photo photo, String url, String token) async {
  try {
    var result = await _callPost('${url}addPhoto', photo.toJson(), token);
    pp('\n\n\n$xx 🔴🔴🔴  addPhoto succeeded. Everything OK?? 🔴🔴🔴');
    var photoBack = Photo.fromJson(result);
    await cacheManager.addPhoto(photo: photoBack);
    pp(' addPhoto has added photo to DB and to Hive cache\n');
    return photo;
  } catch (e) {
    pp(
        '\n\n\n$xx 🔴🔴🔴  addPhoto failed. Something fucked up here! ... 🔴🔴🔴\n\n');
    pp(e);
    rethrow;
  }
}

Future<Video> _addVideo(Video video, String url, String token) async {
  try {
    var result = await _callPost('${url}addVideo', video.toJson(), token);
    pp('\n\n\n$xx 🔴🔴🔴  addVideo succeeded. Everything OK?? 🔴🔴🔴');
    var videoBack = Video.fromJson(result);
    await cacheManager.addVideo(video: videoBack);
    pp('$xx addVideo has added video to DB and to Hive cache\n');
    return video;
  } catch (e) {
    pp(
        '\n\n\n$xx 🔴🔴🔴  addVideo failed. Something fucked up here! ... 🔴🔴🔴\n\n');
    pp(e);
    rethrow;
  }
}

Future<Audio> _addAudio(Audio audio, String url, String token) async {
  try {
    var result = await _callPost('${url}addAudio', audio.toJson(), token);
    pp('\n\n\n$xx 🔴🔴🔴  addAudio succeeded. Everything OK?? 🔴🔴🔴');
    var audioBack = Audio.fromJson(result);
    await cacheManager.addAudio(audio: audioBack);
    pp('$xx addAudio has added audio to DB and to Hive cache\n');
    return audio;
  } catch (e) {
    pp(
        '\n\n\n$xx 🔴🔴🔴  addAudio failed. Something fucked up here! ... 🔴🔴🔴\n\n');
    pp(e);
    rethrow;
  }
}
Future _callPost(String mUrl, Map? bag, String token) async {
  pp('$xx http POST call: 🔆 🔆 🔆  calling : 💙  $mUrl  💙 ');
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
      throw Exception(
          '🚨 🚨 Status Code 🚨 ${resp.statusCode} 🚨 ${resp.body}');
    }
    var end = DateTime.now();
    pp('$xx http POST call: 🔆 elapsed time: ${end.difference(start).inSeconds} seconds 🔆 \n\n');
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

const xx = '😡😡😡 Isolate :  😡😡😡';



Future<String> _sendRequest(
    String token, String url, String objectName, String path) async {
  Map<String, String> headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token'
  };

  var mUrl = '${url}uploadFile';
  var request = http.MultipartRequest("POST", Uri.parse(mUrl));
  //add text fields
  request.fields["objectName"] = objectName;
  //create multipart using filepath, string or bytes
  var pic = await http.MultipartFile.fromPath("document", path);
  //add multipart to request
  request.files.add(pic);
  request.headers.addAll(headers);

  var response = await request.send();
  var responseData = await response.stream.toBytes();
  var responseString = String.fromCharCodes(responseData);

  return responseString;
}
