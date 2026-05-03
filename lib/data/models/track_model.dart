// lib/data/models/track_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TrackModel {
  final String id;
  final String title;
  final String category;
  final String categoryId;
  final String audioUrl;
  final String? imageUrl;
  final Duration? duration;
  final Map<String, dynamic>? extra;

  const TrackModel({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryId,
    required this.audioUrl,
    this.imageUrl,
    this.duration,
    this.extra,
  });

  /// Build from Quran API response
  factory TrackModel.fromApi(Map<String, dynamic> json, String categoryName) {
    return TrackModel(
      id: json['id']?.toString() ?? '',
      title: json['name'] ?? json['title'] ?? '',
      category: categoryName,
      categoryId: json['surah_id']?.toString() ?? json['chapter_id']?.toString() ?? '',
      audioUrl: json['audio'] ?? json['url'] ?? '',
      imageUrl: null,
      extra: json,
    );
  }

  factory TrackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrackModel(
      id: data['id'] as String,
      title: data['title'] as String,
      category: data['category'] as String,
      categoryId: data['categoryId'] as String,
      audioUrl: data['audioUrl'] as String,
      imageUrl: data['imageUrl'] as String?,
      duration: data['durationMs'] != null
          ? Duration(milliseconds: data['durationMs'] as int)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'title': title,
        'category': category,
        'categoryId': categoryId,
        'audioUrl': audioUrl,
        'imageUrl': imageUrl,
        'durationMs': duration?.inMilliseconds,
        'addedAt': FieldValue.serverTimestamp(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TrackModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}


/// Groups tracks by category
class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final List<TrackModel> tracks;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.tracks = const [],
  });

  factory CategoryModel.fromApi(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['englishName'] ?? '',
      description: json['englishNameTranslation'] as String?,
      tracks: [],
    );
  }

  CategoryModel copyWithTracks(List<TrackModel> tracks) => CategoryModel(
        id: id,
        name: name,
        description: description,
        tracks: tracks,
      );
}
