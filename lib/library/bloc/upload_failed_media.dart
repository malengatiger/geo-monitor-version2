import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';

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
      await _uploadFailedBags();
    });
    isStarted = true;
  }

  void stopTimer() {
    if (isStarted) {
      _timer.cancel();
    }
  }

  Future _uploadFailedBags() async {
    pp('$mm start uploading failed media to cloud storage .....');
    var bags = await hiveUtil.getFailedBags();
    if (bags.isEmpty) {
      pp('$mm no media needs rescuing! ✅✅✅');
      return;
    }

    pp('$mm will upload ${bags.length} file/thumbnails pairs .....');
    for (var bag in bags) {
      File file = File(bag.filePath!);
      File thumbnailFile = File(bag.thumbnailPath!);
      pp('$mm file length ${await file.length()} '
          'thumbnail length: ${await thumbnailFile.length()} path: ${file.path} thumb: ${thumbnailFile.path}');
      Future.delayed(const Duration(seconds: 1), () async {
        pp('$mm starting cloud storage upload after '
            'dithering for 1 seconds ...');
        pp('$mm processing files from project: ${bag.project!.name}');

        try {
          var isOK = await cloudStorageBloc.uploadPhotoOrVideo(
              listener: this,
              file: file,
              thumbnailFile: thumbnailFile,
              project: bag.project!,
              projectPosition: bag.projectPosition!,
              isVideo: bag.isVideo!,
              isLandscape: bag.isLandscape!);

          if (isOK == uploadFinished) {
            pp(
                '$mm ...cloud storage uploads completed! ${DateTime.now()
                    .toIso8601String()}');
          }
        } catch (e) {
          pp(e);
        }
      });
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
  onThumbnailProgress(int totalByteCount, int bytesTransferred) {
    pp('$mm Thumbnail File transferring to cloud storage:  🍎 '
        '$bytesTransferred of $totalByteCount bytes');
  }

  @override
  onThumbnailUploadComplete(
      String url, int totalByteCount, int bytesTransferred) {
    pp('$mm Thumbnail File transfer complete:  ${Emoji.leaf} '
        '$bytesTransferred of $totalByteCount bytes');
    pp('$mm thumbnail url: $url');
  }

  @override
  onVideoReady(Video video) {
    pp('$mm Video is ready, folks!');
  }
}
