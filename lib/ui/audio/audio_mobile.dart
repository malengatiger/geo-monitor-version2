import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart' as wv;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_monitor/library/api/sharedprefs.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../library/bloc/cloud_storage_bloc.dart';
import '../../library/data/project.dart';
import '../../library/data/user.dart';
import '../../library/data/video.dart';
import '../../library/functions.dart';
import '../../library/generic_functions.dart';

class AudioMobile extends StatefulWidget {
  const AudioMobile({Key? key, required this.project}) : super(key: key);

  final Project project;
  @override
  AudioMobileState createState() => AudioMobileState();
}

class AudioMobileState extends State<AudioMobile>
    with SingleTickerProviderStateMixin implements StorageBlocListener{
  late AnimationController _animationController;

  final mm = '🔆🔆🔆🔆 AudioMobile: ';
  Timer? _timer;
  final _audioRecorder = Record();
  StreamSubscription<RecordState>? _recordSub;
  StreamSubscription<Amplitude>? _amplitudeSub;
  final wv.RecorderController _recorderController = wv.RecorderController(); //

  AudioPlayer player = AudioPlayer();
  List<StreamSubscription> streams = []; // Initialise
  bool isAudioPlaying = false;
  bool isUploading = false;
  User? user;
  @override
  void initState() {
    _animationController = AnimationController(vsync: this);
    super.initState();
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

  void _getUser() async {
    user = await Prefs.getUser();
    setState(() {

    });
  }
  static const int bufferSize = 2048;
  static const int sampleRate = 44100;

  late Stream<Uint8List> audioStream;
  late StreamController<List<double>> audioFFT;

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
      setState(() => seconds++);
    });
  }

  bool isRecording = false;
  bool isPaused = false;
  bool isStopped = false;

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
    setState(() {
      isPaused = false;
      isRecording = false;
      isStopped = true;
    });
  }

  Future<void> _uploadFile() async {
    pp('\n\n$mm Start file upload .....................');
    setState(() {
      isUploading = true;
    });
    try {
      var result = await cloudStorageBloc.uploadAudio(
          listener: this, file: _recordedFile!, project: widget.project);
      pp('$mm result back from database: $result');
    } catch (e) {
      pp(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }

    setState(() {
      isUploading = false;
    });
  }
  String? mTotalByteCount;
  String? mBytesTransferred;
  @override
  onFileProgress(int totalByteCount, int bytesTransferred) {
    pp('$mm 🍏file Upload progress: bytesTransferred: ${(bytesTransferred / 1024).toStringAsFixed(1)} KB '
        'of totalByteCount: ${(totalByteCount / 1024).toStringAsFixed(1)} KB');
    setState(() {
      mTotalByteCount = '${(totalByteCount / 1024/1024).toStringAsFixed(2)} MB';
      mBytesTransferred =
      '${(bytesTransferred / 1024/1024).toStringAsFixed(2)} MB';
    });
  }

  bool fileUploadComplete = false;
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
          message: 'File upload completed!', context: context);
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
  onThumbnailProgress(int totalByteCount, int bytesTransferred) {
    pp('$mm 🍏thumbnail Upload progress: bytesTransferred: ${(bytesTransferred / 1024).toStringAsFixed(1)} KB '
        'of totalByteCount: ${(totalByteCount / 1024).toStringAsFixed(1)} KB');
  }

  @override
  onThumbnailUploadComplete(
      String url, int totalByteCount, int bytesTransferred) async {
    pp('$mm 🍏thumbnail Upload has been completed 😡 bytesTransferred: ${(bytesTransferred / 1024).toStringAsFixed(1)} KB '
        'of totalByteCount: ${(totalByteCount / 1024).toStringAsFixed(1)} KB');
    setState(() {});
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
  File? _recordedFile;
  int fileSize = 0;
  int seconds = 0;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),
        body: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 1,
                  shape: getRoundedBorder(radius: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                          height: 48,
                        ),
                        Text(
                          '${widget.project.name}',
                          style: myTextStyleLarge(context),
                        ),
                        const SizedBox(
                          height: 28,
                        ),
                        user == null? const SizedBox():Text(
                          '${user!.name}',
                          style: myTextStyleSmall(context),
                        ),
                        const SizedBox(
                          height: 80,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TimerCard(seconds: seconds),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
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
                                        waveColor: Theme.of(context).primaryColor,
                                        durationStyle: myTextStyleSmall(context),
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
                        _recordedFile == null? const SizedBox(): SizedBox(height: 200,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Card(
                              elevation: 4,
                              child: Column(
                                children: [
                                  const SizedBox(height: 20,),

                                  ElevatedButton(
                                    onPressed: _uploadFile,
                                    child: const Text('Upload File'),
                                  ),
                                  const SizedBox(height: 16,),
                                  Row(mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('File upload size', style: myTextStyleSmall(context),),
                                      const SizedBox(width: 8,),
                                      Text((fileSize/1024/1024).toStringAsFixed(2)),
                                      const SizedBox(width: 8,),
                                      const Text('MB'),

                                    ],
                                  ),
                                  const SizedBox(height: 16,),

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
              bottom: 28,
              left: 20,
              right: 20,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: PlayControls(
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
            isAudioPlaying? Positioned(
                bottom: 120, left: 40, right: 40,
                child: Card(
                  shape: getRoundedBorder(radius: 16),
                  elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Saved audio is playing')
                  ],
                ),
              ),
            )) : const SizedBox(),
            mTotalByteCount == null? const SizedBox(): Positioned(
                bottom: 100, left: 40, right: 40,
                child: Card(
                  elevation: 8,
                  shape: getRoundedBorder(radius: 16),
              child: Row(
                children: [
                  Text('Uploaded ', style: myTextStyleSmall(context),),
                  const SizedBox(width: 8,),
                  Text('$mBytesTransferred', style: myNumberStyleSmall(context),),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  onVideoReady(Video video) {
  }
}

class PlayControls extends StatelessWidget {
  const PlayControls(
      {Key? key,
      required this.onPlay,
      required this.onPause,
      required this.onStop,
      required this.onRecord,
      required this.isRecording,
      required this.isPaused,
      required this.isStopped})
      : super(key: key);
  final Function onPlay;
  final Function onPause;
  final Function onStop;
  final Function onRecord;
  final bool isRecording;
  final bool isPaused;
  final bool isStopped;
  @override
  Widget build(BuildContext context) {
    var showRecord = true;
    var showPlay = false;
    var showStop = false;
    var showPause = false;
    //pp('🍎 isRecording: $isRecording 🍎isPaused: $isPaused 🍎isStopped: $isStopped');
    if (!isRecording && !isPaused && !isStopped) {
      pp('🍎 all flags are false; should show the recording icon only');
      showRecord = true;
      showStop = false;
      showPlay = false;
      showPause = false;
    } else {
      if (isRecording) {
        showStop = true;
        showPause = true;
        showRecord = false;
      } else if (isStopped) {
        showStop = true;
        showRecord = true;
        showPlay = true;
      } else if (isPaused) {
        showStop = true;
        showRecord = true;
        showPlay = false;
      }
    }

    return Card(
      elevation: 4,
      shape: getRoundedBorder(radius: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            const SizedBox(
              width: 12,
            ),
            showRecord
                ? IconButton(onPressed: _onRecord, icon:  Icon(Icons.mic, color: Theme.of(context).primaryColor))
                : const SizedBox(),
            const SizedBox(
              width: 32,
            ),
            showPlay
                ? IconButton(
                    onPressed: _onPlayTapped,
                    icon:  Icon(Icons.play_arrow, color: Theme.of(context).primaryColor))
                : const SizedBox(),
            const SizedBox(
              width: 32,
            ),
            showPause
                ? IconButton(
                    onPressed: _onPlayPaused, icon:  Icon(Icons.pause, color: Theme.of(context).primaryColor))
                : const SizedBox(),
            const SizedBox(
              width: 32,
            ),
            showStop
                ? IconButton(
                    onPressed: _onPlayStopped, icon:  Icon(Icons.stop, color: Theme.of(context).primaryColor,))
                : const SizedBox(),
          ],
        ),
      ),
    );
  }

  void _onPlayTapped() {
    onPlay();
  }

  void _onPlayStopped() {
    onStop();
  }

  void _onPlayPaused() {
    onPause();
  }

  void _onRecord() {
    onRecord();
  }
}

class TimerCard extends StatelessWidget {
  const TimerCard({Key? key, required this.seconds}) : super(key: key);
  final int seconds;
  @override
  Widget build(BuildContext context) {
    int h, m, s;
    h = seconds ~/ 3600;
    m = ((seconds - h * 3600)) ~/ 60;
    s = seconds - (h * 3600) - (m * 60);
    String hourLeft = h.toString().length < 2 ? "0$h" : h.toString();
    String minuteLeft = m.toString().length < 2 ? "0$m" : m.toString();
    String secondsLeft = s.toString().length < 2 ? "0$s" : s.toString();

    String result = "$hourLeft:$minuteLeft:$secondsLeft";

    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Text(
              'Elapsed Time:',
              style: myTextStyleSmall(context),
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              '$result ',
              style: GoogleFonts.lato(
                  textStyle: Theme.of(context).textTheme.bodyLarge,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  color: Theme.of(context).primaryColor),
            ),
          ],
        ),
      ),
    );
  }

}
