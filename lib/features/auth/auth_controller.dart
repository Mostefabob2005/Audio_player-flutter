import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  /// Stream to listen to auth state (logged in / logged out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// SIGN UP
  Future<User?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
  }) async {
    try {
      // 🔐 Create user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;

      if (user == null) {
        throw Exception("User creation failed");
      }

      // 📅 Age validation (>= 13)
      final age = _calculateAge(birthDate);
      if (age < 13) {
        await user.delete(); // rollback account
        throw Exception("User must be at least 13 years old");
      }

      // ☁️ Save profile in Firestore
      await _firestore.saveUserProfile(
        uid: user.uid,
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
      );

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception("Signup failed: $e");
    }
  }

  /// SIGN IN
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  /// RESET PASSWORD
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  /// SIGN OUT
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// GET CURRENT USER
  User? get currentUser => _auth.currentUser;

  /// 🧠 Calculate age
  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  /// 🔥 Handle Firebase errors (clean messages)
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return "Email already in use";
      case 'invalid-email':
        return "Invalid email address";
      case 'weak-password':
        return "Password must be at least 6 characters";
      case 'user-not-found':
        return "No user found with this email";
      case 'wrong-password':
        return "Incorrect password";
      default:
        return "Authentication error: ${e.message}";
    }
  }
}
