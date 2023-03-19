import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart' as wv;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geo_monitor/library/api/prefs_og.dart';
import 'package:geo_monitor/library/bloc/geo_uploader.dart';
import 'package:geo_monitor/library/cache_manager.dart';
import 'package:geo_monitor/ui/audio/recording_controls.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:uuid/uuid.dart';

import '../../device_location/device_location_bloc.dart';
import '../../l10n/translation_handler.dart';
import '../../library/bloc/audio_for_upload.dart';
import '../../library/data/position.dart';
import '../../library/data/project.dart';
import '../../library/data/settings_model.dart';
import '../../library/data/user.dart';
import '../../library/functions.dart';
import '../../library/generic_functions.dart';

class AudioHandler extends StatefulWidget {
  const AudioHandler({Key? key, required this.project, required this.onClose})
      : super(key: key);

  final Project project;
  final Function onClose;
  @override
  AudioHandlerState createState() => AudioHandlerState();
}

class AudioHandlerState extends State<AudioHandler>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final mm = '🔆🔆🔆🔆🔆🔆 AudioHandlerMobile: 🔆 ';
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
  String? mBytesTransferred, title;
  bool fileUploadComplete = false;

  late Stream<Uint8List> audioStream;
  late StreamController<List<double>> audioFFT;
  File? _recordedFile;
  int fileSize = 0;
  int seconds = 0;
  String? fileUploadSize, uploadAudioClipText, elapsedTime;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this);
    super.initState();
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
    if (settingsModel != null) {
      var m = settingsModel?.maxAudioLengthInMinutes;
      limitInSeconds = m! * 60;
      title = await mTx.translate('recordAudioClip', settingsModel!.locale!);
      fileUploadSize = await mTx.translate('fileSize', settingsModel!.locale!);
      uploadAudioClipText =
          await mTx.translate('uploadAudioClip', settingsModel!.locale!);
      elapsedTime = await mTx.translate('elapsedTime', settingsModel!.locale!);
    }

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
    pp('\n\n$mm ........... stop recording NOW! ...\n\n');
    if (_timer != null) {
      _timer?.cancel();
    }
    try {
      final path = await _recorderController.stop();
      if (path != null) {
        _recordedFile = File(path);
        fileSize = (await _recordedFile?.length())!;
        pp('$mm _waveController stopped : 🍎🍎🍎 path: $path');
        pp('$mm _waveController stopped : 🍎🍎🍎 size: $fileSize bytes');
      }
    } catch (e) {
      pp('$mm problem with stop ... falling down: $e');
      showToast(
          backgroundColor: Theme.of(context).primaryColor,
          message: 'Recording is a little bit off ...',
          context: context);
    }

    pp('$mm stopped; setting isStopped to TRUE .......');
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
      AudioPlayer audioPlayer = AudioPlayer();
      var dur = await audioPlayer.setFilePath(_recordedFile!.path);
      // var bytes = await _recordedFile!.readAsBytes();
      var audioForUpload = AudioForUpload(
          fileBytes: null,
          userName: user!.name,
          userThumbnailUrl: user!.thumbnailUrl,
          userId: user!.userId,
          organizationId: user!.organizationId,
          filePath: _recordedFile!.path,
          project: widget.project,
          position: position,
          durationInSeconds: dur == null ? 0 : dur.inSeconds,
          audioId: const Uuid().v4(),
          date: DateTime.now().toUtc().toIso8601String());

      await cacheManager.addAudioForUpload(audio: audioForUpload);
      geoUploader.manageMediaUploads();

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
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            backgroundColor: Colors.pink,
          ),
        ),
      );
    } else {
      return ScreenTypeLayout(
        mobile: SafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: Text(title == null ? 'Record Audio' : title!),
            ),
            body: AudioCardAnyone(
              projectName: widget.project.name!,
              elapsedTime: elapsedTime == null ? 'Elapsed Time' : elapsedTime!,
              fileUploadSize:
                  fileUploadSize == null ? 'File Size' : fileUploadSize!,
              uploadAudioClipText: uploadAudioClipText == null
                  ? 'Upload Audio Clip'
                  : uploadAudioClipText!,
              user: user!,
              seconds: seconds,
              recorderController: _recorderController,
              onUploadFile: _uploadFile,
              fileSize: fileSize.toDouble(),
              onPlay: _onPlay,
              onPause: _onPause,
              onRecord: _onRecord,
              onStop: _onStop,
              recordedFile: _recordedFile,
              onClose: () {
                widget.onClose();
              },
            ),
          ),
        ),
        tablet: AudioCardAnyone(
          projectName: widget.project.name!,
          elapsedTime: elapsedTime == null ? 'Elapsed Time' : elapsedTime!,
          fileUploadSize:
              fileUploadSize == null ? 'File Size' : fileUploadSize!,
          uploadAudioClipText:
              uploadAudioClipText == null ? 'Upload Audio Clip' : uploadAudioClipText!,
          user: user!,
          seconds: seconds,
          recorderController: _recorderController,
          onUploadFile: _uploadFile,
          onPlay: _onPlay,
          onPause: _onPause,
          onRecord: _onRecord,
          onStop: _onStop,
          fileSize: fileSize.toDouble(),
          recordedFile: _recordedFile,
          onClose: () {
            widget.onClose();
          },
        ),
      );
    }
  }
}

