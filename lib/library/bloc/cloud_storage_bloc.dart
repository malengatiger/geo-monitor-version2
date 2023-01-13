import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:path_provider/path_provider.dart';

import 'package:uuid/uuid.dart';

import '../api/data_api.dart';
import '../api/sharedprefs.dart';
import '../data/position.dart';
import '../data/user.dart';
import '../data/video.dart';
import '../emojis.dart';
import '../functions.dart';
import '../location/loc_bloc.dart';
import '../data/city.dart';
import '../data/community.dart';
import '../data/condition.dart';
import '../data/field_monitor_schedule.dart';
import '../data/monitor_report.dart';
import '../data/org_message.dart';
import '../data/organization.dart';
import '../data/photo.dart';
import '../data/project.dart';
import '../data/project_position.dart';
import '../data/section.dart';
import '../data/user.dart';
import '../data/video.dart';

final CloudStorageBloc cloudStorageBloc = CloudStorageBloc();

class CloudStorageBloc {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  Random rand = Random(DateTime.now().millisecondsSinceEpoch);
  static const mm = '☕️☕️☕️☕️☕️☕️ CloudStorageBloc: 💚 ';
  final List<StorageMediaBag> _mediaBags = [];
  final StreamController<List<StorageMediaBag>> _mediaStreamController =
      StreamController.broadcast();
  Stream<List<StorageMediaBag>> get mediaStream =>
      _mediaStreamController.stream;

  User? _user;

  close() {
    _mediaStreamController.close();
  }

  // ignore: missing_return

  final photoStorageName = 'geoPhotos';
  final videoStorageName = 'geoVideos';
  final StreamController<Photo> _photoStreamController =
      StreamController.broadcast();
  Stream<Photo> get photoStream => _photoStreamController.stream;
  late StorageBlocListener storageBlocListener;

