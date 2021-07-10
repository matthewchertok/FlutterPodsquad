import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/OtherSpecialViews/AudioPlayer.dart';
import 'package:record/record.dart';

class AudioRecorder extends StatefulWidget {
  const AudioRecorder({Key? key}) : super(key: key);

  @override
  _AudioRecorderState createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  final _audioRecorder = Record();
  bool _isRecording = false;
  String? _recordingPath;
  int _recordDuration = 0;
  Timer? _timer;
  Timer? _ampTimer;
  Amplitude? _amplitude;

  /// Start recording
  void _startRecording() async {
    print("STARTING");
    try {
      print("C'mon man");
      if (await this._audioRecorder.hasPermission()) {
        print("YAY");
        await this._audioRecorder.start();
        bool isRecording = await this._audioRecorder.isRecording();
        setState(() {
          this._isRecording = _isRecording;
          _isRecording = isRecording;
          _recordDuration = 0;
        });
        print("RECORDING AUDIO");
        _startTimer();
      } else {
        final alert = CupertinoAlertDialog(
          title: Text("Permissions Error"),
          content: Text("You must "
              "accept microphone permissions to record audio."),
          actions: [
            CupertinoButton(
                child: Text("OK"),
                onPressed: () {
                  dismissAlert(context: context);
                })
          ],
        );
        showCupertinoDialog(context: context, builder: (context) => alert);
      }
    } catch (e) {
      print(e);
    }
  }

  /// Stop recording
  void _stopRecording() async {
    _timer?.cancel();
    _ampTimer?.cancel();
    this._recordingPath = await this._audioRecorder.stop();
    bool isRecording = await _audioRecorder.isRecording();
    setState(() {
      _isRecording = false;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _ampTimer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
      if(_recordDuration >= 30) _stopRecording(); // don't allow recordings longer than 30 seconds
    });

    _ampTimer = Timer.periodic(const Duration(milliseconds: 200), (Timer t) async {
      _amplitude = await _audioRecorder.getAmplitude();
      setState(() {});
    });
  }

  Widget _buildText() {
    if (_isRecording) {
      return _buildTimer();
    }
    return Text("Waiting to record");
  }

  Widget _buildTimer() {
    final String minutes = _formatNumber(_recordDuration ~/ 60);
    final String seconds = _formatNumber(_recordDuration % 60);

    return Text(
      '$minutes : $seconds',
      style: TextStyle(color: CupertinoColors.systemRed),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0' + numberStr;
    }

    return numberStr;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ampTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // if there's no recording, show a record button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (this._recordDuration == 0 && !this._isRecording)
                CupertinoButton(
                    child: Icon(
                      CupertinoIcons.smallcircle_fill_circle,
                      color: CupertinoColors.systemRed,
                    ),
                    onPressed: _startRecording),
              if (this._isRecording)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // stop recording button
                    CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Icon(
                          CupertinoIcons.stop_circle,
                          color: CupertinoColors.systemRed,
                        ),
                        onPressed: _stopRecording),
                    Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: _buildText(),
                    ) // timer
                  ],
                )
            ],
          ),

          if (this._recordDuration > 0 && !this._isRecording)
            Container(
              width: 180,
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                      child: AudioPlayer(
                    localFilePath: this._recordingPath,
                  )),
                  CupertinoButton(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.smallcircle_fill_circle,
                            color: CupertinoColors.systemRed,
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Record\nAgain",
                            style: TextStyle(fontSize: 12, color: CupertinoColors.black.withOpacity(0.6)),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ),
                      onPressed: _startRecording)
                ],
              ),
            )
        ],
      ),
    );
  }
}
