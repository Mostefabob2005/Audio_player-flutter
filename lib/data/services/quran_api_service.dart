// lib/data/services/quran_api_service.dart

import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/result.dart';
import '../models/track_model.dart';

class QuranApiService {
  late final Dio _dio;

  QuranApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.quranApiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(LogInterceptor(responseBody: false));
  }

  /// Fetch all surahs (categories)
  Future<Result<List<CategoryModel>>> fetchCategories() async {
    try {
      final response = await _dio.get('/api/surahs');
      final List<dynamic> data = response.data['data'] ?? response.data;

      final categories = data
          .map((json) => CategoryModel.fromApi(json as Map<String, dynamic>))
          .toList();

      return Success(categories);
    } on DioException catch (e) {
      return Failure(_mapDioError(e), error: e);
    }
  }

  /// Fetch recitations for a specific surah/category
  Future<Result<List<TrackModel>>> fetchTracksForCategory({
    required String categoryId,
    required String categoryName,
    int reciterId = 1, // default reciter
  }) async {
    try {
      final response = await _dio.get(
        '/api/recitations/$reciterId/by_chapter/$categoryId',
      );

      final List<dynamic> data =
          response.data['audio_files'] ?? response.data['data'] ?? [];

      final tracks = data
          .map((json) => TrackModel.fromApi(
                json as Map<String, dynamic>,
                categoryName,
              ))
          .toList();

      return Success(tracks);
    } on DioException catch (e) {
      return Failure(_mapDioError(e), error: e);
    }
  }

  /// Fetch all categories with their tracks (for first load)
  Future<Result<List<CategoryModel>>> fetchAllWithTracks({
    int reciterId = 1,
  }) async {
    final categoriesResult = await fetchCategories();
    if (categoriesResult is Failure<List<CategoryModel>>) {
      return categoriesResult;
    }

    final categories = (categoriesResult as Success<List<CategoryModel>>).data;
    final enriched = <CategoryModel>[];

    for (final cat in categories) {
      final tracksResult = await fetchTracksForCategory(
        categoryId: cat.id,
        categoryName: cat.name,
        reciterId: reciterId,
      );
      enriched.add(
        cat.copyWithTracks(
          tracksResult is Success<List<TrackModel>>
              ? tracksResult.data
              : [],
        ),
      );
    }

    return Success(enriched);
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
