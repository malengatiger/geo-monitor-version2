import 'dart:async';
import 'dart:io';
import 'dart:math';
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
  Random rand = Random(DateTime.now().millisecondsSinceEpoch);
  final photoStorageName = 'geoPhotos';
  final videoStorageName = 'geoVideos';

  void startTimer(Duration duration) {
    _timer = Timer.periodic(duration, (timer) async {
      pp('\n\n$mm ......... Timer tick:  🍎 ${timer.tick} 🍎 at: '
          '${DateTime.now().toIso8601String()}');
      await uploadFailedMedia();
    });
    isStarted = true;
  }

  void stopTimer() {
    if (isStarted) {
      _timer.cancel();
    }
  }

  Future uploadFailedMedia() async {
    pp('$mm start uploading failed media to cloud storage .....');
    var bags = await cacheManager.getFailedBags();
    var failedAudios = await cacheManager.getFailedAudios();
    if (bags.isEmpty) {
      pp('$mm no photos or videos need rescuing for cloud storage! ✅✅✅');
    }
    if (failedAudios.isEmpty) {
      pp('$mm no audio needs rescuing for cloud storage! ✅✅✅');
    }

    pp('$mm will upload ${bags.length} file/thumbnails pairs .....');
    for (var bag in bags) {
      if (bag.filePath != null) {
        File file = File(bag.filePath!);
        File thumbnailFile = File(bag.thumbnailPath!);
        pp('$mm file length ${await file.length()} '
            'thumbnail length: ${await thumbnailFile.length()} path: ${file.path} thumb: ${thumbnailFile.path}');
        if (file.path.contains('photo')) {
          var result = await cloudStorageBloc.uploadPhoto(
              listener: this,
              file: file,
              thumbnailFile: thumbnailFile,
              project: bag.project!,
              projectPosition: bag.projectPosition!);
          if (result == 0) {
            await cacheManager.removeFailedBag(bag: bag);
          }
        }
        if (file.path.contains('video')) {
          var result =await cloudStorageBloc.uploadVideo(
              listener: this,
              file: file,
              thumbnailFile: thumbnailFile,
              project: bag.project!,
              projectPosition: bag.projectPosition!);

          if (result == 0) {
            await cacheManager.removeFailedBag(bag: bag);
          }
        }


      }

    }
    //audio
    for (var failedAudio in failedAudios) {
      if (failedAudio.filePath != null) {
        File file = File(failedAudio.filePath!);
        pp('$mm file length ${await file.length()} ');
        var result = await cloudStorageBloc.uploadAudio(
            listener: this,
            file: file,
            project: failedAudio.project!,
            projectPosition: failedAudio.projectPosition!);
        if (result == 0) {
          await cacheManager.removeFailedAudio(failedAudio: failedAudio);
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
    pp('$mm File transfer complete:  ${E.leaf} '
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
