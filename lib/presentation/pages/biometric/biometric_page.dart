// lib/presentation/pages/biometric/biometric_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/services/biometric_service.dart';

class BiometricPage extends StatefulWidget {
  const BiometricPage({super.key});

  @override
  State<BiometricPage> createState() => _BiometricPageState();
}

class _BiometricPageState extends State<BiometricPage>
    with SingleTickerProviderStateMixin {
  final BiometricService _biometric = BiometricService();

  bool _isAuthenticating = false;
  bool _failed = false;
  String _message = 'Touch the fingerprint sensor to continue';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Auto-trigger fingerprint dialog on page open
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _failed = false;
      _message = 'Touch the fingerprint sensor to continue';
    });

    // Check if biometrics are enrolled
    final enrolled = await _biometric.hasEnrolledBiometrics();
    if (!mounted) return;

    if (!enrolled) {
      setState(() {
        _isAuthenticating = false;
        _failed = true;
        _message = 'No fingerprint registered on this device.\nPlease set one up in Settings.';
      });
      return;
    }

    // Trigger fingerprint prompt
    final success = await _biometric.authenticate(
      reason: 'Verify your identity to access AudioSecure',
    );
    if (!mounted) return;

    if (success) {
      setState(() => _message = 'Identity verified!');
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.login);
      }
    } else {
      setState(() {
        _isAuthenticating = false;
        _failed = true;
        _message = 'Authentication failed. Retrying...';
      });
      // Auto-retry after 1.5 seconds
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) _authenticate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App name
              Text(
                'AudioSecure',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Secure Audio Experience',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 72),

              // Fingerprint icon with pulse animation
              ScaleTransition(
                scale: _isAuthenticating ? _pulse : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _failed
                        ? AppTheme.errorColor.withOpacity(0.15)
                        : AppTheme.primaryColor.withOpacity(0.12),
                    border: Border.all(
                      color: _failed
                          ? AppTheme.errorColor.withOpacity(0.5)
                          : AppTheme.primaryColor.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _failed
                        ? Icons.fingerprint
                        : Icons.fingerprint,
                    size: 64,
                    color: _failed
                        ? AppTheme.errorColor
                        : AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Status message
              Text(
                _message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _failed
                          ? AppTheme.errorColor
                          : AppTheme.onSurface,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 40),

              // Auto-retry on failure
              if (_failed) ...[
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, AppRouter.login),
                  child: Text(
                    'Use a different account',
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                ),
              ],

              // Loading indicator while authenticating
              if (_isAuthenticating) ...[
                const SizedBox(height: 16),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
