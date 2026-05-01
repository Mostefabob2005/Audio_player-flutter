// lib/data/repositories/favorites_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/result.dart';
import '../models/track_model.dart';

class FavoritesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _userFavorites(String uid) => _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection(AppConstants.favoritesCollection);

  Stream<List<TrackModel>> watchFavorites(String uid) {
    return _userFavorites(uid)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TrackModel.fromFirestore(d)).toList());
  }

  Future<Result<void>> addFavorite(String uid, TrackModel track) async {
    try {
      await _userFavorites(uid).doc(track.id).set(track.toFirestore());
      return const Success(null);
    } catch (e) {
      return Failure('Failed to add favorite', error: e);
    }
  }

  /// Requires biometric auth before calling
  Future<Result<void>> removeFavorite(String uid, String trackId) async {
    try {
      await _userFavorites(uid).doc(trackId).delete();
      return const Success(null);
    } catch (e) {
      return Failure('Failed to remove favorite', error: e);
    }
  }

  Future<bool> isFavorite(String uid, String trackId) async {
    try {
      final doc = await _userFavorites(uid).doc(trackId).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }
}
