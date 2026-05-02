// lib/data/models/track_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TrackModel {
  final String id;
  final String title;
  final String titleAr;
  final String category;      // surah name in English
  final String categoryId;    // surah number
  final String audioUrl;
  final String type;          // Meccan / Medinan
  final int ayatCount;
  final Duration? duration;

  const TrackModel({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.category,
    required this.categoryId,
    required this.audioUrl,
    required this.type,
    required this.ayatCount,
    this.duration,
  });

  /// Build from /api/surahs item
  /// Audio URL pattern: https://cdn.islamic.network/quran/audio/128/ar.alafasy/{number}.mp3
  factory TrackModel.fromSurahApi(Map<String, dynamic> json) {
    final number = json['number']?.toString() ?? json['id']?.toString() ?? '1';
    return TrackModel(
      id: 'surah_$number',
      title: json['name_en'] as String? ?? '',
      titleAr: json['name_ar'] as String? ?? '',
      category: json['type'] as String? ?? '',
      categoryId: number,
      audioUrl:
          'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/$number.mp3',
      type: json['type'] as String? ?? '',
      ayatCount: int.tryParse(json['ayat_count']?.toString() ?? '0') ?? 0,
    );
  }

  factory TrackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrackModel(
      id: data['id'] as String,
      title: data['title'] as String,
      titleAr: data['titleAr'] as String? ?? '',
      category: data['category'] as String,
      categoryId: data['categoryId'] as String,
      audioUrl: data['audioUrl'] as String,
      type: data['type'] as String? ?? '',
      ayatCount: data['ayatCount'] as int? ?? 0,
      duration: data['durationMs'] != null
          ? Duration(milliseconds: data['durationMs'] as int)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'title': title,
        'titleAr': titleAr,
        'category': category,
        'categoryId': categoryId,
        'audioUrl': audioUrl,
        'type': type,
        'ayatCount': ayatCount,
        'durationMs': duration?.inMilliseconds,
        'addedAt': FieldValue.serverTimestamp(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TrackModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Groups surahs by type: Meccan / Medinan
class CategoryModel {
  final String id;
  final String name;
  final List<TrackModel> tracks;

  const CategoryModel({
    required this.id,
    required this.name,
    this.tracks = const [],
  });

  CategoryModel copyWithTracks(List<TrackModel> tracks) => CategoryModel(
        id: id,
        name: name,
        tracks: tracks,
      );
}
