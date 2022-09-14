import 'dart:io';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_audio_player_platform_interface/audio_data_source.dart';
import 'package:flutter_audio_player_platform_interface/flutter_audio_player_platform_interface.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerWindows extends AudioPlayerPlatform {
  static AudioPlayerWindows instance = AudioPlayerWindows();
  int _textureCounter = 1000;
  final Map<int, _AudioPlayer> _audioPlayers = <int, _AudioPlayer>{};
  static void registerWith() {
    DartVLC.initialize();
    AudioPlayerPlatform.instance = instance;
  }

  @override
  Future<int> init() async {
    final int textureId = _textureCounter;
    _textureCounter++;
    _AudioPlayer _audioPlayer = _AudioPlayer(textureId);
    await _audioPlayer.init();
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

class _AudioPlayer {
  _AudioPlayer(this.id);
  final int id;
  late Player _player;

  final BehaviorSubject<Duration> _currentPosition = BehaviorSubject<Duration>.seeded(const Duration());
  final BehaviorSubject<double> _playSpeed = BehaviorSubject.seeded(1.0);

  final BehaviorSubject<double> _volume = BehaviorSubject<double>.seeded(1.0);

  final BehaviorSubject<bool> _isBuffering = BehaviorSubject<bool>.seeded(false);

  //是否在播放
  final BehaviorSubject<bool> _isPlaying = BehaviorSubject<bool>.seeded(false);

  //是否在播放完成
  final BehaviorSubject<bool> _playlistFinished = BehaviorSubject<bool>.seeded(false);

  final BehaviorSubject<AudioDataSource> _current = BehaviorSubject<AudioDataSource>();
  final BehaviorSubject<AudioPlayerState> _playerState = BehaviorSubject<AudioPlayerState>.seeded(AudioPlayerState.unknown);
  final BehaviorSubject<AudioDataSource> _onReadyToPlay = BehaviorSubject<AudioDataSource>();

  late VoidCallback _onListener;
  bool _isReadPlay = false;
  Future<void> init() async {
    _player = Player(id: 9999);
    _player.textureId.addListener(() {});
    _onListener = () {
      _player.playbackStream.listen((event) {
        if (event.isCompleted) {
          if (_player.current.isPlaylist) {
            if (_player.current.index == _player.current.medias.length - 1) {
              _playlistFinished.add(event.isCompleted);
            }
          } else {
            _playlistFinished.add(event.isCompleted);
          }
        }

        AudioPlayerState audioPlayerState;
        if (_player.playback.isPlaying) {
          audioPlayerState = AudioPlayerState.play;
          _isPlaying.add(_player.playback.isPlaying);
        } else {
          audioPlayerState = AudioPlayerState.pause;
          _isReadPlay = false;
        }
        _playerState.add(audioPlayerState);
      });

      _player.generalStream.listen((event) {
        _playSpeed.add(event.rate);
        _volume.add(event.volume);
      });

      _player.positionStream.listen((event) {
        if (_player.playback.isPlaying) {
          if (!_isReadPlay) {
            _player.setVolume(1.0);
            AudioDataSource audioDataSource = _covertMediaToAudioDataSource(
              _player.current.media ?? Media.asset(''),
            );
            _onReadyToPlay.add(audioDataSource);
            _isReadPlay = true;
          }
        }
        _currentPosition.add(event.position ?? Duration.zero);
      });
      _player.bufferingProgressStream.listen((event) {
        _isBuffering.add(!(_player.bufferingProgress == 100));
      });
      _player.currentStream.listen((event) {
        if (event.media != null) {
          _current.add(_covertMediaToAudioDataSource(event.media ?? Media.asset('')));
        }
      });
    };
    _player.textureId.addListener(_onListener);
  }

  Future<void> dispose() async {
    _player.dispose();
    _player.textureId.removeListener(_onListener);
    await _currentPosition.close();
    await _isBuffering.close();
    await _isPlaying.close();
    await _volume.close();
    await _playSpeed.close();
    await _playlistFinished.close();
    await _current.close();
    await _playerState.close();
    await _onReadyToPlay.close();
  }

  Future<void> play() async {
    return _player.play();
  }

  Future<void> pause() async {
    return _player.pause();
  }

  ValueStream<bool> get playlistFinished {
    return _playlistFinished.stream;
  }

  ValueStream<bool> get isPlaying {
    return _isPlaying.stream;
  }

  ValueStream<AudioDataSource?> get current {
    return _current.stream;
  }

  Stream<AudioPlayerState> get playerState {
    return _playerState.stream;
  }

  Future<void> open(AudioSource dataSource) async {
    if (dataSource is AudioDataSource) {
      Media media = _coverAudioDataSourceToMedial(dataSource);
      _player.open(media);
    } else if (dataSource is AudioPlaylist) {
      _player.open(
        Playlist(medias: dataSource.playList.map(_coverAudioDataSourceToMedial).toList()),
      );
    }
  }

  Stream<AudioDataSource?> get onReadyToPlay {
    return _onReadyToPlay.stream;
  }

  Future<void> setPlaySpeed(double playSpeed) async {
    return _player.setRate(playSpeed);
  }

  Future<void> seek(Duration to) async {
    return _player.seek(to);
  }

  ValueStream<double> get playSpeed {
    return _playSpeed.stream;
  }

  ValueStream<double> get volume {
    return _volume.stream;
  }

  Future<void> stop() async {
    _playerState.add(AudioPlayerState.stop);
    _player.stop();
  }

  ValueStream<bool> get isBuffering {
    return _isBuffering.stream;
  }

  ValueStream<Duration> get currentPosition {
    return _currentPosition.stream;
  }

  AudioDataSource _covertMediaToAudioDataSource(Media media) {
    AudioDataSource audioDataSource;
    switch (media.mediaType) {
      case MediaType.asset:
        audioDataSource = AudioDataSource.asset(media.resource, playSpeed: _player.general.rate, duration: _player.position.duration);
        break;
      case MediaType.network:
        audioDataSource = AudioDataSource.network(media.resource,
            playSpeed: _player.general.rate, cached: _player.bufferingProgress == 100, duration: _player.position.duration);
        break;
      case MediaType.file:
        audioDataSource = AudioDataSource.file(media.resource, playSpeed: _player.general.rate, duration: _player.position.duration);
        break;
      case MediaType.directShow:
        audioDataSource = AudioDataSource.network(media.resource,
            playSpeed: _player.general.rate, cached: _player.bufferingProgress == 100, duration: _player.position.duration);
        break;
    }
    return audioDataSource;
  }

  Media _coverAudioDataSourceToMedial(AudioDataSource dataSource) {
    Media media;
    switch (dataSource.audioDataSourceType) {
      case AudioDataSourceType.asset:
        String assetUrl = dataSource.path;
        if (dataSource.package != null && dataSource.package!.isNotEmpty) {
          assetUrl = 'packages/${dataSource.package}/$assetUrl';
        }
        media = Media.asset(assetUrl);
        break;
      case AudioDataSourceType.file:
        media = Media.file(File(dataSource.path));
        break;
      case AudioDataSourceType.liveStream:
      case AudioDataSourceType.network:
        media = Media.network(dataSource.path);
    }
    return media;
  }
}
