// lib/data/models/listening_stats_model.dart

class DailyListeningModel {
  final DateTime date;
  final int minutes;

  const DailyListeningModel({required this.date, required this.minutes});

  factory DailyListeningModel.fromMap(Map<String, dynamic> map) =>
      DailyListeningModel(
        date: DateTime.parse(map['date'] as String),
        minutes: map['minutes'] as int,
      );

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String().substring(0, 10),
        'minutes': minutes,
      };
}

class ListeningStatsModel {
  final String userId;
  final int totalMinutes;
  final List<DailyListeningModel> dailyStats;
  final Map<String, int> trackPlayCounts; // trackId -> count

  const ListeningStatsModel({
    required this.userId,
    required this.totalMinutes,
    required this.dailyStats,
    required this.trackPlayCounts,
  });

  int get totalHours => totalMinutes ~/ 60;
  int get remainingMinutes => totalMinutes % 60;

  /// Minutes listened in the current month
  int get currentMonthMinutes {
    final now = DateTime.now();
    return dailyStats
        .where((d) => d.date.year == now.year && d.date.month == now.month)
        .fold(0, (sum, d) => sum + d.minutes);
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
        orElse: () => DailyListeningModel(date: date, minutes: 0),
      );
      return found;
    });
  }

  factory ListeningStatsModel.empty(String userId) => ListeningStatsModel(
        userId: userId,
        totalMinutes: 0,
        dailyStats: [],
        trackPlayCounts: {},
      );
}
