// lib/data/services/biometric_service.dart

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/utils/result.dart';

enum BiometricStatus { available, notEnrolled, notAvailable }

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if biometric hardware is available and enrolled
  Future<BiometricStatus> checkStatus() async {
    try {
      final isAvailable = await _auth.isDeviceSupported();
      if (!isAvailable) return BiometricStatus.notAvailable;

      final isEnrolled = await _auth.canCheckBiometrics;
      if (!isEnrolled) return BiometricStatus.notEnrolled;

      return BiometricStatus.available;
    } catch (_) {
      return BiometricStatus.notAvailable;
    }
  }

  /// Returns available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Authenticate with biometrics
  /// [reason] – shown to user in the system prompt
  Future<Result<bool>> authenticate({
    String reason = 'Authenticate to continue',
  }) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return Success(authenticated);
    } on PlatformException catch (e) {
      if (e.code == 'NotEnrolled') {
        return const Failure('No fingerprint enrolled on this device');
      }
      return Failure(e.message ?? 'Authentication failed', error: e);
    } catch (e) {
      return Failure('Unexpected error during authentication', error: e);
    }
  }

  /// Stop any ongoing authentication
  Future<void> stopAuthentication() => _auth.stopAuthentication();
}
