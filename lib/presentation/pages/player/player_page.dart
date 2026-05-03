// lib/presentation/pages/player/player_page.dart

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/audio_player_service.dart';
import '../../providers/audio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/player/player_controls.dart';
import '../../widgets/player/seek_bar.dart';

class PlayerPage extends StatelessWidget {
  final Map<String, dynamic>? initialArgs;
  const PlayerPage({super.key, this.initialArgs});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final track = audioProvider.currentTrack;
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    if (track == null) {
      return const Scaffold(body: Center(child: Text('No track selected')));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              audioProvider.isFavorite(track.id)
                  ? Icons.favorite_rounded
                  : Icons.favorite_outline_rounded,
              color: audioProvider.isFavorite(track.id)
                  ? AppTheme.primaryColor
                  : null,
            ),
            onPressed: () => audioProvider.toggleFavorite(uid, track),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),

              // Surah artwork — decorative circle with number
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.3),
                      AppTheme.cardDark,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.25),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      track.categoryId,
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Text(
                      'Surah',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Arabic name
              Text(
                track.titleAr,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),

              // English name
              Text(
                track.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              // Type + ayat count
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Chip(label: track.type),
                  const SizedBox(width: 8),
                  _Chip(label: '${track.ayatCount} ayahs'),
                ],
              ),

              const SizedBox(height: 32),

              // Seek Bar
              StreamBuilder<PositionData>(
                stream: audioProvider.playerService.positionDataStream,
                builder: (_, snap) {
                  final data = snap.data ??
                      const PositionData(
                        position: Duration.zero,
                        bufferedPosition: Duration.zero,
                        duration: Duration.zero,
                      );
                  return SeekBar(
                    duration: data.duration,
                    position: data.position,
                    bufferedPosition: data.bufferedPosition,
                    onChanged: audioProvider.playerService.seek,
                  );
                },
              ),

              const SizedBox(height: 8),

              // Controls
              PlayerControls(audioProvider: audioProvider),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
