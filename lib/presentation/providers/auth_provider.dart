// lib/presentation/providers/auth_provider.dart

import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../core/utils/result.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider(this._authService) {
    _init();
  }

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void _init() {
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        _status = AuthStatus.unauthenticated;
        _user = null;
      } else if (_user == null) {
        final result = await _authService.getCurrentUserProfile();
        if (result is Success<UserModel>) {
          _user = result.data;
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
      }
      notifyListeners();
    });
  }

  Future<Result<UserModel>> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading();
    final result = await _authService.signIn(email: email, password: password);
    result.fold(
      onSuccess: (user) {
        _user = user;
        _status = AuthStatus.authenticated;
      },
      onFailure: (msg) {
        _errorMessage = msg;
        _status = AuthStatus.error;
      },
    );
    notifyListeners();
    return result;
  }

  Future<Result<UserModel>> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
  }) async {
    _setLoading();
    final result = await _authService.signUp(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
    );
    result.fold(
      onSuccess: (user) {
        _user = user;
        _status = AuthStatus.authenticated;
      },
      onFailure: (msg) {
        _errorMessage = msg;
        _status = AuthStatus.error;
      },
    );
    notifyListeners();
    return result;
  }

  Future<Result<void>> sendPasswordReset(String email) async {
    _setLoading();
    final result = await _authService.sendPasswordReset(email);
    if (result is Failure) {
      _errorMessage = result.errorOrNull;
      _status = AuthStatus.error;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
    return result;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }
}
