// lib/presentation/pages/biometric/biometric_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../data/services/biometric_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/utils/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/result.dart';

class BiometricPage extends StatefulWidget {
  const BiometricPage({super.key});

  @override
  State<BiometricPage> createState() => _BiometricPageState();
}

class _BiometricPageState extends State<BiometricPage>
    with TickerProviderStateMixin {
  final BiometricService _biometricService = BiometricService();
  bool _isAuthenticating = false;
  String? _message;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _message = null;
    });

    final status = await _biometricService.checkStatus();

    if (status == BiometricStatus.notAvailable) {
      _showMessage('Biometric authentication not available on this device');
      setState(() => _isAuthenticating = false);
      return;
    }

    if (status == BiometricStatus.notEnrolled) {
      _showNotEnrolledDialog();
      setState(() => _isAuthenticating = false);
      return;
    }

    final result = await _biometricService.authenticate(
      reason: 'Place your finger on the sensor to open AudioSecure',
    );

    if (!mounted) return;

    result.fold(
      onSuccess: (authenticated) {
        if (authenticated) {
          _onAuthSuccess();
        } else {
          setState(() {
            _isAuthenticating = false;
            _message = 'Authentication failed. Please try again.';
          });
        }
      },
      onFailure: (msg) {
        setState(() {
          _isAuthenticating = false;
          _message = msg;
        });
      },
    );
  }

  void _onAuthSuccess() {
    // Play success sound via system (or use audioplayers for a local asset)
    SystemSound.play(SystemSoundType.click);

    final authService = context.read<AuthService>();
    if (authService.isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppRouter.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  void _showMessage(String msg) =>
      setState(() => _message = msg);

  void _showNotEnrolledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('No Fingerprint Found'),
        content: const Text(
          'No fingerprint is enrolled on this device.\n\n'
          'Please go to Settings → Security → Fingerprint to add one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Open system security settings
              const MethodChannel('biometric_settings')
                  .invokeMethod('openSecuritySettings');
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // App logo
              Text(
                'AudioSecure',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Secure Audio Experience',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
              ),

              const Spacer(),

              // Fingerprint icon
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.cardDark,
                    border: Border.all(
                      color: _isAuthenticating
                          ? AppTheme.primaryColor
                          : AppTheme.onSurfaceVariant.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    size: 64,
                    color: _isAuthenticating
                        ? AppTheme.primaryColor
                        : AppTheme.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                _isAuthenticating
                    ? 'Verifying your identity...'
                    : 'Touch the fingerprint sensor',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),

              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(
                  _message!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.errorColor),
                  textAlign: TextAlign.center,
                ),
              ],

              const Spacer(),

              if (!_isAuthenticating)
                ElevatedButton.icon(
                  onPressed: _authenticate,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
