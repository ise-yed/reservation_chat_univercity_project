import 'dart:async';

import 'package:just_audio/just_audio.dart';


class VoicePlayerManager {
  VoicePlayerManager._internal();
  static final VoicePlayerManager _instance = VoicePlayerManager._internal();
  static VoicePlayerManager get instance => _instance;

  final AudioPlayer _player = AudioPlayer();
  String? _currentUrl;
  Duration _totalDuration = Duration.zero;

  final StreamController<PlayerStateData> _playerStateController =
      StreamController<PlayerStateData>.broadcast();

  Stream<PlayerStateData> get playerStateStream =>
      _playerStateController.stream;
  String? get currentUrl => _currentUrl;
  bool get isPlaying => _player.playing;

  Future<void> init() async {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
      _playerStateController.add(
        PlayerStateData(
          isPlaying: _player.playing,
          processingState: state.processingState,
          duration: _totalDuration,
          position: _player.position,
        ),
      );
    });

    _player.positionStream.listen((position) {
      _playerStateController.add(
        PlayerStateData(
          isPlaying: _player.playing,
          processingState: _player.processingState,
          duration: _totalDuration,
          position: position,
        ),
      );
    });

    _player.durationStream.listen((duration) {
      _totalDuration = duration ?? Duration.zero;
    });
  }

  bool isCurrentUrl(String url) => _currentUrl == url;

  Future<void> play(String url) async {
    if (_currentUrl != url) {
      _currentUrl = url;
      try {
        await _player.setUrl(url);
        _totalDuration = _player.duration ?? Duration.zero;
      } catch (e) {
      }
    }
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void dispose() {
    _player.dispose();
    _playerStateController.close();
  }
}

class PlayerStateData {
  final bool isPlaying;
  final ProcessingState processingState;
  final Duration duration;
  final Duration position;

  PlayerStateData({
    required this.isPlaying,
    required this.processingState,
    required this.duration,
    required this.position,
  });
}
