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

  // ─── Fetch Stats ──────────────────────────────────────────────────────────

  Future<ListeningStatsModel> fetchStats(String uid) async {
    try {
      final doc = await _statsDoc(uid).get();
      if (!doc.exists) return ListeningStatsModel.empty(uid);

      final data = doc.data() as Map<String, dynamic>;
      // Backward compatible:
      // - old schema: totalMinutes + dailyMinutes
      // - new schema: totalSeconds + dailySeconds
      final totalSeconds = (data['totalSeconds'] as num?)?.toInt() ??
          (((data['totalMinutes'] as num?)?.toInt() ?? 0) * 60);
      final playCounts = Map<String, int>.from(
        (data['trackPlayCounts'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
      );

      // dailySeconds stored as { "2025-05-01": 1800, "2025-05-02": 2700, ... }
      // (fallback to dailyMinutes * 60)
      final rawDailySeconds =
          data['dailySeconds'] as Map<String, dynamic>? ?? {};
      final rawDailyMinutes =
          data['dailyMinutes'] as Map<String, dynamic>? ?? {};

      final dailyStats = <DailyListeningModel>[
        ...rawDailySeconds.entries.map((e) {
          return DailyListeningModel(
            date: DateTime.parse(e.key),
            seconds: (e.value as num).toInt(),
          );
        }),
        ...rawDailyMinutes.entries.map((e) {
          return DailyListeningModel(
            date: DateTime.parse(e.key),
            seconds: (e.value as num).toInt() * 60,
          );
        }),
      ]
        ..sort((a, b) => a.date.compareTo(b.date));

      // Merge duplicates by date (if both seconds + minutes existed)
      final merged = <String, int>{};
      for (final d in dailyStats) {
        final key = d.date.toIso8601String().substring(0, 10);
        merged[key] = (merged[key] ?? 0) + d.seconds;
      }

      final mergedDaily = merged.entries.map((e) {
        return DailyListeningModel(
          date: DateTime.parse(e.key),
          seconds: e.value,
        );
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      return ListeningStatsModel(
        userId: uid,
        totalSeconds: totalSeconds,
        dailyStats: mergedDaily,
        trackPlayCounts: playCounts,
      );
    } catch (_) {
      return ListeningStatsModel.empty(uid);
    }
  }

  // ─── Record Listening ─────────────────────────────────────────────────────

  Future<void> recordListeningSeconds({
    required String uid,
    required TrackModel track,
    required int secondsListened,
  }) async {
    if (uid.trim().isEmpty || secondsListened <= 0) return;

    final dateKey = DateTime.now().toIso8601String().substring(0, 10);

    try {
      await _statsDoc(uid).set(
        {
          'totalSeconds': FieldValue.increment(secondsListened),
          'lastUpdated': FieldValue.serverTimestamp(),
          'trackPlayCounts': {track.id: FieldValue.increment(1)},
          'dailySeconds': {dateKey: FieldValue.increment(secondsListened)},
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Ignore transient write errors; dashboard will recover on next save.
    }
  }
}
