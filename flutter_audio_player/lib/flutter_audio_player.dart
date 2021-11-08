// You have generated a new plugin project without
// specifying the `--platforms` flag. A plugin project supports no platforms is generated.
// To add platforms, run `flutter create -t plugin --platforms <platforms> .` under the same
// directory. You can also find a detailed instruction on how to add platforms in the `pubspec.yaml` at https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'dart:io';

import 'package:flutter_audio_player_platform_interface/flutter_audio_player_platform_interface.dart';
import 'package:flutter_audio_player_windows/flutter_audio_player_windows.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayer {
  AudioPlayer._();

  factory AudioPlayer() {
    return _instance ??= AudioPlayer._();
  }

  static AudioPlayerPlatform get _audioPlayerPlatform {
    return Platform.isWindows ? AudioPlayerWindows.instance : AudioPlayerPlatform.instance;
  }

  static AudioPlayer? _instance;

  Future<void> open(AudioDataSource dataSource) {
    return _audioPlayerPlatform.open(dataSource);
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

  ValueStream<double> get playSpeed {
    return _audioPlayerPlatform.playSpeed;
  }

  ValueStream<double> get volume {
    return _audioPlayerPlatform.volume;
  }

  ValueStream<bool> get isBuffering {
    return _audioPlayerPlatform.isBuffering;
  }

  ValueStream<Duration> get currentPosition {
    return _audioPlayerPlatform.currentPosition;
  }

  Stream<AudioDataSource?> get onReadyToPlay {
    return _audioPlayerPlatform.onReadyToPlay;
  }
}