  void uploadPhotoOrVideo(
      {required StorageBlocListener listener,
      required File file,
      required File thumbnailFile,
      required Project project,
      required Position projectPosition,
      required bool isVideo,
      String? projectPositionId,
      String? projectPolygonId,
      required bool isLandscape}) async {
    pp('\n\n\n$mm️ uploadPhotoOrVideo ☕️ file path: ${file.path} - isLandscape: $isLandscape');
    storageBlocListener = listener;
    rand = Random(DateTime.now().millisecondsSinceEpoch);
    var name = '';
    if (isVideo) {
      name =
          'video@${project.projectId}@${DateTime.now().toUtc()
              .toIso8601String()}.${'mp4'}';
    } else {
      name =
          'photo@${project.projectId}@${DateTime.now().toUtc()
              .toIso8601String()}.${'jpg'}';
    }
    try {
      pp('$mm️ uploadPhotoOrVideo ☕️ file path: ${file.path}');
      var storageName = '';
      if (isVideo) {
        storageName = videoStorageName;
      } else {
        storageName = photoStorageName;
      }
      var firebaseStorageRef =
          FirebaseStorage.instance.ref().child(storageName).child(name);
      var uploadTask = firebaseStorageRef.putFile(file);

      _reportProgress(uploadTask, listener);

      uploadTask.whenComplete(() => null).then((snapShot) async {
        var totalByteCount = snapShot.totalBytes;
        var bytesTransferred = snapShot.bytesTransferred;
        var bt = '${(bytesTransferred / 1024).toStringAsFixed(2)} KB';
        var tot = '${(totalByteCount / 1024).toStringAsFixed(2)} KB';
        pp('$mm main uploadTask: 💚💚 '
            'photo or video upload complete '
            ' 🧩 $bt of $tot 🧩 transferred.'
            ' date: ${DateTime.now().toIso8601String()}\n');

        var fileUrl = await firebaseStorageRef.getDownloadURL();
        pp('$mm️ uploadPhotoOrVideo ☕️ file url from cloud storage: '
            '\n${Emoji.appleRed} $fileUrl ${Emoji.appleRed} ');

        await _uploadThumbnail(
            listener: listener,
            file: file,
            type: 'jpg',
            thumbnailFile: thumbnailFile,
            position: projectPosition,
            isVideo: isVideo,
            fileUrl: fileUrl,
            projectPositionId: projectPositionId,
            projectPolygonId: projectPolygonId,
            project: project,
            isLandscape: isLandscape);

        pp('$mm File upload and database write should be complete');
        listener.onFileUploadComplete(
            fileUrl, snapShot.totalBytes, snapShot.bytesTransferred);
      }).catchError((e) {
        pp(e);
        listener.onError('👿👿👿👿 Something is not good, Boss! : $e 👿👿👿👿');
      });
    } catch (e) {
      pp('👿👿👿👿 Photo upload failed: $e');
      pp(e);
      listener.onError('👿👿👿👿 Houston, we have a problem $e');
    }
    return null;
  }

  void _reportProgress(UploadTask uploadTask, StorageBlocListener listener) {
    uploadTask.snapshotEvents.listen((event) {
      var totalByteCount = event.totalBytes;
      var bytesTransferred = event.bytesTransferred;
      var bt = '${(bytesTransferred / 1024).toStringAsFixed(2)} KB';
      var tot = '${(totalByteCount / 1024).toStringAsFixed(2)} KB';
      pp('️$mm _reportProgress:  💚 progress ******* 🧩 $bt KB of $tot KB 🧩 transferred');
      listener.onFileProgress(event.totalBytes, event.bytesTransferred);
    });
  }

  Future<String?> _uploadThumbnail(
      {required StorageBlocListener listener,
      required File file,
      required File thumbnailFile,
      required type,
      required Project project,
      required Position position,
      required bool isVideo,
      String? projectPositionId,
      String? projectPolygonId,
      required String fileUrl,
      required bool isLandscape}) async {
    rand = Random(DateTime.now().millisecondsSinceEpoch);
    var name =
        'thumb@${project.projectId}@${DateTime.now().toUtc().toIso8601String()}.$type';
    String thumbnailUrl;

    try {
      final size = ImageSizeGetter.getSize(FileInput(thumbnailFile));
      pp('$mm _uploadThumbnail: 💚image height: ${size.height} width: ${size.width}');
      pp('$mm uploadThumbnail ☕️file path: ${thumbnailFile.path} - isLandscape: $isLandscape');
      var storageName = '';
      if (isVideo) {
        storageName = videoStorageName;
      } else {
        storageName = photoStorageName;
      }
      var firebaseStorageRef =
          FirebaseStorage.instance.ref().child(storageName).child(name);
      var uploadTask = firebaseStorageRef.putFile(thumbnailFile);
      thumbnailProgress(uploadTask, listener);

      uploadTask.whenComplete(() => null).then((snap) async {
        var totalByteCount = snap.totalBytes;
        var bytesTransferred = snap.bytesTransferred;
        var bt = '${(bytesTransferred / 1024).toStringAsFixed(2)} KB';
        var tot = '${(totalByteCount / 1024).toStringAsFixed(2)} KB';

        pp('$mm uploadTask: 🥦🥦 '
            'thumbnail upload complete '
            ' 🍓 $bt of $tot 🍓 transferred.'
            ' ${DateTime.now().toIso8601String()}\n\n');

        thumbnailUrl = await firebaseStorageRef.getDownloadURL();
        pp('$mm uploadThumbnail:  🥦🥦 thumbnailUrl from cloud storage: $thumbnailUrl');
        listener.onThumbnailUploadComplete(
            thumbnailUrl, snap.totalBytes, snap.bytesTransferred);

        if (isVideo) {
          _writeVideo(
              project: project,
              projectPosition: position,
              projectPositionId: projectPositionId,
              projectPolygonId: projectPolygonId,
              fileUrl: fileUrl,
              thumbnailUrl: thumbnailUrl);
        } else {
          _writePhoto(
              project: project,
              projectPosition: position,
              fileUrl: fileUrl,
              thumbnailUrl: thumbnailUrl,
              projectPositionId: projectPositionId,
              projectPolygonId: projectPolygonId,
              height: size.height,
              width: size.width,
              isLandscape: isLandscape);
        }

        var mediaBag = StorageMediaBag(
            url: fileUrl,
            thumbnailUrl: thumbnailUrl,
            isVideo: isVideo,
            file: file,
            date: getFormattedDate(DateTime.now().toString()),
            thumbnailFile: thumbnailFile);

        _mediaBags.add(mediaBag);
        pp('$mm 🍇 uploadTask.whenComplete: 💙💙 mediaStream: '
            '......... sending result of upload in mediaBag to stream: '
            '🍇 ${_mediaBags.length} 🍇 mediaBags in stream\n\n');
        _mediaStreamController.sink.add(_mediaBags);
      }).catchError((e) {
        pp(e);
        listener.onError('👿👿👿👿 thumbnail upload failed: $e');
      });
    } catch (e) {
      pp(e);
      listener.onError('👿👿👿👿 Houston, fuck! we have a problem $e');
    }
    return null;
  }

  void _addVideoBagToStream(
      {required String fileUrl,
      required File file,
      required Project project,
      required String projectPositionId,
      required Position position}) {
    var mediaBag = StorageMediaBag(
      url: fileUrl,
      thumbnailUrl: '',
      isVideo: true,
      file: file,
      date: getFormattedDate(DateTime.now().toString()),
    );

    _mediaBags.add(mediaBag);
    pp('\n\n🍇🍇🍇🍇 uploadTask.whenComplete: 🇿🇦 💙💙 💙💙 💙💙 mediaStream: '
        '......... Sending result of upload in mediaBag to stream: '
        '🍇 ${_mediaBags.length} 🍇 mediaBags in stream\n\n');
    _mediaStreamController.sink.add(_mediaBags);
    _writeVideo(
        project: project,
        projectPosition: position,
        fileUrl: fileUrl,
        projectPositionId: projectPositionId,
        thumbnailUrl: 'not available');
  }

  void thumbnailProgress(UploadTask uploadTask, StorageBlocListener listener) {
    uploadTask.snapshotEvents.listen((event) {
      var totalByteCount = event.totalBytes;
      var bytesTransferred = event.bytesTransferred;
      var bt = '${(bytesTransferred / 1024).toStringAsFixed(2)} KB';
      var tot = '${(totalByteCount / 1024).toStringAsFixed(2)} KB';
      pp('$mm️ .uploadThumbnail:  🥦 progress ******* 🍓 $bt KB of $tot KB 🍓 transferred');
      listener.onThumbnailProgress(event.totalBytes, event.bytesTransferred);
    });
  }

  void _writePhoto(
      {required Project project,
      required Position projectPosition,
      required String fileUrl,
      required String thumbnailUrl,
      String? projectPositionId,
      String? projectPolygonId,
      required int height,
      required int width,
      required bool isLandscape}) async {
    pp('\n🎽🎽🎽🎽 StorageBloc: _writePhoto : 🎽 🎽 adding photo - isLandscape: $isLandscape');
    if (_user == null) {
      await getUser();
    }

    var distance = await locationBloc.getDistanceFromCurrentPosition(
        latitude: projectPosition.coordinates[1],
        longitude: projectPosition.coordinates[0]);

    pp('🎽🎽🎽🎽 StorageBloc: _writePhoto : 🎽🎽 adding photo ..... 😡😡 distance: $distance 😡😡 isLandscape: $isLandscape');
    var u = const Uuid();

    var photo = Photo(
        url: fileUrl,
        caption: 'tbd',
        created: DateTime.now().toIso8601String(),
        userId: _user!.userId,
        userName: _user!.name,
        projectPosition: projectPosition,
        distanceFromProjectPosition: distance,
        projectId: project.projectId,
        thumbnailUrl: thumbnailUrl,
        projectName: project.name,
        organizationId: _user!.organizationId,
        height: height,
        width: width,
        projectPositionId: projectPositionId,
        projectPolygonId: projectPolygonId,
        photoId: u.v4(),
        landscape: isLandscape ? 0 : 1);

    var result = await DataAPI.addPhoto(photo);
    _photoStreamController.sink.add(photo);
    pp('🎽🎽🎽🎽 🎁 🎁 StorageBloc: Photo has been added to database, result photo: 🎁 $result - 🎁 isLandscape: $isLandscape');
    pp('🎽🎽🎽🎽 🎁 🎁 StorageBloc: Photo has been added to photoStream ...');
  }

  void _writeVideo(
      {required Project project,
      required Position projectPosition,
      String? projectPositionId,
      String? projectPolygonId,
      required String fileUrl,
      required String thumbnailUrl}) async {
    pp('🎽🎽🎽🎽 StorageBloc: _writeVideo : 🎽🎽 adding video .....');
    if (_user == null) {
      await getUser();
    }
    var distance = await locationBloc.getDistanceFromCurrentPosition(
        latitude: projectPosition.coordinates[1],
        longitude: projectPosition.coordinates[0]);

    pp('🎽🎽🎽🎽 StorageBloc: _writeVideo : 🎽🎽 adding video ..... 😡😡 distance: $distance 😡😡');
    var u = const Uuid();
    var video = Video(
        url: fileUrl,
        caption: 'tbd',
        created: DateTime.now().toIso8601String(),
        userId: _user!.userId,
        userName: _user!.name,
        projectPosition: projectPosition,
        distanceFromProjectPosition: distance,
        projectId: project.projectId,
        thumbnailUrl: thumbnailUrl,
        projectName: project.name,
        projectPositionId: projectPositionId,
        projectPolygonId: projectPolygonId,
        organizationId: _user!.organizationId,
        videoId: u.v4());

    var result = await DataAPI.addVideo(video);
    pp('🎽🎽🎽🎽 🎁 🎁 Video has been added to database: 🎁 $result');
    storageBlocListener.onVideoReady(video);
  }

  Future<File> downloadFile(String url) async {
    pp('🌿🌿🌿🌿🌿🌿🌿 : downloadFile: 😡😡😡 $url ....');
    final http.Response response =
        await http.get(Uri.parse(url)).catchError((e) {
      pp('😡😡😡 Download failed: 😡😡😡 $e');
      throw Exception('😡😡😡 Download failed: $e');
    });

    pp('🌿🌿🌿🌿🌿🌿🌿 : downloadFile: OK?? 💜💜💜💜'
        '  statusCode: ${response.statusCode}');

    if (response.statusCode == 200) {
      final Directory directory = await getApplicationDocumentsDirectory();
      var type = 'jpg';
      if (url.contains('mp4')) {
        type = 'mp4';
      }
      final File mFile = File(
          '${directory.path}/download${DateTime.now().millisecondsSinceEpoch}.$type');
      pp('🌿🌿🌿🌿🌿🌿🌿 : downloadFile: 💜  .... new file: ${mFile.path}');
      mFile.writeAsBytesSync(response.bodyBytes);
      var len = await mFile.length();
      pp('🌿🌿🌿🌿🌿🌿🌿 : downloadFile: 💜  .... file downloaded length: 😡 '
          '${(len / 1024).toStringAsFixed(1)} KB - path: ${mFile.path}');
      return mFile;
    } else {
      pp('🌿🌿🌿🌿🌿🌿🌿 : downloadFile: Download failed: 😡😡😡 statusCode ${response.statusCode} 😡 ${response.body} 😡');
      throw Exception('Download failed: statusCode: ${response.statusCode}');
    }
  }

  // ignore: missing_return
  Future<int> deleteFolder(String folderName) async {
    pp('.deleteFolder ######## deleting $folderName');
    var task = _firebaseStorage.ref().child(folderName).delete();
    await task.then((f) {
      pp('.deleteFolder $folderName deleted from FirebaseStorage');
      return 0;
    }).catchError((e) {
      pp('.deleteFolder ERROR $e');
      return 1;
    });
    return 0;
  }

  // ignore: missing_return
  Future<int> deleteFile(String folderName, String name) async {
    pp('.deleteFile ######## deleting $folderName : $name');
    var task = _firebaseStorage.ref().child(folderName).child(name).delete();
    task.then((f) {
      pp('.deleteFile $folderName : $name deleted from FirebaseStorage');
      return 0;
    }).catchError((e) {
      pp('.deleteFile ERROR $e');
      return 1;
    });
    return 0;
  }

  CloudStorageBloc() {
    pp('🍇 🍇 🍇 🍇 🍇 StorageBloc constructor 🍇 🍇 🍇 🍇 🍇');
    getUser();
  }
  Future? getUser() async {
    _user = await Prefs.getUser();
    return _user;
  }
}

abstract class StorageBlocListener {
  onFileProgress(int totalByteCount, int bytesTransferred);
  onFileUploadComplete(String url, int totalByteCount, int bytesTransferred);

  onThumbnailProgress(int totalByteCount, int bytesTransferred);
  onThumbnailUploadComplete(
      String url, int totalByteCount, int bytesTransferred);

  onVideoReady(Video video);

  onError(String message);
}

class StorageMediaBag {
  String url, thumbnailUrl, date;
  bool isVideo;
  File? file;
  File? thumbnailFile;

  StorageMediaBag(
      {required this.url,
      required this.file,
      required this.thumbnailUrl,
      required this.isVideo,
      this.thumbnailFile,
      required this.date});
}

const uploadBusy = 201;
const uploadFinished = 200;
const uploadError = 500;
