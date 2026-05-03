// lib/data/services/audio_player_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../models/track_model.dart';

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  const PositionData({
    required this.position,
    required this.bufferedPosition,
    required this.duration,
  });
}

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  TrackModel? _currentTrack;
  List<TrackModel> _playlist = [];
  StreamSubscription? _completionSub;

  // Callback called when track changes via auto-next
  Function(TrackModel)? onTrackChanged;

  AudioPlayer get player => _player;
  TrackModel? get currentTrack => _currentTrack;
  bool get isPlaying => _player.playing;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<bool> get playingStream => _player.playingStream;

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        (position, buffered, duration) => PositionData(
          position: position,
          bufferedPosition: buffered,
          duration: duration ?? Duration.zero,
        ),
      );

  Future<void> loadTrack(TrackModel track, {List<TrackModel>? playlist}) async {
    _currentTrack = track;
    if (playlist != null) _playlist = playlist;

    await _player.setAudioSource(
      AudioSource.uri(Uri.parse(track.audioUrl)),
    );

    // Listen for track completion → auto-play next
    _completionSub?.cancel();
    _completionSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        debugPrint('[AudioPlayerService] Track completed: ${track.title}');
        _autoPlayNext();
      }
    });
  }

  Future<void> _autoPlayNext() async {
    final idx = _playlist.indexWhere((t) => t.id == _currentTrack?.id);
    if (idx >= 0 && idx < _playlist.length - 1) {
      final nextTrack = _playlist[idx + 1];
      debugPrint('[AudioPlayerService] Auto-playing next: ${nextTrack.title}');
      await loadTrack(nextTrack, playlist: _playlist);
      await play();
      // Notify AudioProvider that the track changed
      onTrackChanged?.call(nextTrack);
    } else {
      debugPrint('[AudioPlayerService] Playlist finished');
    }
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> seekForward() async {
    final newPos = _player.position + const Duration(seconds: 10);
    final duration = _player.duration ?? Duration.zero;
    await _player.seek(newPos > duration ? duration : newPos);
  }

  Future<void> seekBackward() async {
    final newPos = _player.position - const Duration(seconds: 10);
    await _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);

  Future<void> playNext() async {
    final idx = _playlist.indexWhere((t) => t.id == _currentTrack?.id);
    if (idx >= 0 && idx < _playlist.length - 1) {
      final nextTrack = _playlist[idx + 1];
      await loadTrack(nextTrack, playlist: _playlist);
      await play();
      onTrackChanged?.call(nextTrack);
    }
  }

  Future<void> playPrevious() async {
    final idx = _playlist.indexWhere((t) => t.id == _currentTrack?.id);
    if (idx > 0) {
      final prevTrack = _playlist[idx - 1];
      await loadTrack(prevTrack, playlist: _playlist);
      await play();
      onTrackChanged?.call(prevTrack);
    }
  }

  bool get hasNext {
    final idx = _playlist.indexWhere((t) => t.id == _currentTrack?.id);
    return idx >= 0 && idx < _playlist.length - 1;
  }

  bool get hasPrevious {
    final idx = _playlist.indexWhere((t) => t.id == _currentTrack?.id);
    return idx > 0;
  }

  void dispose() {
    _completionSub?.cancel();
    _player.dispose();
  }
}
