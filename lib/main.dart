// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'data/repositories/favorites_repository.dart';
import 'data/repositories/stats_repository.dart';
import 'data/services/audio_player_service.dart';
import 'data/services/auth_service.dart';
import 'firebase_options.dart';
import 'presentation/providers/audio_provider.dart';
import 'presentation/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const AudioSecureApp());
}

class AudioSecureApp extends StatelessWidget {
  const AudioSecureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => FavoritesRepository()),
        Provider(create: (_) => StatsRepository()),
        Provider(create: (_) => AudioPlayerService()),
        ChangeNotifierProvider(
          create: (ctx) => AuthProvider(ctx.read<AuthService>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => AudioProvider(
            playerService: ctx.read<AudioPlayerService>(),
            favoritesRepo: ctx.read<FavoritesRepository>(),
            statsRepo: ctx.read<StatsRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'AudioSecure',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AppRouter.login,
      ),
    );
  }
}
