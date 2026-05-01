// lib/presentation/pages/home/playlist_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/track_model.dart';
import '../../../data/services/quran_api_service.dart';
import '../../providers/audio_provider.dart';
import '../../providers/auth_provider.dart';

class PlaylistTab extends StatefulWidget {
  const PlaylistTab({super.key});

  @override
  State<PlaylistTab> createState() => _PlaylistTabState();
}

class _PlaylistTabState extends State<PlaylistTab> {
  final QuranApiService _apiService = QuranApiService();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _apiService.fetchCategories();
    if (!mounted) return;

    result.fold(
      onSuccess: (cats) {
        context.read<AudioProvider>().setCategories(cats);
        setState(() => _isLoading = false);
      },
      onFailure: (msg) => setState(() {
        _error = msg;
        _isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: AppTheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCategories,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final categories = context.watch<AudioProvider>().categories;

    if (categories.isEmpty) {
      return const Center(child: Text('No content available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: categories.length,
      itemBuilder: (ctx, i) => _CategoryTile(category: categories[i]),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        category.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: category.description != null
          ? Text(category.description!,
              style: TextStyle(
                  color: AppTheme.onSurfaceVariant, fontSize: 12))
          : null,
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          category.id,
          style: const TextStyle(
              color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      children: category.tracks.isEmpty
          ? [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No tracks available',
                    style: TextStyle(color: AppTheme.onSurfaceVariant)),
              )
            ]
          : category.tracks
              .map((track) => _TrackTile(
                    track: track,
                    playlist: category.tracks,
                  ))
              .toList(),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final TrackModel track;
  final List<TrackModel> playlist;

  const _TrackTile({required this.track, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final isPlaying = audioProvider.currentTrack?.id == track.id;
    final isFav = audioProvider.isFavorite(track.id);
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isPlaying
              ? AppTheme.primaryColor
              : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isPlaying ? Icons.equalizer : Icons.play_arrow,
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
        style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
      ),
      trailing: IconButton(
        icon: Icon(
          isFav ? Icons.favorite : Icons.favorite_outline,
          color: isFav ? AppTheme.primaryColor : AppTheme.onSurfaceVariant,
        ),
        onPressed: () => audioProvider.toggleFavorite(uid, track),
      ),
      onTap: () {
        audioProvider.loadAndPlay(track, playlist: playlist);
        Navigator.pushNamed(context, AppRouter.player,
            arguments: {'track': track});
      },
    );
  }
}
