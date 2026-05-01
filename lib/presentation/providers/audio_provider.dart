// lib/presentation/providers/audio_provider.dart

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/track_model.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/services/audio_player_service.dart';
import '../../data/services/biometric_service.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayerService _playerService;
  final FavoritesRepository _favoritesRepo;
  final StatsRepository _statsRepo;
  final BiometricService _biometricService;

  AudioProvider({
    required AudioPlayerService playerService,
    required FavoritesRepository favoritesRepo,
    required StatsRepository statsRepo,
    required BiometricService biometricService,
  }) : _playerService = playerService,
       _favoritesRepo = favoritesRepo,
       _statsRepo = statsRepo,
       _biometricService = biometricService;

  List<CategoryModel> _categories = [];
  Set<String> _favoriteIds = {};
  final bool _isLoadingCategories = false;
  String? _error;
  DateTime? _playStartTime;
  LoopMode _loopMode = LoopMode.off;

  AudioPlayerService get playerService => _playerService;
  List<CategoryModel> get categories => _categories;
  Set<String> get favoriteIds => _favoriteIds;
  bool get isLoadingCategories => _isLoadingCategories;
  String? get error => _error;
  TrackModel? get currentTrack => _playerService.currentTrack;
  LoopMode get loopMode => _loopMode;

  void setCategories(List<CategoryModel> cats) {
    _categories = cats;
    notifyListeners();
  }

  void setFavorites(List<TrackModel> favs) {
    _favoriteIds = favs.map((f) => f.id).toSet();
    notifyListeners();
  }

  bool isFavorite(String trackId) => _favoriteIds.contains(trackId);

  Future<void> loadAndPlay(
    TrackModel track, {
    List<TrackModel>? playlist,
  }) async {
    // Save stats for previous track
    await _savePreviousTrackStats();

    await _playerService.loadTrack(track, playlist: playlist);
    await _playerService.play();
    _playStartTime = DateTime.now();
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (_playerService.isPlaying) {
      await _playerService.pause();
    } else {
      await _playerService.play();
      _playStartTime ??= DateTime.now();
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

  Future<void> toggleFavorite(String uid, TrackModel track) async {
    if (isFavorite(track.id)) {
      // Require biometric to remove
      final auth = await _biometricService.authenticate(
        reason: 'Authenticate to remove from favorites',
      );
      if (!auth.isSuccess || auth.dataOrNull != true) return;

      await _favoritesRepo.removeFavorite(uid, track.id);
      _favoriteIds.remove(track.id);
    } else {
      await _favoritesRepo.addFavorite(uid, track);
      _favoriteIds.add(track.id);
    }
    notifyListeners();
  }

  Future<void> _savePreviousTrackStats() async {
    // Reserved: implement with uid context if needed
    _playStartTime = null;
  }

  @override
  void dispose() {
    _playerService.dispose();
    super.dispose();
  }
}
