import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:AUDIO_PLAYER-FLUTTER/services/biometric_service.dart';
import 'package:audio_app_secure/providers/auth_provider.dart';
import 'package:audio_app_secure/screens/login_screen.dart';
import 'package:audio_app_secure/screens/home_screen.dart';
import 'package:just_audio/just_audio.dart';

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  final BiometricService _bioService = BiometricService();
  final AudioPlayer _successPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _checkAndAuthenticate();
  }

  Future<void> _checkAndAuthenticate() async {
    final canCheck = await _bioService.canCheckBiometrics();
    if (!canCheck) {
      _showNoBiometricsDialog();
      return;
    }

    final isEnrolled = await _bioService.isBiometricEnrolled();
    if (!isEnrolled) {
      _redirectToSecuritySettings();
      return;
    }

    final authenticated = await _bioService.authenticateWithBiometrics();
    if (authenticated) {
      await _playSuccessSound();
      _navigateToNext();
    } else {
      // Optionally show retry or exit
      _showRetryDialog();
    }
  }

  Future<void> _playSuccessSound() async {
    try {
      await _successPlayer.setAsset('assets/audio/success.mp3');
      await _successPlayer.play();
    } catch (e) {
      debugPrint('Could not play success sound: $e');
    }
  }

  void _navigateToNext() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _redirectToSecuritySettings() {
    // Android / iOS specific intent
    const platform = MethodChannel('com.example.audio_app_secure/settings');
    try {
      platform.invokeMethod('openSecuritySettings');
    } catch (e) {
      // Fallback: show dialog with instructions
    }
    // For simplicity, we can use a package like app_settings
  }

  void _showNoBiometricsDialog() { /* ... */ }
  void _showRetryDialog() { /* ... */ }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}