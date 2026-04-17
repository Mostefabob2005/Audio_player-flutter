import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': Timestamp.fromDate(birthDate),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot> getUserProfile(String uid) =>
      _firestore.collection('users').doc(uid).get();

  // Favorites methods (to be used later)
  Future<void> addToFavorites(String uid, String trackId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(trackId)
        .set({'addedAt': FieldValue.serverTimestamp()});
  }

  Future<void> removeFromFavorites(String uid, String trackId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(trackId)
        .delete();
  }

  Stream<QuerySnapshot> getFavorites(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }
}