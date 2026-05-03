// lib/presentation/providers/audio_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
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
        _statsRepo = statsRepo;

  List<CategoryModel> _categories = [];
  Set<String> _favoriteIds = {};
  LoopMode _loopMode = LoopMode.off;
  String _uid = '';

  Timer? _listenTimer;
  int _secondsAccumulated = 0;
  int _statsSaveCount = 0;
  int get statsSaveCount => _statsSaveCount;

  AudioPlayerService get playerService => _playerService;
  List<CategoryModel> get categories => _categories;
  Set<String> get favoriteIds => _favoriteIds;
  TrackModel? get currentTrack => _playerService.currentTrack;
  LoopMode get loopMode => _loopMode;

  void setUid(String uid) {
    _uid = uid;
    debugPrint('[AudioProvider] UID set: $_uid');
  }

  // ─── Playback ─────────────────────────────────────────────────────────────

  Future<void> loadAndPlay(TrackModel track,
      {List<TrackModel>? playlist}) async {
    await _flushStats();
    _secondsAccumulated = 0;

    _playerService.onTrackChanged = (_) => notifyListeners();
    await _playerService.loadTrack(track, playlist: playlist);
    await _playerService.play();

    _startTimer();
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (_playerService.isPlaying) {
      await _playerService.pause();
      _stopTimer();
    } else {
      await _playerService.play();
      _startTimer();
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

  // ─── Timer ────────────────────────────────────────────────────────────────

  void _startTimer() {
    _listenTimer?.cancel();
    debugPrint('[AudioProvider] Timer STARTED for "${_playerService.currentTrack?.title}"');
    _listenTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      _secondsAccumulated += 30;
      debugPrint('[AudioProvider] Timer tick: $_secondsAccumulated s, uid=$_uid');
      await _flushStats();
    });
  }

  void _stopTimer() {
    _listenTimer?.cancel();
    _listenTimer = null;
    debugPrint('[AudioProvider] Timer STOPPED');
  }

  Future<void> _flushStats() async {
    debugPrint('[AudioProvider] _flushStats called: uid="$_uid" seconds=$_secondsAccumulated track=${_playerService.currentTrack?.title}');

    if (_uid.isEmpty) {
      debugPrint('[AudioProvider] SKIP: uid is empty');
      return;
    }
    final track = _playerService.currentTrack;
    if (track == null) {
      debugPrint('[AudioProvider] SKIP: no current track');
      return;
    }
    if (_secondsAccumulated < 30) {
      debugPrint('[AudioProvider] SKIP: only $_secondsAccumulated s accumulated');
      return;
    }

    final minutes = (_secondsAccumulated / 60).ceil();
    _secondsAccumulated = 0;

    debugPrint('[AudioProvider] Saving $minutes min to Firestore...');
    final ok = await _statsRepo.recordListening(
      uid: _uid,
      track: track,
      minutesListened: minutes,
    );

    if (ok) {
      _statsSaveCount++;
      notifyListeners();
      debugPrint('[AudioProvider] Stats saved! saveCount=$_statsSaveCount');
    }
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

  @override
  void dispose() {
    _stopTimer();
    _playerService.dispose();
    super.dispose();
  }
}
