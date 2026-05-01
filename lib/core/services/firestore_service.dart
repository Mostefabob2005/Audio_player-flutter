import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===============================
  // 👤 USER PROFILE
  // ===============================

  Future<void> saveUserProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
  }) async {
    await _db.collection('users').doc(uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // ===============================
  // ⭐ FAVORITES
  // ===============================

  Future<void> addFavorite({
    required String uid,
    required String trackId,
    required String title,
    required String url,
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(trackId)
        .set({
          'title': title,
          'url': url,
          'addedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> removeFavorite({
    required String uid,
    required String trackId,
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(trackId)
        .delete();
  }

  Stream<QuerySnapshot> getFavorites(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  // ===============================
  // 📊 LISTENING STATS (BASIC)
  // ===============================

  Future<void> updateListeningTime({
    required String uid,
    required int minutes,
  }) async {
    final docRef = _db.collection('users').doc(uid);

    await docRef.set({
      'totalMinutes': FieldValue.increment(minutes),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserStats(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }
}
