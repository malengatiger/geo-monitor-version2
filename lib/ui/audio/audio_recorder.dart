import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/data/project.dart';
import 'package:geo_monitor/library/data/settings_model.dart';
import 'package:geo_monitor/library/functions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../device_location/device_location_bloc.dart';
import '../../l10n/translation_handler.dart';
import '../../library/bloc/audio_for_upload.dart';
import '../../library/bloc/geo_uploader.dart';
import '../../library/cache_manager.dart';
import '../../library/data/position.dart';
import '../../library/data/user.dart';
import '../../library/generic_functions.dart';

class AudioRecorder extends StatefulWidget {
  final void Function(String path) onStop;

  const AudioRecorder({Key? key, required this.onStop, required this.project}) : super(key: key);
  final Project project;
  @override
  State<AudioRecorder> createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  int _recordDuration = 0;
  Timer? _timer;
  final _audioRecorder = Record();
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;
  StreamSubscription<Amplitude>? _amplitudeSub;
  Amplitude? _amplitude;
  static const mx = '🍐🍐🍐 AudioRecorder 🍐🍐🍐: ';
  User? user;
  SettingsModel? settingsModel;
  @override
  void initState() {
    _recordSub = _audioRecorder.onStateChanged().listen((RecordState recordState) {
      pp('$mx onStateChanged; record state: $recordState');
      setState(() => _recordState = recordState);
    });

    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amp) {
      // pp('$mx onAmplitudeChanged: amp: 🌀🌀 current: ${amp.current} max: ${amp.max}');
           setState(() {
             _amplitude = amp;
           });
    });

    super.initState();
    _getUser();
  }
  String? fileUploadSize,
      uploadAudioClipText,
      locationNotAvailable,
      elapsedTime, title;
  int limitInSeconds = 0;
  void _getUser() async {
    user = await prefsOGx.getUser();
    settingsModel = await prefsOGx.getSettings();
    if (settingsModel != null) {
      var m = settingsModel?.maxAudioLengthInMinutes;
      limitInSeconds = m! * 60;
      title = await mTx.translate('recordAudioClip', settingsModel!.locale!);
      fileUploadSize = await mTx.translate('fileSize', settingsModel!.locale!);
      uploadAudioClipText =
      await mTx.translate('uploadAudioClip', settingsModel!.locale!);
      elapsedTime = await mTx.translate('elapsedTime', settingsModel!.locale!);
      locationNotAvailable =
      await mTx.translate('locationNotAvailable', settingsModel!.locale!);
    }

    setState(() {});
  }
  Future<void> _start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // We don't do anything with this but printing
        final isSupported = await _audioRecorder.isEncoderSupported(
          AudioEncoder.aacLc,
        );
        if (kDebugMode) {
          pp('$mx ${AudioEncoder.aacLc.name} supported: $isSupported');
        }

        // final devs = await _audioRecorder.listInputDevices();
        // final isRecording = await _audioRecorder.isRecording();
        var directory = await getApplicationDocumentsDirectory();
        pp('$mx _start: 🔆🔆🔆 directory: ${directory.path}');
        File audioFile =
        File('${directory.path}/zip${DateTime.now().millisecondsSinceEpoch}.mp4a');

        await _audioRecorder.start(path: audioFile.path);
        pp('$mx _audioRecorder has started ...');
        _startTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  File? fileToUpload;
  Future<void> _stop() async {
    _timer?.cancel();

    final path = await _audioRecorder.stop();
    pp('$mx onStop: file path: $path');

    if (path != null) {
      fileToUpload = File(path);
      pp('$mx onStop: file length: 🍎🍎🍎 ${await fileToUpload?.length()} bytes, ready for upload');
      //_uploadFile(file);
      //widget.onStop(path);
      setState(() {
        _readyForUpload = true;
      });
    }
  }

  Future<void> _pause() async {
    _timer?.cancel();
    await _audioRecorder.pause();
  }

  Future<void> _resume() async {
    _startTimer();
    await _audioRecorder.resume();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Widget _buildRecordStopControl() {
    late Icon icon;
    late Color color;

    if (_recordState != RecordState.stop) {
      icon = const Icon(Icons.stop, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = Icon(Icons.mic, color: theme.primaryColor, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            (_recordState != RecordState.stop) ? _stop() : _start();
          },
        ),
      ),
    );
  }

  Widget _buildPauseResumeControl() {
    if (_recordState == RecordState.stop) {
      return const SizedBox.shrink();
    }

    late Icon icon;
    late Color color;

    if (_recordState == RecordState.record) {
      icon = const Icon(Icons.pause, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = const Icon(Icons.play_arrow, color: Colors.red, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            (_recordState == RecordState.pause) ? _resume() : _pause();
          },
        ),
      ),
    );
  }

  Widget _buildText() {
    if (_recordState != RecordState.stop) {
      return _buildTimer();
    }

    return const Text("Waiting to record");
  }

  Widget _buildTimer() {
    final String minutes = _formatNumber(_recordDuration ~/ 60);
    final String seconds = _formatNumber(_recordDuration % 60);

    return Text(
      '$minutes : $seconds',
      style: myNumberStyleLargePrimaryColor(context),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }

  void _startTimer() {
    _timer?.cancel();
    _recordDuration = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }

  bool _readyForUpload = false;

  Future<void> _uploadFile(File f) async {

    pp('\n\n$mx Start file upload .....................');
    setState(() {

    });
    try {
      Position? position;
      var loc = await locationBloc.getLocation();
      if (loc != null) {
        position =
            Position(coordinates: [loc.longitude, loc.latitude], type: 'Point');
      } else {
        if (mounted) {
          showToast(message: 'Device Location unavailable', context: context);
          return;
        }
      }
      pp('$mx about to create audioForUpload .... ');
      if (user == null) {
        pp('$mx user is null, WTF!!');
        return;
      }

      var audioForUpload = AudioForUpload(
          fileBytes: null,
          userName: user!.name,
          userThumbnailUrl: user!.thumbnailUrl,
          userId: user!.userId,
          organizationId: user!.organizationId,
          filePath: f.path,
          project: widget.project,
          position: position,
          durationInSeconds: _recordDuration,
          audioId: const Uuid().v4(),
          date: DateTime.now().toUtc().toIso8601String());

      await cacheManager.addAudioForUpload(audio: audioForUpload);
      geoUploader.manageMediaUploads();

    } catch (e) {
      pp("something amiss here: ${e.toString()}");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }

    setState(() {

    });
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Test Audio Recording'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: getRoundedBorder(radius: 16),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    shape: getRoundedBorder(radius: 16),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          _buildRecordStopControl(),
                          const SizedBox(width: 20),
                          _buildPauseResumeControl(),
                          const SizedBox(width: 20),
                          _buildText(),
                        ],
                      ),
                    ),
                  ),
                  if (_amplitude != null) ...[
                    const SizedBox(height: 48),
                    Text('Current: ${_amplitude?.current.toStringAsFixed(8) ?? 0.0}',style: myNumberStyleLargePrimaryColor(context),),
                    Text('Max: ${_amplitude?.max.toStringAsFixed(8) ?? 0.0}', style: myNumberStyleLargePrimaryColor(context),),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
