// lib/data/repositories/stats_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/listening_stats_model.dart';
import '../models/track_model.dart';

class StatsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference _statsDoc(String uid) => _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection(AppConstants.listeningStatsCollection)
      .doc('summary');

  // ─── Monthly Goal (local) ─────────────────────────────────────────────────

  Future<int> getMonthlyGoalHours() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.keyMonthlyGoalHours) ??
        AppConstants.defaultMonthlyGoalHours;
  }

  Future<void> setMonthlyGoalHours(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyMonthlyGoalHours, hours);
  }

  // ─── Listening Stats ──────────────────────────────────────────────────────

  Future<ListeningStatsModel> fetchStats(String uid) async {
    try {
      final doc = await _statsDoc(uid).get();
      if (!doc.exists) return ListeningStatsModel.empty(uid);

      final data = doc.data() as Map<String, dynamic>;
      final totalMinutes = (data['totalMinutes'] as num?)?.toInt() ?? 0;

      final rawDaily = data['dailyStats'] as List<dynamic>? ?? [];
      final dailyStats = rawDaily
          .map((e) =>
              DailyListeningModel.fromMap(e as Map<String, dynamic>))
          .toList();

      final playCounts = Map<String, int>.from(data['trackPlayCounts'] ?? {});

      return ListeningStatsModel(
        userId: uid,
        totalMinutes: totalMinutes,
        dailyStats: dailyStats,
        trackPlayCounts: playCounts,
      );
    } catch (_) {
      return ListeningStatsModel.empty(uid);
    }
  }

  /// Record that a track was played for [minutes] minutes today
  Future<void> recordListening({
    required String uid,
    required TrackModel track,
    required int minutesListened,
  }) async {
    if (minutesListened <= 0) return;

    final today = DateTime.now();
    final dateKey = today.toIso8601String().substring(0, 10);

    await _statsDoc(uid).set(
      {
        'totalMinutes': FieldValue.increment(minutesListened),
        'lastUpdated': FieldValue.serverTimestamp(),
        'trackPlayCounts.${track.id}': FieldValue.increment(1),
        'dailyMinutes.$dateKey': FieldValue.increment(minutesListened),
      },
      SetOptions(merge: true),
    );
  }
}
