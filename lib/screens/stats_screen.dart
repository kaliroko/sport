/// 数据统计页
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:metamorphosis_checkin/services/check_in_service.dart';
import 'package:metamorphosis_checkin/services/workout_service.dart';
import 'package:metamorphosis_checkin/widgets/completion_heatmap.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CheckInService()..init()),
        ChangeNotifierProvider(create: (_) => WorkoutService()..init()),
      ],
      child: const _StatsScreenContent(),
    );
  }
}

class _StatsScreenContent extends StatelessWidget {
  const _StatsScreenContent();

  @override
  Widget build(BuildContext context) {
    return AdaptiveLiquidGlassLayer(
      settings: const LiquidGlassSettings(),
      quality: GlassQuality.standard,
      blendAmount: 10.0,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: const Text(
                  '运动记录',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: const _CompletionHeatmapWidget(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: const _ExerciseTrendChart(
                exerciseName: '标准俯卧撑',
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: const _DurationTrendChart(
                exerciseName: '平板支撑',
                color: AppTheme.secondaryColor,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: const _CardioDurationChart(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: const _DailyCompletionChart(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _CompletionHeatmapWidget extends StatelessWidget {
  const _CompletionHeatmapWidget();

  @override
  Widget build(BuildContext context) {
    final checkIns = context.watch<CheckInService>().historicalCheckIns;
    final completionData = <String, double>{};
    for (final checkIn in checkIns) {
      completionData[checkIn.date] = checkIn.completionRate;
    }
    return CompletionHeatmap(completionData: completionData);
  }
}

// fl_chart 0.65+ 辅助函数
Widget _makeTitleWidget(String Function(double) builder) {
  return (double value, TitleMeta meta) => Text(
    builder(value),
    style: const TextStyle(color: AppTheme.textHint, fontSize: 10),
  );
}

class _ExerciseTrendChart extends StatelessWidget {
  final String exerciseName;
  final Color color;
  const _ExerciseTrendChart({required this.exerciseName, required this.color});

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<WorkoutService>().logs;
    final exerciseLogs = logs.where((log) => log.exerciseName == exerciseName).toList();
    if (exerciseLogs.isEmpty) return _EmptyChartCard();

    final Map<String, int> dailyTotals = {};
    for (final log in exerciseLogs) {
      final total = log.reps * log.sets;
      dailyTotals[log.date] = (dailyTotals[log.date] ?? 0) + total;
    }
    final sortedDates = dailyTotals.keys.toList()..sort();
    final spots = sortedDates.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), dailyTotals[entry.value]!.toDouble());
    }).toList();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$exerciseName 总次数趋势',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: _makeTitleWidget((v) => (v / 5).toStringAsFixed(0)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: _makeTitleWidget((v) {
                        final index = v.toInt();
                        return index >= 0 && index < sortedDates.length ? sortedDates[index].substring(5) : '';
                      }),
                    ),
                  ),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.1)),
                  ),
                ],
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationTrendChart extends StatelessWidget {
  final String exerciseName;
  final Color color;
  const _DurationTrendChart({required this.exerciseName, required this.color});

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<WorkoutService>().logs;
    final exerciseLogs = logs.where((log) => log.exerciseName == exerciseName).toList();
    if (exerciseLogs.isEmpty) return _EmptyChartCard();

    final Map<String, int> dailyMax = {};
    for (final log in exerciseLogs) {
      if (log.durationSeconds > (dailyMax[log.date] ?? 0)) {
        dailyMax[log.date] = log.durationSeconds;
      }
    }
    final sortedDates = dailyMax.keys.toList()..sort();
    final spots = sortedDates.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), dailyMax[entry.value]!.toDouble());
    }).toList();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$exerciseName 最长时长趋势',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: _makeTitleWidget((v) => (v / 60).round().toString()),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: _makeTitleWidget((v) {
                        final index = v.toInt();
                        return index >= 0 && index < sortedDates.length ? sortedDates[index].substring(5) : '';
                      }),
                    ),
                  ),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.1)),
                  ),
                ],
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardioDurationChart extends StatelessWidget {
  const _CardioDurationChart();

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<WorkoutService>().logs;
    final Map<String, int> weeklyMinutes = {};
    for (final log in logs) {
      if (log.workoutType.name == 'cardio') {
        final weekStart = log.date.substring(0, 7);
        final days = log.date.substring(8, 10);
        final weekKey = '$weekStart-W${(int.parse(days) ~/ 7).toString().padLeft(2, '0')}';
        weeklyMinutes[weekKey] = (weeklyMinutes[weekKey] ?? 0) + log.durationSeconds ~/ 60;
      }
    }
    if (weeklyMinutes.isEmpty) return _EmptyChartCard();

    final sortedWeeks = weeklyMinutes.keys.toList()..sort();
    final barGroups = sortedWeeks.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: weeklyMinutes[entry.value]!.toDouble(),
            color: AppTheme.primaryColor,
            width: 24,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('每周有氧总时长',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: _makeTitleWidget((v) {
                        final index = v.toInt();
                        return index >= 0 && index < sortedWeeks.length ? sortedWeeks[index].substring(5) : '';
                      }),
                    ),
                  ),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyCompletionChart extends StatelessWidget {
  const _DailyCompletionChart();

  @override
  Widget build(BuildContext context) {
    final checkIns = context.watch<CheckInService>().historicalCheckIns;
    if (checkIns.isEmpty) return _EmptyChartCard();

    final last14Days = checkIns.take(14).toList().reversed.toList();
    final barGroups = last14Days.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.completionRate,
            color: entry.value.completionRate >= 80
                ? AppTheme.successColor
                : entry.value.completionRate >= 50
                    ? AppTheme.warningColor
                    : AppTheme.errorColor,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('近14天完成率',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: _makeTitleWidget((v) {
                        final index = v.toInt();
                        return index >= 0 && index < last14Days.length ? last14Days[index].date.substring(5) : '';
                      }),
                    ),
                  ),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
                minY: 0,
                maxY: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChartCard extends StatelessWidget {
  const _EmptyChartCard();
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.insert_chart, size: 48, color: AppTheme.textHint),
            SizedBox(height: 12),
            Text('暂无数据', style: TextStyle(color: AppTheme.textHint, fontSize: 14)),
            SizedBox(height: 4),
            Text('完成训练后数据将在这里展示', style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}