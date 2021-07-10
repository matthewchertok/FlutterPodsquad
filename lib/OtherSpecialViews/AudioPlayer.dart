import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as player;
import 'package:flutter/cupertino.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

/// To play a file from the database, pass in a URL and leave localFilePath empty. To play a local file, pass in the
/// path to the file and leave audioURL empty.
class AudioPlayer extends StatefulWidget {
  const AudioPlayer({Key? key, this.audioURL = "", this.localFilePath}) : super(key: key);
  final String audioURL;
  final String? localFilePath;

  @override
  _AudioPlayerState createState() => _AudioPlayerState(audioURL: this.audioURL, localFilePath: this.localFilePath);
}

class _AudioPlayerState extends State<AudioPlayer> {
  _AudioPlayerState({required this.audioURL, this.localFilePath});

  final String audioURL;

  /// If I want to play audio from a saved recording instead of from the database, pass this in
  final String? localFilePath;
  final _audioPlayer = player.AudioPlayer();

  /// Keep track of whether audio is playing, paused, or stopped, and update the UI accordingly.
  _AudioStatus _audioStatus = _AudioStatus.stopped;

  ///Play audio
  void play() async {
    // Play from a local file if a value is passed in for localFilePath. Otherwise, play from the database.
    final result = this.localFilePath == null ? await _audioPlayer.play(audioURL, isLocal: false) : await _audioPlayer
        .play(localFilePath!, isLocal: true);
    print("Audio playing!");
    setState(() {
      if (result == 1) this._audioStatus = _AudioStatus.playing;
    });
  }

  /// Pause audio
  void pause() async {
    final result = await _audioPlayer.pause();
    print("Audio paused!");
    setState(() {
      if (result == 1) this._audioStatus = _AudioStatus.paused;
    });
  }

  /// Stop audio
  void stop() async {
    final result = await _audioPlayer.stop();
    print("Audio stopped!");
    setState(() {
      if (result == 1) this._audioStatus = _AudioStatus.stopped;
      this.currentPosition = Duration.zero; // reset the position to the beginning
    });
  }

  /// Resume audio
  void resume() async {
    final result = await _audioPlayer.resume();
    print("Audio resumed!");
    setState(() {
      if (result == 1) this._audioStatus = _AudioStatus.playing;
    });
  }

  /// Seek (skip through) audio
  void seek({required Duration duration}) async {
    await _audioPlayer.seek(duration);
  }

  /// Track the audio position
  Duration currentPosition = Duration.zero;

  /// Track the length of the audio
  Duration audioLength = Duration.zero;

  /// Cancel the subscription when the widget is disposed
  StreamSubscription? audioPositionListener;
  StreamSubscription? audioDurationListener;
  StreamSubscription? audioCompletionListener;

  @override
  void initState() {
    super.initState();
    this.audioPositionListener = _audioPlayer.onAudioPositionChanged.listen((Duration position) {
      setState(() {
        currentPosition = position;
      });
    });

    this.audioDurationListener = _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        print("Audio length is $duration");
        audioLength = duration;
      });
    });

    // Stop audio when it reaches the end
    this.audioCompletionListener = _audioPlayer.onPlayerCompletion.listen((event) {
      stop();
    });
  }

  @override
  void dispose() {
    super.dispose();
    audioPositionListener?.cancel();
    audioDurationListener?.cancel();
    audioCompletionListener?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      /// Contains the play/pause button above a seek bar
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Play/pause/stop buttons
          Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // show a Play button if audio is paused or stopped
              if (_audioStatus != _AudioStatus.playing)
                CupertinoButton(
                    padding: EdgeInsets.fromLTRB(0, 5, 0, 10),
                    child: Icon(CupertinoIcons.play),
                    onPressed: _audioStatus == _AudioStatus.paused ? resume : play),
              // show a Pause button if audio is playing
              if (_audioStatus == _AudioStatus.playing)
                CupertinoButton(padding: EdgeInsets.fromLTRB(0, 5, 0, 10), child: Icon(CupertinoIcons.pause), onPressed: pause),

              // Show a Stop button
              CupertinoButton(padding: EdgeInsets.fromLTRB(0, 5, 0, 10), child: Icon(CupertinoIcons.stop), onPressed: stop)
            ],
          ),

          // Seek slider
          Container(
            child: ProgressBar(
              progress: currentPosition,
              total: audioLength,
              onSeek: (duration) {
                this.seek(duration: duration);
              },
            ),
          )
        ],
      ),
    );
  }
}

/// Determines whether audio is playing, paused, or stopped.
enum _AudioStatus { playing, paused, stopped }
