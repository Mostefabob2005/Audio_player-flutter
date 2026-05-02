// lib/core/utils/app_router.dart

import 'package:flutter/material.dart';
import '../../presentation/pages/biometric/biometric_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/auth/forgot_password_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/player/player_page.dart';
import '../../presentation/pages/favorites/favorites_page.dart';

class AppRouter {
  static const String biometric = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String player = '/player';
  static const String favorites = '/favorites';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case biometric:
        return _pageRoute(const BiometricPage());
      case login:
        return _pageRoute(const LoginPage());
      case register:
        return _pageRoute(const RegisterPage());
      case forgotPassword:
        return _pageRoute(const ForgotPasswordPage());
      case home:
        return _pageRoute(const HomePage());
      case player:
        final args = settings.arguments as Map<String, dynamic>?;
        return _pageRoute(PlayerPage(initialArgs: args));
      case favorites:
        return _pageRoute(const FavoritesPage());
      default:
        return _pageRoute(const BiometricPage());
    }
  }

  static PageRouteBuilder _pageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
