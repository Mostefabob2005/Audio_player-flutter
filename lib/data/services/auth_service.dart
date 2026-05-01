// lib/data/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/result.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentFirebaseUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isLoggedIn => _auth.currentUser != null;

  // ─── Sign Up ─────────────────────────────────────────────────────────────

  Future<Result<UserModel>> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        uid: credential.user!.uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
        dateOfBirth: dateOfBirth,
        createdAt: DateTime.now(),
      );

      await _db
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(user.toFirestore());

      await credential.user!.updateDisplayName(user.fullName);

      return Success(user);
    } on FirebaseAuthException catch (e) {
      return Failure(_mapAuthError(e.code), error: e);
    } catch (e) {
      return Failure('Sign up failed. Please try again.', error: e);
    }
  }

  // ─── Sign In ─────────────────────────────────────────────────────────────

  Future<Result<UserModel>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = await _db
          .collection(AppConstants.usersCollection)
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        return const Failure('User profile not found');
      }

      return Success(UserModel.fromFirestore(userDoc));
    } on FirebaseAuthException catch (e) {
      return Failure(_mapAuthError(e.code), error: e);
    } catch (e) {
      return Failure('Sign in failed. Please try again.', error: e);
    }
  }

  // ─── Forgot Password ─────────────────────────────────────────────────────

  Future<Result<void>> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      return Failure(_mapAuthError(e.code), error: e);
    }
  }

  // ─── Get Current User Profile ────────────────────────────────────────────

  Future<Result<UserModel>> getCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Failure('Not authenticated');

    try {
      final doc = await _db
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      if (!doc.exists) return const Failure('Profile not found');
      return Success(UserModel.fromFirestore(doc));
    } catch (e) {
      return Failure('Failed to load profile', error: e);
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() => _auth.signOut();

  // ─── Error Mapping ────────────────────────────────────────────────────────

  String _mapAuthError(String code) => switch (code) {
        'email-already-in-use' => 'This email is already registered',
        'invalid-email' => 'Invalid email address',
        'weak-password' => 'Password is too weak',
        'user-not-found' => 'No account found with this email',
        'wrong-password' => 'Incorrect password',
        'user-disabled' => 'This account has been disabled',
        'too-many-requests' => 'Too many attempts. Please try again later',
        'network-request-failed' => 'Network error. Check your connection',
        _ => 'Authentication error: $code',
      };
}
