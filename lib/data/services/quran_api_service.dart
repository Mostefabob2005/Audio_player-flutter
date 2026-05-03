// lib/data/services/quran_api_service.dart

import 'package:dio/dio.dart';
import '../../core/utils/result.dart';
import '../models/track_model.dart';

class QuranApiService {
  late final Dio _dio;

  static const String _baseUrl = 'https://quran.yousefheiba.com';

  QuranApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );
  }

  /// Fetch all 114 surahs and group them by type (Meccan / Medinan)
  Future<Result<List<CategoryModel>>> fetchCategoriesWithTracks() async {
    try {
      final response = await _dio.get('/api/surahs');

      // API returns a plain JSON array
      final List<dynamic> rawList = response.data is List
          ? response.data as List
          : (response.data['data'] as List? ?? []);

      final tracks = rawList
          .map((json) =>
              TrackModel.fromSurahApi(json as Map<String, dynamic>))
          .toList();

      // Group by type: Meccan / Medinan
      final meccan = tracks.where((t) => t.type == 'Meccan').toList();
      final medinan = tracks.where((t) => t.type == 'Medinan').toList();
      final other =
          tracks.where((t) => t.type != 'Meccan' && t.type != 'Medinan').toList();

      final categories = <CategoryModel>[
        CategoryModel(id: 'meccan', name: 'Meccan Surahs', tracks: meccan),
        CategoryModel(id: 'medinan', name: 'Medinan Surahs', tracks: medinan),
        if (other.isNotEmpty)
          CategoryModel(id: 'other', name: 'Other', tracks: other),
      ];

      return Success(categories);
    } on DioException catch (e) {
      return Failure(_mapDioError(e), error: e);
    } catch (e) {
      return Failure('Failed to load surahs: $e', error: e);
    }
  }

  /// All tracks as flat list (for player playlist)
  Future<Result<List<TrackModel>>> fetchAllTracks() async {
    try {
      final response = await _dio.get('/api/surahs');
      final List<dynamic> rawList = response.data is List
          ? response.data as List
          : (response.data['data'] as List? ?? []);

      final tracks = rawList
          .map((json) =>
              TrackModel.fromSurahApi(json as Map<String, dynamic>))
          .toList();

      return Success(tracks);
    } on DioException catch (e) {
      return Failure(_mapDioError(e), error: e);
    }
  }

  String _mapDioError(DioException e) => switch (e.type) {
        DioExceptionType.connectionTimeout => 'Connection timed out',
        DioExceptionType.receiveTimeout => 'Server response timed out',
        DioExceptionType.connectionError => 'No internet connection',
        DioExceptionType.badResponse =>
          'Server error: ${e.response?.statusCode}',
        _ => 'Network error. Please try again',
      };
}
