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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing'),
        actions: [
          IconButton(
            icon: Icon(
              audioProvider.isFavorite(track.id)
                  ? Icons.favorite
                  : Icons.favorite_outline,
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

              // Album Art
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppTheme.cardDark,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: track.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          track.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.music_note,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
              ),

              const Spacer(),

              // Track Info
              Text(
                track.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                track.category,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 32),

              // Seek Bar
              StreamBuilder<PositionData>(
                stream: audioProvider.playerService.positionDataStream,
                builder: (_, snap) {
                  final data =
                      snap.data ??
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

              const SizedBox(height: 16),

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
