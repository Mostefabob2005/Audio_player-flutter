// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'AudioSecure';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String favoritesCollection = 'favorites';
  static const String listeningStatsCollection = 'listening_stats';

  // SharedPreferences Keys
  static const String keyMonthlyGoalHours = 'monthly_goal_hours';
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyLastSyncDate = 'last_sync_date';

  // Defaults
  static const int defaultMonthlyGoalHours = 20;
  static const int minimumAgeYears = 13;

  // Quran API
  static const String quranApiBaseUrl = 'https://quran.yousefheiba.com/en';
  static const String quranApiSurahs = '/api/surahs';
  static const String quranApiRecitations = '/api/recitations';

  // Audio
  static const Duration seekStep = Duration(seconds: 10);

  // Monthly goal options (hours)
  static const List<int> goalOptions = [5, 10, 15, 20, 30, 50, 100];
}
