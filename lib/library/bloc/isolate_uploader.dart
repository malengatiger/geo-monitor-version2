import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:geo_monitor/library/bloc/photo_for_upload.dart';
import 'package:geo_monitor/library/bloc/uploader.dart';

import '../functions.dart';

final IsolateUploader isolateUploader = IsolateUploader();

class IsolateUploader {
  static const mm = '🌎🌎🌎🌎🌎🌎IsolateUploader: ';

  ///start isolate to upload media ...
  Future<void> start() async {
    DartPluginRegistrant.ensureInitialized();
    pp('\n\n$mm starting ...');

    await doExpensiveWorkInBackground();
  }

  Future<int> doExpensiveWorkInBackground() async {
    pp('🌎🌎🌎🌎🌎🌎 starting doExpensiveWorkInBackground inside Isolate ...');
    DartPluginRegistrant.ensureInitialized();
    flutterIsolate = await FlutterIsolate.spawn(startUploader, "uploader");

    return 0;

    // var msg = '🌎🌎🌎🌎🌎🌎Done uploading media';
    // return await flutterCompute((message) => startUploader(), msg);
  }
}
late FlutterIsolate flutterIsolate;
@pragma('vm:entry-point')
void startUploader(String msg) async {
  pp('🌎🌎🌎🌎🌎🌎 starting startUploader inside Isolate ... $msg');

  await uploader.uploadPhotos();
  await uploader.uploadAudios();
  await uploader.uploadVideos();

  pp('\n\n🌎🌎🌎🌎🌎🌎Uploader done inside Isolate, needs to be killed? ...');
  flutterIsolate.kill();
  // Isolate.exit();
  // return;
}

void uploadPhoto(PhotoForUpload pfl) {
  //todo - use http for uploads
  File f = File(pfl.filePath!);
  Uint8List bytes = f.readAsBytesSync();
}
