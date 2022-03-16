import 'dart:async';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter_audio_player_platform_interface/flutter_audio_player_platform_interface.dart';
import 'package:rxdart/rxdart.dart';

import 'audio_data_source.dart';

class MethodChannelAudioPlayer extends AudioPlayerPlatform {
  late AssetsAudioPlayer audioPlayer;
  final BehaviorSubject<AudioDataSource> _current = BehaviorSubject<AudioDataSource>();
  final BehaviorSubject<AudioDataSource> _onReadyPlay = BehaviorSubject<AudioDataSource>();
  @override
  Future<void> init() async {
    audioPlayer = AssetsAudioPlayer.withId('SINGLE_PLAYER');
  }

  @override
  Future<void> open(AudioSource dataSource) {
    Playable audio = Playable();
    audioPlayer.current.listen((event) {
      _current.add(
        _covertPlayingAudioToAudioDataSource(event?.audio ?? PlayingAudio(audio: Audio(''))),
      );
    });
    audioPlayer.onReadyToPlay.listen((event) {
      _onReadyPlay.add(_covertPlayingAudioToAudioDataSource(event ?? PlayingAudio(audio: Audio(''))));
    });
    if (dataSource is AudioDataSource && dataSource.audioSourceType == AudioSourceType.audio) {
      audio = _covertAudioDataSourceToAudio(dataSource);
    } else if (dataSource is AudioPlaylist) {
      audio = Playlist(
        audios: dataSource.playList.map(_covertAudioDataSourceToAudio).toList(),
      );
    }

    return audioPlayer.open(
      audio,
      playInBackground: PlayInBackground.disabledPause,
    );
  }

  @override
  Future<void> play() {
    return audioPlayer.play();
  }

  @override
  Future<void> pause() {
    return audioPlayer.pause();
  }

  @override
  Future<void> stop() {
    return audioPlayer.stop();
  }

  @override
  Future<void> setPlaySpeed(double playSpeed) {
    return audioPlayer.setPlaySpeed(playSpeed);
  }

  @override
  Future<void> seek(Duration to) {
    return audioPlayer.seek(to);
  }

  @override
  ValueStream<double> get playSpeed {
    return audioPlayer.playSpeed;
  }

  @override
  ValueStream<double> get volume {
    return audioPlayer.volume;
  }

  @override
  ValueStream<bool> get isBuffering {
    return audioPlayer.isBuffering;
  }

  @override
  ValueStream<Duration> get currentPosition {
    return audioPlayer.currentPosition;
  }

  @override
  ValueStream<bool> get isPlaying => audioPlayer.isPlaying;

  @override
  ValueStream<bool> get playlistFinished => audioPlayer.playlistFinished;

  @override
  Stream<AudioPlayerState> get playerState {
    return audioPlayer.playerState.transform(StreamTransformer<PlayerState, AudioPlayerState>.fromHandlers(handleData: (data, sink) {
      AudioPlayerState event = AudioPlayerState.unknown;
      switch (data) {
        case PlayerState.play:
          event = AudioPlayerState.play;
          break;
        case PlayerState.pause:
          event = AudioPlayerState.pause;
          break;
        case PlayerState.stop:
          event = AudioPlayerState.stop;
          break;
      }
      sink.add(event);
    }));
  }

  @override
  ValueStream<AudioDataSource?> get current {
    return _current.stream;
  }

  @override
  Stream<AudioDataSource?> get onReadyToPlay {
    // print('audioPlayer.onReadyToPlay.runtimeType ${audioPlayer.onReadyToPlay.listen((event) {
    //   print('sssss ${event.toString()}');
    // })}');

    return _onReadyPlay.stream;
  }

  AudioDataSource _covertPlayingAudioToAudioDataSource(PlayingAudio audio) {
    AudioDataSource audioDataSource;
    switch (audio.audio.audioType) {
      case AudioType.asset:
        audioDataSource = AudioDataSource.asset(audio.audio.path, playSpeed: audio.audio.playSpeed, duration: audio.duration);
        break;
      case AudioType.network:
        audioDataSource = AudioDataSource.network(audio.audio.path, playSpeed: audio.audio.playSpeed, duration: audio.duration);
        break;
      case AudioType.file:
        audioDataSource = AudioDataSource.file(audio.audio.path, playSpeed: audio.audio.playSpeed, duration: audio.duration);
        break;
      case AudioType.liveStream:
        audioDataSource = AudioDataSource.liveStream(audio.audio.path, playSpeed: audio.audio.playSpeed, duration: audio.duration);
        break;
    }

    return audioDataSource;
  }

  Audio _covertAudioDataSourceToAudio(AudioDataSource dataSource) {
    Audio audio;

    switch (dataSource.audioDataSourceType) {
      case AudioDataSourceType.asset:
        audio = Audio(
          dataSource.path,
          package: dataSource.package,
          playSpeed: dataSource.playSpeed,
        );
        break;
      case AudioDataSourceType.file:
        audio = Audio.file(
          dataSource.path,
          playSpeed: dataSource.playSpeed,
        );
        break;
      case AudioDataSourceType.network:
        audio = Audio.network(
          dataSource.path,
          playSpeed: dataSource.playSpeed,
        );
        break;
      case AudioDataSourceType.liveStream:
        audio = Audio.liveStream(
          dataSource.path,
          playSpeed: dataSource.playSpeed,
        );
        break;
    }

    return audio;
  }

  @override
  Future<void> dispose() async {
    audioPlayer.dispose();
    await _current.close();
    return super.dispose();
  }
}
