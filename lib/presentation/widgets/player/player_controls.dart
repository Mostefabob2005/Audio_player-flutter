// lib/presentation/widgets/player/player_controls.dart

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/audio_provider.dart';

class PlayerControls extends StatelessWidget {
  final AudioProvider audioProvider;

  const PlayerControls({super.key, required this.audioProvider});

  @override
  Widget build(BuildContext context) {
    final playerService = audioProvider.playerService;

    return Column(
      children: [
        // Loop + shuffle row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _loopIcon(audioProvider.loopMode),
                color: audioProvider.loopMode != LoopMode.off
                    ? AppTheme.primaryColor
                    : AppTheme.onSurfaceVariant,
              ),
              onPressed: audioProvider.cycleLoopMode,
            ),
          ],
        ),

        // Main controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Previous
            IconButton(
              iconSize: 36,
              icon: const Icon(Icons.skip_previous_rounded),
              onPressed: playerService.hasPrevious ? playerService.playPrevious : null,
              color: playerService.hasPrevious
                  ? AppTheme.onSurface
                  : AppTheme.onSurfaceVariant,
            ),

            // Seek back
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.replay_10),
              onPressed: playerService.seekBackward,
              color: AppTheme.onSurface,
            ),

            // Play / Pause
            StreamBuilder<bool>(
              stream: playerService.playingStream,
              builder: (_, snap) {
                final isPlaying = snap.data ?? false;
                return GestureDetector(
                  onTap: audioProvider.togglePlay,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 40,
                      color: Colors.black,
                    ),
                  ),
                );
              },
            ),

            // Seek forward
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.forward_10),
              onPressed: playerService.seekForward,
              color: AppTheme.onSurface,
            ),

            // Next
            IconButton(
              iconSize: 36,
              icon: const Icon(Icons.skip_next_rounded),
              onPressed: playerService.hasNext ? playerService.playNext : null,
              color: playerService.hasNext
                  ? AppTheme.onSurface
                  : AppTheme.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }

  IconData _loopIcon(LoopMode mode) => switch (mode) {
        LoopMode.off => Icons.repeat,
        LoopMode.one => Icons.repeat_one,
        LoopMode.all => Icons.repeat,
      };
}
