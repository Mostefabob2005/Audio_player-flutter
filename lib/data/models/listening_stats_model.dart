// lib/data/models/listening_stats_model.dart

class DailyListeningModel {
  final DateTime date;
  final int seconds;

  const DailyListeningModel({required this.date, required this.seconds});

  factory DailyListeningModel.fromMap(Map<String, dynamic> map) =>
      DailyListeningModel(
        date: DateTime.parse(map['date'] as String),
        seconds: map['seconds'] as int,
      );

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String().substring(0, 10),
        'seconds': seconds,
      };
}

class ListeningStatsModel {
  final String userId;
  final int totalSeconds;
  final List<DailyListeningModel> dailyStats;
  final Map<String, int> trackPlayCounts; // trackId -> count

  const ListeningStatsModel({
    required this.userId,
    required this.totalSeconds,
    required this.dailyStats,
    required this.trackPlayCounts,
  });

  int get totalHours => totalSeconds ~/ 3600;
  int get remainingMinutes => (totalSeconds % 3600) ~/ 60;

  /// Minutes listened in the current month
  int get currentMonthMinutes {
    final now = DateTime.now();
    return dailyStats
        .where((d) => d.date.year == now.year && d.date.month == now.month)
        .fold(0, (sum, d) => sum + (d.seconds ~/ 60));
  }

  /// Daily stats for current month, padded for all days
  List<DailyListeningModel> get currentMonthDailyStats {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return List.generate(daysInMonth, (i) {
      final date = DateTime(now.year, now.month, i + 1);
      final found = dailyStats.firstWhere(
        (d) => d.date.year == date.year &&
               d.date.month == date.month &&
               d.date.day == date.day,
        orElse: () => DailyListeningModel(date: date, seconds: 0),
      );
      return found;
    });
  }

  factory ListeningStatsModel.empty(String userId) => ListeningStatsModel(
        userId: userId,
        totalSeconds: 0,
        dailyStats: [],
        trackPlayCounts: {},
      );
}
