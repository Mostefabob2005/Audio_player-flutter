import 'package:flutter/material.dart';
import '../../core/services/biometric_service.dart';
import '../auth/login_screen.dart';

class BiometricGate extends StatefulWidget {
  const BiometricGate({super.key});

  @override
  _BiometricGateState createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate> {
  final BiometricService _bioService = BiometricService();

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    bool isAvailable = await _bioService.isBiometricAvailable();

    if (!isAvailable) {
      _showError("No biometric available on this device");
      return;
    }

    bool success = await _bioService.authenticate();

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    } else {
      _showError("Authentication failed");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
