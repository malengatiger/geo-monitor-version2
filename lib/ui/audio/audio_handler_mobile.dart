import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart' as wv;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/data/audio.dart';
import 'package:geo_monitor/library/hive_util.dart';
import 'package:geo_monitor/ui/audio/recording_controls.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../device_location/device_location_bloc.dart';
import '../../library/bloc/audio_for_upload.dart';
import '../../library/bloc/cloud_storage_bloc.dart';
import '../../library/data/position.dart';
import '../../library/data/project.dart';
import '../../library/data/settings_model.dart';
import '../../library/data/user.dart';
import '../../library/data/video.dart';
import '../../library/functions.dart';
import '../../library/generic_functions.dart';
import '../dashboard/dashboard_mobile.dart';

class AudioHandlerMobile extends StatefulWidget {
  const AudioHandlerMobile({Key? key, required this.project}) : super(key: key);

  final Project project;
  @override
  AudioHandlerMobileState createState() => AudioHandlerMobileState();
}

class AudioHandlerMobileState extends State<AudioHandlerMobile>
    with SingleTickerProviderStateMixin
    implements StorageBlocListener {
  late AnimationController _animationController;

  final mm = '🔆🔆🔆🔆 AudioMobile: ';
  Timer? _timer;
  final _audioRecorder = Record();
  StreamSubscription<RecordState>? _recordSub;
  StreamSubscription<Amplitude>? _amplitudeSub;
  final wv.RecorderController _recorderController = wv.RecorderController(); //
  late StreamSubscription<String> killSubscription;

  AudioPlayer player = AudioPlayer();
  List<StreamSubscription> streams = []; // Initialise
  bool isAudioPlaying = false;
  bool isUploading = false;
  User? user;
  static const int bufferSize = 2048;
  static const int sampleRate = 44100;
  bool isRecording = false;
  bool isPaused = false;
  bool isStopped = false;
  String? mTotalByteCount;
  String? mBytesTransferred;
  bool fileUploadComplete = false;

  late Stream<Uint8List> audioStream;
  late StreamController<List<double>> audioFFT;
  File? _recordedFile;
  int fileSize = 0;
  int seconds = 0;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this);
    super.initState();
    killSubscription = listenForKill(context: context);
    _getSettings();
    _getUser();
    player.playerStateStream.listen((event) {
      if (event.playing) {
        pp('$mm AudioPlayer is playing');
        if (mounted) {
          setState(() {
            isAudioPlaying = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isAudioPlaying = false;
          });
        }
      }
    });
  }

  void _getSettings() async {
    settingsModel = await prefsOGx.getSettings();
    var m = settingsModel?.maxAudioLengthInMinutes;
    limitInSeconds = m! * 60;
    setState(() {});
  }

  void _getUser() async {
    user = await prefsOGx.getUser();
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    _recorderController.dispose();
    _animationController.dispose();
    killSubscription.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      seconds = t.tick;
      if (mounted) {
        setState(() {});
      }
    });
  }

  SettingsModel? settingsModel;
  int limitInSeconds = 60;
  _onRecord() async {
    pp('$mm start recording ...');

    try {
      setState(() {
        _recordedFile = null;
        mTotalByteCount = null;
        mBytesTransferred = null;
      });
      final Directory directory = await getApplicationDocumentsDirectory();
      final File mFile = File(
          '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.mp4');

      _recorderController.refresh();
      if (await _recorderController.checkPermission()) {
        await _recorderController.record(path: mFile.path);
        _startTimer();
        _recorderController.addListener(() {
          if (_recorderController.recorderState.name == 'recording') {
            //ignore
          } else {
            pp('$mm _waveController.recorderState.name: 🔆 ${_recorderController.recorderState.name}');
          }
          switch (_recorderController.recorderState.name) {
            case 'recording':
              if (mounted) {
                setState(() {
                  isRecording = true;
                  isPaused = false;
                  isStopped = false;
                });
              }
              break;
            case 'paused':
              if (mounted) {
                setState(() {
                  isRecording = false;
                  isPaused = true;
                  isStopped = false;
                });
              }
              break;
            case 'stopped':
              if (mounted) {
                setState(() {
                  isRecording = false;
                  isPaused = false;
                  isStopped = true;
                });
              }
              break;
          }
        });
      }
    } catch (e) {
      pp(e);
    }
  }

  _onPlay() async {
    if (_recordedFile == null) {
      return;
    }
    pp('$mm ......... start playing ...');

    player.setFilePath(_recordedFile!.path);
    await player.play();
  }

  _onPause() async {
    pp('$mm pause recording ...');
    _timer?.cancel();
    await _recorderController.pause();
    setState(() {
      isPaused = true;
      isRecording = false;
      isStopped = false;
    });
  }

  _onStop() async {
    pp('$mm stop recording ...');
    _timer?.cancel();
    final path = await _recorderController.stop();
    if (path != null) {
      _recordedFile = File(path);
      fileSize = (await _recordedFile?.length())!;
      pp('$mm _waveController stopped : 🍎🍎🍎 path: $path');
      pp('$mm _waveController stopped : 🍎🍎🍎 size: $fileSize bytes');
    }
    if (_timer != null) {
      _timer?.cancel();
    }
    setState(() {
      isPaused = false;
      isRecording = false;
      isStopped = true;
    });
  }

  Future<void> _uploadFile() async {
    if (isUploading) {
      return;
    }
    pp('\n\n$mm Start file upload .....................');
    setState(() {
      isUploading = true;
    });
    try {
      Position? position;
      var loc = await locationBloc.getLocation();
      if (loc != null) {
        position =
            Position(coordinates: [loc.longitude, loc.latitude], type: 'Point');
      }
      var audioForUpload = AudioForUpload(
          filePath: _recordedFile!.path,
          project: widget.project,
          position: position,
          audioId: const Uuid().v4(),
          date: DateTime.now().toUtc().toIso8601String());

      await cacheManager.addAudioForUpload(audio: audioForUpload);
      _recordedFile = null;
    } catch (e) {
      pp(e);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }

    setState(() {
      isUploading = false;
    });
  }

  @override
  onFileProgress(int totalByteCount, int bytesTransferred) {
    pp('$mm 🍏file Upload progress: bytesTransferred: ${(bytesTransferred / 1024).toStringAsFixed(1)} KB '
        'of totalByteCount: ${(totalByteCount / 1024).toStringAsFixed(1)} KB');
    setState(() {
      mTotalByteCount =
          '${(totalByteCount / 1024 / 1024).toStringAsFixed(2)} MB';
      mBytesTransferred =
          '${(bytesTransferred / 1024 / 1024).toStringAsFixed(2)} MB';
    });
  }

  @override
  onFileUploadComplete(String url, int totalByteCount, int bytesTransferred) {
    pp('$mm 😡 file Upload has been completed 😡 bytesTransferred: ${(bytesTransferred / 1024).toStringAsFixed(1)} KB '
        'of totalByteCount: ${(totalByteCount / 1024).toStringAsFixed(1)} KB');
    _reset(totalByteCount, bytesTransferred);
    if (mounted) {
      setState(() {
        pp('$mm 😡 file Upload has been completed 😡setting state ...');
      });
      showToast(
          toastGravity: ToastGravity.TOP,
          backgroundColor: Theme.of(context).primaryColor,
          duration: const Duration(seconds: 5),
          padding: 8.0,
          message: 'File upload completed!',
          context: context);
    }
  }

  void _reset(int totalByteCount, int bytesTransferred) {
    isRecording = false;
    isPaused = false;
    isStopped = false;
    fileUploadComplete = true;
    _recordedFile = null;
    seconds = 0;
    isAudioPlaying = false;
    totalByteCount = 0;
    bytesTransferred = 0;
    mTotalByteCount = null;
    mBytesTransferred = null;
    fileSize = 0;
  }

  @override
  onError(String message) {
    pp('$mm onError fired - $message');
    if (mounted) {
      showToast(
          message: message,
          textStyle: const TextStyle(color: Colors.white),
          duration: const Duration(seconds: 3),
          toastGravity: ToastGravity.TOP,
          backgroundColor: Colors.pink,
          context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),
        body: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Card(
                  elevation: 1,
                  shape: getRoundedBorder(radius: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          'Project Audio',
                          style: myTextStyleMedium(context),
                        ),
                        const SizedBox(
                          height: 28,
                        ),
                        Text(
                          '${widget.project.name}',
                          style: myTextStyleLarge(context),
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        user == null
                            ? const SizedBox()
                            : Text(
                                '${user!.name}',
                                style: myTextStyleSmall(context),
                              ),
                        const SizedBox(
                          height: 48,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TimerCard(seconds: seconds),
                          ],
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        isStopped
                            ? const SizedBox()
                            : Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Card(
                                  shape: getRoundedBorder(radius: 16),
                                  elevation: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: wv.AudioWaveforms(
                                      size: const Size(260.0, 80.0),
                                      recorderController: _recorderController,
                                      enableGesture: true,
                                      waveStyle: wv.WaveStyle(
                                        waveColor:
                                            Theme.of(context).primaryColor,
                                        durationStyle:
                                            myTextStyleSmall(context),
                                        showDurationLabel: true,
                                        waveThickness: 6.0,
                                        spacing: 8.0,
                                        showBottom: false,
                                        extendWaveform: true,
                                        showMiddleLine: false,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        _recordedFile == null
                            ? const SizedBox()
                            : SizedBox(
                                height: 200,
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Card(
                                    elevation: 4,
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        isUploading
                                            ? SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 4,
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .primaryColorDark,
                                                ),
                                              )
                                            : ElevatedButton(
                                                onPressed: _uploadFile,
                                                child:
                                                    const Text('Upload File'),
                                              ),
                                        const SizedBox(
                                          height: 16,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'File upload size',
                                              style: myTextStyleSmall(context),
                                            ),
                                            const SizedBox(
                                              width: 8,
                                            ),
                                            Text((fileSize / 1024 / 1024)
                                                .toStringAsFixed(2)),
                                            const SizedBox(
                                              width: 8,
                                            ),
                                            const Text('MB'),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 16,
                                        ),
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
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: RecordingControls(
                  onPlay: _onPlay,
                  onPause: _onPause,
                  onStop: _onStop,
                  onRecord: _onRecord,
                  isRecording: isRecording,
                  isPaused: isPaused,
                  isStopped: isStopped,
                ),
              ),
            ),
            isAudioPlaying
                ? Positioned(
                    bottom: 120,
                    left: 40,
                    right: 40,
                    child: Card(
                      shape: getRoundedBorder(radius: 16),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [Text('Saved audio is playing')],
                        ),
                      ),
                    ))
                : const SizedBox(),
            mTotalByteCount == null
                ? const SizedBox()
                : Positioned(
                    bottom: 100,
                    left: 40,
                    right: 40,
                    child: Card(
                      elevation: 8,
                      shape: getRoundedBorder(radius: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Uploaded ',
                              style: myTextStyleSmall(context),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              '$mBytesTransferred',
                              style: myTextStyleSmall(context),
                            ),
                          ],
                        ),
                      ),
                    )),
          ],
        ),
      ),
    );
  }

  @override
  onVideoReady(Video video) {}

  @override
  onAudioReady(Audio audio) {}
}
