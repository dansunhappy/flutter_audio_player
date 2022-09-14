// You have generated a new plugin project without
// specifying the `--platforms` flag. A plugin project supports no platforms is generated.
// To add platforms, run `flutter create -t plugin --platforms <platforms> .` under the same
// directory. You can also find a detailed instruction on how to add platforms in the `pubspec.yaml` at https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'dart:async';
// import 'dart:io' if (dart.library.io) 'dart:io' if (dart.library.html) 'dart:html';

import 'package:flutter/foundation.dart';
import 'package:flutter_audio_player_platform_interface/audio_data_source.dart';
import 'package:flutter_audio_player_platform_interface/flutter_audio_player_platform_interface.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayer {
  AudioPlayer._();

  factory AudioPlayer() {
    return _instance ??= AudioPlayer._();
  }

  late AudioPlayerPlatform _audioPlayerPlatform;
  static AudioPlayer? _instance;
  Completer? _initCompleter;
  late int textureId;

  Future<void> init() async {
    _audioPlayerPlatform = AudioPlayerPlatform.instance;
    textureId = await _audioPlayerPlatform.init();
    _initCompleter = Completer();
  }

  Future<void> open(AudioSource dataSource) {
    _audioPlayerPlatform.onReadyToPlay(textureId)?.listen((event) {
      if (!_initCompleter!.isCompleted) {
        _initCompleter?.complete();
      }
    });
    return _audioPlayerPlatform.open(dataSource, textureId);
  }

  Future<void> setPlaySpeed(double playSpeed) {
    return _audioPlayerPlatform.setPlaySpeed(playSpeed, textureId);
  }

  Future<void> play() {
    return _audioPlayerPlatform.play(textureId);
  }

  Future<void> pause() {
    return _audioPlayerPlatform.pause(textureId);
  }

  Future<void> stop() {
    return _audioPlayerPlatform.stop(textureId);
  }

  Future<void> seek(Duration to) {
    return _audioPlayerPlatform.seek(to, textureId);
  }

  ValueStream<double>? get playSpeed {
    return _audioPlayerPlatform.playSpeed(textureId);
  }

  ValueStream<double>? get volume {
    return _audioPlayerPlatform.volume(textureId);
  }

  ValueStream<bool>? get isBuffering {
    return _audioPlayerPlatform.isBuffering(textureId);
  }

  ValueStream<bool>? get isPlaying {
    return _audioPlayerPlatform.isPlaying(textureId);
  }

  ValueStream<bool>? get playlistFinished {
    return _audioPlayerPlatform.playlistFinished(textureId);
  }

  Stream<AudioPlayerState>? get playerState {
    return _audioPlayerPlatform.playerState(textureId);
  }

  ValueStream<Duration>? get currentPosition {
    return _audioPlayerPlatform.currentPosition(textureId);
  }

  Stream<AudioDataSource?>? get onReadyToPlay {
    return _audioPlayerPlatform.onReadyToPlay(textureId);
  }

  ValueStream<AudioDataSource?>? get current {
    return _audioPlayerPlatform.current(textureId);
  }

  Future<void> dispose() async {
    if (_initCompleter != null) {
      await _initCompleter?.future;
      _initCompleter = null;
      await _audioPlayerPlatform.dispose(textureId);
    }
  }
}
