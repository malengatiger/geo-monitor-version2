import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geo_monitor/library/data/audio.dart';

import '../data/video.dart';
import '../emojis.dart';
import '../functions.dart';
import '../hive_util.dart';
import 'cloud_storage_bloc.dart';

final UploadFailedMedia uploadFailedMedia = UploadFailedMedia();

class UploadFailedMedia implements StorageBlocListener {
  final mm = '️🌿🌿🌿🌿🌿 UploadFailedMedia: 🍎 ';
  late Timer _timer;
  bool isStarted = false;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  Random rand = Random(DateTime.now().millisecondsSinceEpoch);
  final photoStorageName = 'geoPhotos';
  final videoStorageName = 'geoVideos';

  void startTimer(Duration duration) {
    _timer = Timer.periodic(duration, (timer) async {
      pp('\n\n$mm ......... Timer tick:  🍎 ${timer.tick} 🍎 at: '
          '${DateTime.now().toIso8601String()}');
      await uploadFailedBags();
    });
    isStarted = true;
  }

  void stopTimer() {
    if (isStarted) {
      _timer.cancel();
    }
  }

  Future uploadFailedBags() async {
    pp('$mm start uploading failed media to cloud storage .....');
    var bags = await hiveUtil.getFailedBags();
    if (bags.isEmpty) {
      pp('$mm no media needs rescuing! ✅✅✅');
      return;
    }

    pp('$mm will upload ${bags.length} file/thumbnails pairs .....');
    for (var bag in bags) {
      if (bag.filePath != null) {
        File file = File(bag.filePath!);
        File thumbnailFile = File(bag.thumbnailPath!);
        pp('$mm file length ${await file.length()} '
            'thumbnail length: ${await thumbnailFile.length()} path: ${file.path} thumb: ${thumbnailFile.path}');
        if (file.path.contains('photo')) {
          await cloudStorageBloc.uploadPhoto(listener: this,
              file: file,
              thumbnailFile: thumbnailFile,
              project: bag.project!,
              projectPosition: bag.projectPosition!);
        }
        if (file.path.contains('video')) {
          await cloudStorageBloc.uploadVideo(listener: this,
              file: file,
              thumbnailFile: thumbnailFile,
              project: bag.project!,
              projectPosition: bag.projectPosition!);
        }
      }
    }
  }


  @override
  onError(String message) {
    pp('$mm Error: $message');
  }

  @override
  onFileProgress(int totalByteCount, int bytesTransferred) {
    pp('$mm File transferring to cloud storage:  🍎 '
        '$bytesTransferred of $totalByteCount bytes');
  }

  @override
  onFileUploadComplete(String url, int totalByteCount, int bytesTransferred) {
    pp('$mm File transfer complete:  ${Emoji.leaf} '
        '$bytesTransferred of $totalByteCount bytes');
    pp('$mm file url: $url');
  }

  @override
  onVideoReady(Video video) {
    pp('$mm Video is ready, folks!');
  }

  @override
  onAudioReady(Audio audio) {
    pp('$mm Audio is ready, folks!');
  }
}
