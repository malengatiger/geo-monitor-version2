import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/data/project.dart';
import 'package:geo_monitor/library/data/settings_model.dart';
import 'package:geo_monitor/library/functions.dart';
import 'package:geo_monitor/ui/activity/user_profile_card.dart';
import 'package:geo_monitor/ui/audio/recording_controls.dart';
import 'package:geo_monitor/ui/visualizer/audio_visualizer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:responsive_builder/responsive_builder.dart';
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
  final void Function() onCloseRequested;

  const AudioRecorder({Key? key, required this.onCloseRequested, required this.project})
      : super(key: key);
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
    _recordSub =
        _audioRecorder.onStateChanged().listen((RecordState recordState) {
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
      elapsedTime,
      title,
      audioToBeUploaded,
      waitingToRecordAudio;
  int limitInSeconds = 0;
  int fileSize = 0;
  void _getUser() async {
    user = await prefsOGx.getUser();
    settingsModel = await prefsOGx.getSettings();
    if (settingsModel != null) {
      var m = settingsModel?.maxAudioLengthInMinutes;
      limitInSeconds = m! * 60;
      title = await mTx.translate('recordAudioClip', settingsModel!.locale!);
      elapsedTime = await mTx.translate('elapsedTime', settingsModel!.locale!);

      fileUploadSize = await mTx.translate('fileSize', settingsModel!.locale!);
      uploadAudioClipText =
          await mTx.translate('uploadAudioClip', settingsModel!.locale!);
      elapsedTime = await mTx.translate('elapsedTime', settingsModel!.locale!);
      locationNotAvailable =
          await mTx.translate('locationNotAvailable', settingsModel!.locale!);

      waitingToRecordAudio =
          await mTx.translate('waitingToRecordAudio', settingsModel!.locale!);
      audioToBeUploaded =
          await mTx.translate('audioToBeUploaded', settingsModel!.locale!);
    }

    setState(() {});
  }

  Future<void> _start() async {
    try {
      setState(() {
        _readyForUpload = false;
      });
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
        File audioFile = File(
            '${directory.path}/zip${DateTime.now().millisecondsSinceEpoch}.mp4');

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
      var length = await fileToUpload?.length();
      pp('$mx onStop: file length: 🍎🍎🍎 $length bytes, ready for upload');
      fileSize = length!;
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
    final theme = Theme.of(context);
    if (_recordState != RecordState.stop) {
      icon = Icon(Icons.stop, color: theme.primaryColor, size: 30);
      color = theme.primaryColorLight.withOpacity(0.1);
    } else {
      icon = Icon(Icons.mic, color: theme.primaryColor, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipOval(
          child: Material(
            color: color,
            child: InkWell(
              child: SizedBox(width: 56, height: 56, child: icon),
              onTap: () {
                (_recordState != RecordState.stop) ? _stop() : _start();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPauseResumeControl() {
    if (_recordState == RecordState.stop) {
      return const SizedBox.shrink();
    }

    late Icon icon;
    late Color color;

    if (_recordState == RecordState.record) {
      icon = Icon(Icons.pause, color: Theme.of(context).primaryColor, size: 30);
      color = Theme.of(context).primaryColor.withOpacity(0.1);
    } else {
      icon = Icon(Icons.play_arrow,
          color: Theme.of(context).primaryColor, size: 30);
      color = Theme.of(context).primaryColor.withOpacity(0.1);
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

  int _seconds = 0;

  void _startTimer() {
    _timer?.cancel();
    _recordDuration = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      _seconds = t.tick;
      setState(() => _recordDuration++);
    });
  }

  bool _readyForUpload = false;

  Future<void> _uploadFile() async {
    pp('\n\n$mx Start file upload .....................');
    setState(() {
      _readyForUpload = false;
    });
    showToast(
        message: audioToBeUploaded == null
            ? 'Audio clip will be uploaded'
            : audioToBeUploaded!,
        context: context,
        textStyle: myTextStyleMediumBold(context),
        padding: 20.0,
        toastGravity: ToastGravity.TOP,
        backgroundColor: Theme.of(context).primaryColor);
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
          filePath: fileToUpload!.path,
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
      _readyForUpload = false;
      _seconds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_amplitude != null) {
      itemBloc.addItem(_amplitude!.current);
    }
    return ScreenTypeLayout(
      mobile: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(title == null ? 'Audio Recording' : title!),
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              shape: getRoundedBorder(radius: 16),
              elevation: 8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Card(
                      shape: getRoundedBorder(radius: 16),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              widget.project.name!,
                              style: myTextStyleLargePrimaryColor(context),
                            ),
                            const SizedBox(
                              height: 48,
                            ),
                            user == null
                                ? const SizedBox()
                                : UserProfileCard(
                                    userName: user!.name!,
                                    userThumbUrl: user!.thumbnailUrl,
                                    avatarRadius: 20.0,
                                    padding: 12.0,
                                    elevation: 4.0,
                                  ),
                            const SizedBox(
                              height: 24,
                            ),
                            _amplitude == null
                                ? const SizedBox()
                                : SizedBox(
                                    height: 120,
                                    child: elapsedTime == null
                                        ? const SizedBox()
                                        : TimerCard(
                                            fontSize: 40,
                                            seconds: _seconds,
                                            elapsedTime: elapsedTime!,
                                          ),
                                  ),
                            const SizedBox(
                              height: 24,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildRecordStopControl(),
                                const SizedBox(width: 48),
                                _buildPauseResumeControl(),
                              ],
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                            _readyForUpload
                                ? Card(
                                    elevation: 2,
                                    shape: getRoundedBorder(radius: 16),
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              fileUploadSize!,
                                              style: myTextStyleSmall(context),
                                            ),
                                            const SizedBox(
                                              width: 8,
                                            ),
                                            Text(
                                              ((fileSize / 1024 / 1024)
                                                  .toStringAsFixed(2)),
                                              style:
                                                  myTextStyleMediumBoldPrimaryColor(
                                                      context),
                                            ),
                                            const SizedBox(
                                              width: 8,
                                            ),
                                            Text(
                                              'MB',
                                              style: myTextStyleSmall(context),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            _uploadFile();
                                          },
                                          child: SizedBox(
                                            width: 240.0,
                                            child: Center(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child:
                                                    uploadAudioClipText == null
                                                        ? const SizedBox()
                                                        : Text(
                                                            uploadAudioClipText!,
                                                            style:
                                                                myTextStyleSmallBold(
                                                                    context),
                                                          ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 16,
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      tablet: Card(
        shape: getRoundedBorder(radius: 16),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                      onPressed: () {
                          widget.onCloseRequested();

                      },
                      icon: const Icon(Icons.close))
                ],
              ),
              Text(
                widget.project.name!,
                style: myTextStyleLargePrimaryColor(context),
              ),
              const SizedBox(
                height: 32,
              ),
              user == null
                  ? const SizedBox()
                  : UserProfileCard(
                      userName: user!.name!,
                      userThumbUrl: user!.thumbnailUrl,
                      avatarRadius: 24.0,
                      padding: 8.0,
                      elevation: 8.0,
                    ),
              const SizedBox(
                height: 24,
              ),
              _amplitude == null
                  ? const SizedBox()
                  : SizedBox(
                      height: 100,
                      child: elapsedTime == null
                          ? const SizedBox()
                          : TimerCard(
                              fontSize: 40,
                              seconds: _seconds,
                              elapsedTime: elapsedTime!,
                            ),
                    ),
              const SizedBox(
                height: 32,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRecordStopControl(),
                  const SizedBox(width: 48),
                  _buildPauseResumeControl(),
                ],
              ),
              // Container(height: 48, color: Colors.pink,),
              const SizedBox(
                height: 32,
              ),
              _readyForUpload
                  ? Card(
                      elevation: 2,
                      shape: getRoundedBorder(radius: 16),
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 16,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                fileUploadSize!,
                                style: myTextStyleSmall(context),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Text(
                                ((fileSize / 1024 / 1024)
                                    .toStringAsFixed(2)),
                                style:
                                    myTextStyleMediumBoldPrimaryColor(
                                        context),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Text(
                                'MB',
                                style: myTextStyleSmall(context),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _uploadFile();
                            },
                            child: SizedBox(
                              width: 240.0,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: uploadAudioClipText == null
                                      ? const SizedBox()
                                      : Text(
                                          uploadAudioClipText!,
                                          style: myTextStyleSmallBold(
                                              context),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
