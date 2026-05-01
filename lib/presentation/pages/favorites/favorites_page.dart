// lib/presentation/pages/favorites/favorites_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/track_model.dart';
import '../../../data/repositories/favorites_repository.dart';
import '../../providers/audio_provider.dart';
import '../../providers/auth_provider.dart';

class FavoritesPage extends StatelessWidget {
  /// When true, this page is embedded as a bottom nav tab (no AppBar)
  final bool isTab;

  const FavoritesPage({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid ?? '';
    final favoritesRepo = FavoritesRepository();

    final body = StreamBuilder<List<TrackModel>>(
      stream: favoritesRepo.watchFavorites(uid),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }

        final favorites = snap.data ?? [];

        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite_outline,
                    size: 72, color: AppTheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text(
                  'No favorites yet',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap ♡ on any track to save it here',
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: favorites.length,
          itemBuilder: (_, i) => _FavoriteTrackTile(
            track: favorites[i],
            playlist: favorites,
          ),
        );
      },
    );

    if (isTab) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: body,
    );
  }
}

class _FavoriteTrackTile extends StatelessWidget {
  final TrackModel track;
  final List<TrackModel> playlist;

  const _FavoriteTrackTile({required this.track, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final isPlaying = audioProvider.currentTrack?.id == track.id;

    return Dismissible(
      key: Key(track.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.errorColor,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        // biometric auth is done inside toggleFavorite
        await audioProvider.toggleFavorite(uid, track);
        // If still favorite (auth failed), cancel dismiss
        return !audioProvider.isFavorite(track.id);
      },
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isPlaying ? AppTheme.primaryColor : AppTheme.cardDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isPlaying ? Icons.equalizer : Icons.music_note,
            color: isPlaying ? Colors.black : AppTheme.onSurface,
          ),
        ),
        title: Text(
          track.title,
          style: TextStyle(
            color: isPlaying ? AppTheme.primaryColor : AppTheme.onSurface,
            fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          track.category,
          style: const TextStyle(
              color: AppTheme.onSurfaceVariant, fontSize: 12),
        ),
        trailing: const Icon(Icons.favorite,
            color: AppTheme.primaryColor, size: 20),
        onTap: () {
          audioProvider.loadAndPlay(track, playlist: playlist);
          Navigator.pushNamed(context, AppRouter.player);
        },
      ),
    );
  }
}
