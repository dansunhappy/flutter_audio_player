// You have generated a new plugin project without
// specifying the `--platforms` flag. A plugin project supports no platforms is generated.
// To add platforms, run `flutter create -t plugin --platforms <platforms> .` under the same
// directory. You can also find a detailed instruction on how to add platforms in the `pubspec.yaml` at https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'dart:async';
import 'dart:io' if (dart.library.io) 'dart:io' if (dart.library.html) 'dart:html';

import 'package:flutter_audio_player_platform_interface/audio_data_source.dart';
import 'package:flutter_audio_player_platform_interface/flutter_audio_player_platform_interface.dart';
import 'package:flutter_audio_player_platform_interface/method_channel_audio_player.dart';
import 'package:flutter_audio_player_windows/flutter_audio_player_windows.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayer {
  AudioPlayer._();

  factory AudioPlayer() {
    return _instance ??= AudioPlayer._();
  }

  late AudioPlayerPlatform _audioPlayerPlatform;
  static AudioPlayer? _instance;
  Completer? _initCompleter;

  Future<void> init() async {
    _audioPlayerPlatform = Platform.isWindows ? AudioPlayerWindows() : MethodChannelAudioPlayer();
    await _audioPlayerPlatform.init();
    _initCompleter = Completer();
  }

  Future<void> open(AudioSource dataSource) {
    _audioPlayerPlatform.onReadyToPlay.listen((event) {
      if (!_initCompleter!.isCompleted) {
        _initCompleter?.complete();
      }
    });
    return _audioPlayerPlatform.open(dataSource);
  }

  Future<void> setPlaySpeed(double playSpeed) {
    return _audioPlayerPlatform.setPlaySpeed(playSpeed);
  }

  Future<void> play() {
    return _audioPlayerPlatform.play();
  }

  Future<void> pause() {
    return _audioPlayerPlatform.pause();
  }

  Future<void> stop() {
    return _audioPlayerPlatform.stop();
  }

  Future<void> seek(Duration to) {
    return _audioPlayerPlatform.seek(to);
  }

  ValueStream<double> get playSpeed {
    return _audioPlayerPlatform.playSpeed;
  }

  ValueStream<double> get volume {
    return _audioPlayerPlatform.volume;
  }

  ValueStream<bool> get isBuffering {
    return _audioPlayerPlatform.isBuffering;
  }

  ValueStream<bool> get isPlaying {
    return _audioPlayerPlatform.isPlaying;
  }

  ValueStream<bool> get playlistFinished {
    return _audioPlayerPlatform.playlistFinished;
  }

  Stream<AudioPlayerState> get playerState {
    return _audioPlayerPlatform.playerState;
  }

  ValueStream<Duration> get currentPosition {
    return _audioPlayerPlatform.currentPosition;
  }

  Stream<AudioDataSource?> get onReadyToPlay {
    return _audioPlayerPlatform.onReadyToPlay;
  }

  ValueStream<AudioDataSource?> get current {
    return _audioPlayerPlatform.current;
  }

  Future<void> dispose() async {
    if (_initCompleter != null) {
      await _initCompleter?.future;
      _initCompleter = null;
      await _audioPlayerPlatform.dispose();
    }
  }
}
