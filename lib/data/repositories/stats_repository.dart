// lib/data/repositories/stats_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/listening_stats_model.dart';
import '../models/track_model.dart';

class StatsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Store stats directly in the user document — no subcollection
  // This avoids Firestore permission issues with subcollections
  DocumentReference _userDoc(String uid) =>
      _db.collection(AppConstants.usersCollection).doc(uid);

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
      final doc = await _userDoc(uid).get();
      if (!doc.exists) return ListeningStatsModel.empty(uid);

      final data = doc.data() as Map<String, dynamic>;

      final totalMinutes =
          (data['totalMinutes'] as num?)?.toInt() ?? 0;

      final playCounts = <String, int>{};
      final rawCounts = data['trackPlayCounts'];
      if (rawCounts is Map) {
        rawCounts.forEach((k, v) {
          playCounts[k.toString()] = (v as num).toInt();
        });
      }

      final rawDaily = data['dailyMinutes'];
      final dailyStats = <DailyListeningModel>[];
      if (rawDaily is Map) {
        rawDaily.forEach((key, value) {
          try {
            dailyStats.add(DailyListeningModel(
              date: DateTime.parse(key.toString()),
              minutes: (value as num).toInt(),
            ));
          } catch (_) {}
        });
        dailyStats.sort((a, b) => a.date.compareTo(b.date));
      }

      return ListeningStatsModel(
        userId: uid,
        totalMinutes: totalMinutes,
        dailyStats: dailyStats,
        trackPlayCounts: playCounts,
      );
    } catch (e) {
      debugPrint('[StatsRepository] fetchStats error: $e');
      return ListeningStatsModel.empty(uid);
    }
  }

  // ─── Record Listening ─────────────────────────────────────────────────────

  Future<bool> recordListening({
    required String uid,
    required TrackModel track,
    required int minutesListened,
  }) async {
    if (minutesListened <= 0) return false;

    final dateKey = DateTime.now().toIso8601String().substring(0, 10);

    debugPrint('[StatsRepository] Writing $minutesListened min for uid=$uid track=${track.title} date=$dateKey');

    try {
      await _userDoc(uid).set(
        {
          'totalMinutes': FieldValue.increment(minutesListened),
          'statsLastUpdated': FieldValue.serverTimestamp(),
          'trackPlayCounts': {track.id: FieldValue.increment(1)},
          'dailyMinutes': {dateKey: FieldValue.increment(minutesListened)},
        },
        SetOptions(merge: true),
      );
      debugPrint('[StatsRepository] Write SUCCESS');
      return true;
    } catch (e) {
      // Now we can see the actual error
      debugPrint('[StatsRepository] Write FAILED: $e');
      return false;
    }
  }
}
