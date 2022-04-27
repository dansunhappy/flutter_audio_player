import 'dart:io';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_audio_player_platform_interface/audio_data_source.dart';
import 'package:flutter_audio_player_platform_interface/flutter_audio_player_platform_interface.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerWindows extends AudioPlayerPlatform {
  static AudioPlayerWindows instance = AudioPlayerWindows();

  static void registerWith() {
    print('====sss register');
    AudioPlayerPlatform.instance = instance;
  }

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
  @override
  Future<void> init() async {
    DartVLC.initialize();
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
            AudioDataSource audioDataSource = _covertMediaToAudioDataSource(_player.current.media ?? Media.asset(''));
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

  @override
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

  @override
  Future<void> play() async {
    return _player.play();
  }

  @override
  Future<void> pause() async {
    return _player.pause();
  }

  @override
  ValueStream<bool> get playlistFinished {
    return _playlistFinished.stream;
  }

  @override
  ValueStream<bool> get isPlaying {
    return _isPlaying.stream;
  }

  @override
  ValueStream<AudioDataSource?> get current {
    return _current.stream;
  }

  @override
  Stream<AudioPlayerState> get playerState {
    return _playerState.stream;
  }

  @override
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

  @override
  Stream<AudioDataSource?> get onReadyToPlay {
    return _onReadyToPlay.stream;
  }

  @override
  Future<void> setPlaySpeed(double playSpeed) async {
    return _player.setRate(playSpeed);
  }

  @override
  Future<void> seek(Duration to) async {
    return _player.seek(to);
  }

  @override
  ValueStream<double> get playSpeed {
    return _playSpeed.stream;
  }

  @override
  ValueStream<double> get volume {
    return _volume.stream;
  }

  @override
  Future<void> stop() async {
    _playerState.add(AudioPlayerState.stop);
    _player.stop();
  }

  @override
  ValueStream<bool> get isBuffering {
    return _isBuffering.stream;
  }

  @override
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
