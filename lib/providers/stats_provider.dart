import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatsProvider extends ChangeNotifier {
  double _monthlyGoalHours = 20.0;
  double get monthlyGoalHours => _monthlyGoalHours;

  final Map<DateTime, int> _dailyMinutes = {}; // key = day (yyyy-mm-dd)
  final Map<String, int> _trackPlayCounts = {};

  StatsProvider() {
    _loadGoal();
    _loadListeningData();
  }

  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    _monthlyGoalHours = prefs.getDouble('monthlyGoal') ?? 20.0;
    notifyListeners();
  }

  Future<void> setMonthlyGoal(double hours) async {
    _monthlyGoalHours = hours;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthlyGoal', hours);
    notifyListeners();
  }

  Future<void> _loadListeningData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final snapshot = await FirebaseFirestore.instance
        .collection('listening_sessions')
        .where('userId', isEqualTo: uid)
        .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
        .get();

    _dailyMinutes.clear();
    _trackPlayCounts.clear();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = (data['timestamp'] as Timestamp).toDate();
      final dayKey = DateTime(date.year, date.month, date.day);
      final durationSec = data['durationSeconds'] as int? ?? 0;

      _dailyMinutes.update(dayKey, (v) => v + (durationSec ~/ 60), ifAbsent: () => durationSec ~/ 60);

      final trackId = data['trackId'] as String?;
      if (trackId != null) {
        _trackPlayCounts.update(trackId, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    notifyListeners();
  }

  int get totalMinutesThisMonth {
    return _dailyMinutes.values.fold(0, (sum, min) => sum + min);
  }

  double get progressValue {
    final goalMinutes = _monthlyGoalHours * 60;
    return (totalMinutesThisMonth / goalMinutes).clamp(0.0, 1.0);
  }

  List<MapEntry<String, int>> get topTracks {
    final sorted = _trackPlayCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }
}