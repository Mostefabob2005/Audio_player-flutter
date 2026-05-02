// lib/presentation/pages/home/stats_tab.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/listening_stats_model.dart';
import '../../../data/repositories/stats_repository.dart';
import '../../providers/auth_provider.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> with AutomaticKeepAliveClientMixin {
  final StatsRepository _statsRepo = StatsRepository();
  ListeningStatsModel? _stats;
  int _monthlyGoal = AppConstants.defaultMonthlyGoalHours;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => false; // Always reload when switching tabs

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload whenever this tab becomes active
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;

    final stats = await _statsRepo.fetchStats(uid);
    final goal = await _statsRepo.getMonthlyGoalHours();

    if (mounted) {
      setState(() {
        _stats = stats;
        _monthlyGoal = goal;
        _isLoading = false;
      });
    }
  }

  Future<void> _setGoal(int hours) async {
    await _statsRepo.setMonthlyGoalHours(hours);
    setState(() => _monthlyGoal = hours);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = context.watch<AuthProvider>().user;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    final stats = _stats ?? ListeningStatsModel.empty('');
    final monthMinutes = stats.currentMonthMinutes;
    final monthHours = monthMinutes / 60.0;
    final progress = (monthHours / _monthlyGoal).clamp(0.0, 1.0);
    final dailyData = stats.currentMonthDailyStats;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome
            RichText(
              text: TextSpan(
                text: 'Welcome, ',
                style: Theme.of(context).textTheme.titleLarge,
                children: [
                  TextSpan(
                    text: user?.fullName ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Total Listening Card
            _StatCard(
              icon: Icons.headphones_rounded,
              label: 'Total Listening Time',
              value: '${stats.totalHours}h ${stats.remainingMinutes}m',
            ),
            const SizedBox(height: 12),

            // This month card
            _StatCard(
              icon: Icons.calendar_month_rounded,
              label: 'This Month',
              value: '${monthHours.toStringAsFixed(1)}h',
            ),
            const SizedBox(height: 16),

            // Monthly Progress
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Monthly Goal',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        _GoalDropdown(
                          value: _monthlyGoal,
                          onChanged: _setGoal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: AppTheme.backgroundDark,
                        valueColor: const AlwaysStoppedAnimation(
                            AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${monthHours.toStringAsFixed(1)}h / ${_monthlyGoal}h',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: progress >= 1.0
                                    ? AppTheme.primaryColor
                                    : AppTheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Daily Histogram
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minutes per Day — This Month',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pull down to refresh',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: dailyData.every((d) => d.seconds == 0)
                          ? const Center(
                              child: Text(
                                'No listening data yet.\nPlay a surah to start tracking!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppTheme.onSurfaceVariant),
                              ),
                            )
                          : _DailyBarChart(dailyData: dailyData),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-Widgets ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.onSurfaceVariant)),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _GoalDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: value,
      underline: const SizedBox(),
      dropdownColor: AppTheme.cardDark,
      style: const TextStyle(color: AppTheme.primaryColor),
      items: AppConstants.goalOptions
          .map((h) => DropdownMenuItem(value: h, child: Text('$h h')))
          .toList(),
      onChanged: (v) => v != null ? onChanged(v) : null,
    );
  }
}

class _DailyBarChart extends StatelessWidget {
  final List<DailyListeningModel> dailyData;

  const _DailyBarChart({required this.dailyData});

  @override
  Widget build(BuildContext context) {
    final maxMinutes =
        dailyData.map((d) => d.seconds ~/ 60).fold(0, (a, b) => a > b ? a : b);
    final maxY = (maxMinutes * 1.3).clamp(10.0, double.infinity).toDouble();

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${rod.toY.toInt()} min',
              const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if ((idx + 1) % 5 != 0) return const SizedBox();
                return Text(
                  '${idx + 1}',
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.onSurfaceVariant),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppTheme.cardDark, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(dailyData.length, (i) {
          final minutes = (dailyData[i].seconds ~/ 60).toDouble();
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: minutes,
                color: minutes > 0
                    ? AppTheme.primaryColor
                    : AppTheme.cardDark,
                width: 8,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