class AudioCardAnyone extends StatefulWidget {
  const AudioCardAnyone(
      {Key? key,
      required this.projectName,
      required this.user,
      required this.seconds,
      required this.recorderController,
      required this.onUploadFile,
      this.recordedFile,
      required this.fileSize,
      required this.onPlay,
      required this.onPause,
      required this.onStop,
      required this.onRecord,
      required this.onClose,
      required this.fileUploadSize,
      required this.uploadAudioClipText,
      required this.elapsedTime})
      : super(key: key);

  final String projectName;
  final User user;
  final int seconds;
  final wv.RecorderController recorderController;
  final Function onUploadFile;
  final File? recordedFile;
  final double fileSize;
  final Function onPlay, onPause, onStop, onRecord, onClose;
  final String fileUploadSize, uploadAudioClipText, elapsedTime;

  @override
  State<AudioCardAnyone> createState() => _AudioCardAnyoneState();
}

class _AudioCardAnyoneState extends State<AudioCardAnyone> {
  bool isStopped = false,
      isUploading = false,
      isRecording = false,
      isPlaying = false,
      isPaused = false,
      showUpload = false, showWave = false;

  @override
  void initState() {
    super.initState();
  }

  void _onPause() {
    setState(() {
      showUpload = false;
      showWave = false;
    });
    widget.onPause();
  }
  void _onPlay() {
    setState(() {
      showUpload = false;
      showWave = false;
    });
    widget.onPlay();
  }
  void _onStop() {
    setState(() {
      showUpload = true;
      showWave = false;
    });
    widget.onStop();
  }
  void _onRecord() {
    setState(() {
      showUpload = false;
      showWave = true;
    });
    widget.onRecord();
  }

  @override
  Widget build(BuildContext context) {
    var deviceType = getThisDeviceType();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          elevation: 1,
          shape: getRoundedBorder(radius: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                deviceType == 'phone'
                    ? const SizedBox()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                              onPressed: () {
                                widget.onClose();
                              },
                              icon: const Icon(Icons.close)),
                        ],
                      ),
                const SizedBox(
                  height: 20,
                ),
                Text(
                  widget.projectName,
                  style: myTextStyleMediumPrimaryColor(context),
                ),
                const SizedBox(
                  height: 24,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    widget.user.thumbnailUrl == null
                        ? const SizedBox()
                        : CircleAvatar(
                            backgroundImage:
                                NetworkImage(widget.user.thumbnailUrl!),
                            radius: 20,
                          ),
                    const SizedBox(
                      width: 16,
                    ),
                    Text(
                      '${widget.user.name}',
                      style: myTextStyleSmall(context),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 24,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TimerCard(
                      seconds: widget.seconds,
                      elapsedTime: widget.elapsedTime,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 24,
                ),
                showWave
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          shape: getRoundedBorder(radius: 12),
                          elevation: 8,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: wv.AudioWaveforms(
                              size: const Size(300.0, 80.0),
                              recorderController: widget.recorderController,
                              enableGesture: true,
                              waveStyle: wv.WaveStyle(
                                waveColor: Theme.of(context).primaryColor,
                                durationStyle: myTextStyleSmall(context),
                                showDurationLabel: true,
                                waveThickness: 6.0,
                                spacing: 8.0,
                                showBottom: false,
                                extendWaveform: true,
                                showMiddleLine: true,
                              ),
                            ),
                          ),
                        ),
                      ):const SizedBox(),
                showUpload
                    ? SizedBox(
                        height: 280,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Card(
                            elevation: 4,
                            shape: getRoundedBorder(radius: 16),
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 20,
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      widget.fileUploadSize,
                                      style: myTextStyleSmall(context),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Text((widget.fileSize / 1024 / 1024)
                                        .toStringAsFixed(2)),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    const Text('MB'),
                                  ],
                                ),
                                const SizedBox(
                                  height: 48,
                                ),
                                isUploading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 4,
                                          backgroundColor: Theme.of(context)
                                              .primaryColorDark,
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: () {
                                          widget.onUploadFile();
                                        },
                                        child: SizedBox(
                                          width: 220.0,
                                          child: Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                widget.uploadAudioClipText,
                                                style: myTextStyleSmallBold(
                                                    context),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ))
                    : const SizedBox(),
                const SizedBox(
                  height: 16,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: RecordingControls(
                    onPlay: _onPlay,
                    onPause: _onPause,
                    onStop: _onStop,
                    onRecord: _onRecord,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
