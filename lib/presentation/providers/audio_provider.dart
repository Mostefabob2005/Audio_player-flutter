// lib/presentation/providers/audio_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/track_model.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/services/audio_player_service.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayerService _playerService;
  final FavoritesRepository _favoritesRepo;
  final StatsRepository _statsRepo;

  AudioProvider({
    required AudioPlayerService playerService,
    required FavoritesRepository favoritesRepo,
    required StatsRepository statsRepo,
  })  : _playerService = playerService,
        _favoritesRepo = favoritesRepo,
        _statsRepo = statsRepo {
    _listenToPlayerState();
  }

  List<CategoryModel> _categories = [];
  Set<String> _favoriteIds = {};
  LoopMode _loopMode = LoopMode.off;
  String? _currentUid;

  // ─── Listening time tracking ───────────────────────────────────────────────
  Timer? _listenTimer;
  int _secondsListened = 0;
  static const int _saveIntervalSeconds = 60; // save every 1 minute

  AudioPlayerService get playerService => _playerService;
  List<CategoryModel> get categories => _categories;
  Set<String> get favoriteIds => _favoriteIds;
  TrackModel? get currentTrack => _playerService.currentTrack;
  LoopMode get loopMode => _loopMode;

  void setUid(String? uid) {
    final normalized = (uid != null && uid.trim().isNotEmpty) ? uid.trim() : null;
    _currentUid = normalized;
  }

  // ─── Track player state to start/stop the timer ───────────────────────────
  void _listenToPlayerState() {
    _playerService.playingStream.listen((isPlaying) {
      if (isPlaying) {
        _startTimer();
      } else {
        _stopTimer();
      }
    });
  }

  void _startTimer() {
    _listenTimer?.cancel();
    _listenTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsListened++;
      // Save to Firestore every minute
      if (_secondsListened % _saveIntervalSeconds == 0) {
        _flushListeningTime();
      }
    });
  }

  void _stopTimer() {
    _listenTimer?.cancel();
    _listenTimer = null;
    // Save whatever is left
    if (_secondsListened > 0) {
      _flushListeningTime();
    }
  }

  Future<void> _flushListeningTime() async {
    final uid = _currentUid;
    final track = _playerService.currentTrack;
    if (uid == null || track == null) return;

    final seconds = _secondsListened;
    // Don't spam writes for very tiny listens.
    if (seconds < 10) return;

    _secondsListened = 0;
    await _statsRepo.recordListeningSeconds(
      uid: uid,
      track: track,
      secondsListened: seconds,
    );
  }

  // ─── Categories ───────────────────────────────────────────────────────────

  void setCategories(List<CategoryModel> cats) {
    _categories = cats;
    notifyListeners();
  }

  // ─── Favorites ────────────────────────────────────────────────────────────

  void setFavorites(List<TrackModel> favs) {
    _favoriteIds = favs.map((f) => f.id).toSet();
    notifyListeners();
  }

  bool isFavorite(String trackId) => _favoriteIds.contains(trackId);

  Future<void> toggleFavorite(String uid, TrackModel track) async {
    if (isFavorite(track.id)) {
      await _favoritesRepo.removeFavorite(uid, track.id);
      _favoriteIds.remove(track.id);
    } else {
      await _favoritesRepo.addFavorite(uid, track);
      _favoriteIds.add(track.id);
    }
    notifyListeners();
  }

  // ─── Playback ─────────────────────────────────────────────────────────────

  Future<void> loadAndPlay(TrackModel track, {List<TrackModel>? playlist}) async {
    // Flush stats for the previous track before switching
    await _flushListeningTime();
    _secondsListened = 0;

    await _playerService.loadTrack(track, playlist: playlist);
    await _playerService.play();
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (_playerService.isPlaying) {
      await _playerService.pause();
    } else {
      await _playerService.play();
    }
    notifyListeners();
  }

  Future<void> cycleLoopMode() async {
    _loopMode = switch (_loopMode) {
      LoopMode.off => LoopMode.one,
      LoopMode.one => LoopMode.all,
      LoopMode.all => LoopMode.off,
    };
    await _playerService.setLoopMode(_loopMode);
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer();
    _playerService.dispose();
    super.dispose();
  }
}
