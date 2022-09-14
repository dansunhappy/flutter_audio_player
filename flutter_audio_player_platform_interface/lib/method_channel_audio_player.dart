import 'dart:async';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter_audio_player_platform_interface/flutter_audio_player_platform_interface.dart';
import 'package:rxdart/rxdart.dart';

import 'audio_data_source.dart';

class MethodChannelAudioPlayer extends AudioPlayerPlatform {
  static MethodChannelAudioPlayer instance = MethodChannelAudioPlayer();
  int _textureCounter = 1000;
  final Map<int, _MethodAudioPlayer> _audioPlayers = <int, _MethodAudioPlayer>{};
  static void registerWith() {
    AudioPlayerPlatform.instance = instance;
  }

  @override
  Future<int> init() async {
    final int textureId = _textureCounter;
    _textureCounter++;
    _MethodAudioPlayer _audioPlayer = _MethodAudioPlayer(textureId);
    _audioPlayer.init();
    _audioPlayers[textureId] = _audioPlayer;
    return textureId;
  }

  @override
  Future<void> dispose(int textureId) async {
    await _audioPlayers[textureId]?.dispose();
    return;
  }

  @override
  Future<void> play(int textureId) async {
    return _audioPlayers[textureId]?.play();
  }

  @override
  Future<void> open(AudioSource dataSource, int textureId) async {
    return _audioPlayers[textureId]?.open(dataSource);
  }

  @override
  Future<void> seek(Duration to, int textureId) async {
    return _audioPlayers[textureId]?.seek(to);
  }

  @override
  ValueStream<AudioDataSource?>? current(int textureId) {
    return _audioPlayers[textureId]?.current;
  }

  @override
  ValueStream<bool>? playlistFinished(int textureId) {
    return _audioPlayers[textureId]?.playlistFinished;
  }

  @override
  ValueStream<double>? playSpeed(int textureId) {
    return _audioPlayers[textureId]?.playSpeed;
  }

  @override
  ValueStream<double>? volume(int textureId) {
    return _audioPlayers[textureId]?.volume;
  }

  @override
  ValueStream<bool>? isBuffering(int textureId) {
    return _audioPlayers[textureId]?.isBuffering;
  }

  @override
  ValueStream<bool>? isPlaying(int textureId) {
    return _audioPlayers[textureId]?.isPlaying;
  }

  @override
  ValueStream<Duration>? currentPosition(int textureId) {
    return _audioPlayers[textureId]?.currentPosition;
  }

  @override
  Stream<AudioPlayerState>? playerState(int textureId) {
    return _audioPlayers[textureId]?.playerState;
  }

  @override
  Stream<AudioDataSource?>? onReadyToPlay(int textureId) {
    return _audioPlayers[textureId]?.onReadyToPlay;
  }

  @override
  Future<void> pause(int textureId) async {
    return _audioPlayers[textureId]?.pause();
  }

  @override
  Future<void> stop(int textureId) async {
    return _audioPlayers[textureId]?.stop();
  }

  @override
  Future<void> setPlaySpeed(double playSpeed, int textureId) async {
    return _audioPlayers[textureId]?.setPlaySpeed(playSpeed);
  }
}

class _MethodAudioPlayer {
  _MethodAudioPlayer(this.textureId);
  final int textureId;
  late AssetsAudioPlayer audioPlayer;
  final BehaviorSubject<AudioDataSource> _current = BehaviorSubject<AudioDataSource>();
  final BehaviorSubject<AudioDataSource> _onReadyPlay = BehaviorSubject<AudioDataSource>();

  void init() {
    audioPlayer = AssetsAudioPlayer.withId(textureId.toString());
    audioPlayer.current.listen((event) {
      _current.add(
        _covertPlayingAudioToAudioDataSource(event?.audio ?? PlayingAudio(audio: Audio(''))),
      );
    });
    audioPlayer.onReadyToPlay.listen((event) {
      _onReadyPlay.add(_covertPlayingAudioToAudioDataSource(event ?? PlayingAudio(audio: Audio(''))));
    });
  }

  Future<void> open(AudioSource dataSource) {
    Playable audio = Playable();
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

  Future<void> play() {
    return audioPlayer.play();
  }

  Future<void> pause() {
    return audioPlayer.pause();
  }

  Future<void> stop() {
    return audioPlayer.stop();
  }

  Future<void> setPlaySpeed(double playSpeed) {
    return audioPlayer.setPlaySpeed(playSpeed);
  }

  Future<void> seek(Duration to) {
    return audioPlayer.seek(to);
  }

  ValueStream<double> get playSpeed {
    return audioPlayer.playSpeed;
  }

  ValueStream<double> get volume {
    return audioPlayer.volume;
  }

  ValueStream<bool> get isBuffering {
    return audioPlayer.isBuffering;
  }

  ValueStream<Duration> get currentPosition {
    return audioPlayer.currentPosition;
  }

  ValueStream<bool>? get isPlaying => audioPlayer.isPlaying;

  ValueStream<bool>? get playlistFinished {
    return audioPlayer.playlistFinished;
  }

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

  ValueStream<AudioDataSource?> get current {
    return _current.stream;
  }

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

  Future<void> dispose() async {
    audioPlayer.dispose();
    await _current.close();
    return;
  }
}
