// lib/presentation/pages/home/playlist_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../../core/utils/result.dart';
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
  final QuranApiService _api = QuranApiService();
  bool _isLoading = true;
  String? _error;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });

    final result = await _api.fetchCategoriesWithTracks();
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

  List<CategoryModel> _filtered(List<CategoryModel> cats) {
    if (_search.isEmpty) return cats;
    return cats.map((cat) {
      final filtered = cat.tracks.where((t) =>
          t.title.toLowerCase().contains(_search) ||
          t.titleAr.contains(_search) ||
          t.categoryId.contains(_search)).toList();
      return cat.copyWithTracks(filtered);
    }).where((c) => c.tracks.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text('Loading Surahs...', style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: AppTheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final categories = _filtered(context.watch<AudioProvider>().categories);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search surah...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.onSurfaceVariant),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.onSurfaceVariant),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),

        // Categories + tracks
        Expanded(
          child: categories.isEmpty
              ? const Center(child: Text('No surahs found'))
              : ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (ctx, i) => _CategorySection(
                    category: categories[i],
                    allTracks: context.read<AudioProvider>().categories
                        .expand((c) => c.tracks)
                        .toList(),
                  ),
                ),
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  final CategoryModel category;
  final List<TrackModel> allTracks;

  const _CategorySection({required this.category, required this.allTracks});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: category.id == 'meccan',
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: category.id == 'meccan'
              ? AppTheme.primaryColor.withOpacity(0.15)
              : Colors.blueAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${category.tracks.length}',
          style: TextStyle(
            color: category.id == 'meccan' ? AppTheme.primaryColor : Colors.blueAccent,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
      title: Text(
        category.name,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
      subtitle: Text(
        '${category.tracks.length} surahs',
        style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
      ),
      children: category.tracks
          .map((track) => _SurahTile(track: track, playlist: allTracks))
          .toList(),
    );
  }
}

class _SurahTile extends StatelessWidget {
  final TrackModel track;
  final List<TrackModel> playlist;

  const _SurahTile({required this.track, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final isCurrentTrack = audio.currentTrack?.id == track.id;
    final isFav = audio.isFavorite(track.id);
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isCurrentTrack
              ? AppTheme.primaryColor
              : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: isCurrentTrack
            ? const Icon(Icons.equalizer_rounded, color: Colors.black, size: 20)
            : Text(
                track.categoryId,
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
      ),
      title: Text(
        track.title,
        style: TextStyle(
          color: isCurrentTrack ? AppTheme.primaryColor : AppTheme.onSurface,
          fontWeight: isCurrentTrack ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${track.titleAr}  •  ${track.ayatCount} ayahs',
        style: const TextStyle(
          color: AppTheme.onSurfaceVariant,
          fontSize: 12,
        ),
        textDirection: TextDirection.ltr,
      ),
      trailing: IconButton(
        icon: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          color: isFav ? AppTheme.primaryColor : AppTheme.onSurfaceVariant,
          size: 22,
        ),
        onPressed: () => audio.toggleFavorite(uid, track),
      ),
      onTap: () {
        audio.loadAndPlay(track, playlist: playlist);
        Navigator.pushNamed(context, AppRouter.player,
            arguments: {'track': track});
      },
    );
  }
}
