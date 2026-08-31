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
      settings: RecommendedGlassSettings.standard,
      quality: GlassQuality.standard,
      blendAmount: 10.0,
      child: CustomScrollView(
        slivers: [
          // 顶部标题
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

          // 热力图
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: const _CompletionHeatmapWidget(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 俯卧撑趋势
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

          // 平板支撑趋势
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

          // 有氧时长柱状图
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: const _CardioDurationChart(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 打卡完成率柱状图
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

class _ExerciseTrendChart extends StatelessWidget {
  final String exerciseName;
  final Color color;

  const _ExerciseTrendChart({
    required this.exerciseName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<WorkoutService>().logs;
    final exerciseLogs = logs
        .where((log) => log.exerciseName == exerciseName)
        .toList();

    if (exerciseLogs.isEmpty) {
      return _EmptyChartCard();
    }

    // 按日期聚合
    final Map<String, int> dailyTotals = {};
    for (final log in exerciseLogs) {
      final total = log.reps * log.sets;
      dailyTotals[log.date] = (dailyTotals[log.date] ?? 0) + total;
    }

    final sortedDates = dailyTotals.keys.toList()..sort();
    final spots = sortedDates.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      return FlSpot(index.toDouble(), dailyTotals[date]!.toDouble());
    }).toList();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$exerciseName 总次数趋势',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    side: AxisSide.left,
                    axisLabelsProvider: (viewportSpace) {
                      return viewportSpace.map((space) {
                        return AxisLabelWidget(
                          space: space,
                          isLabelShown: true,
                          label: Text(
                            (space.value / 5).round().toString(),
                            style: const TextStyle(color: AppTheme.textHint, fontSize: 10),
                          ),
                        );
                      }).toList();
                    },
                  ),
                  bottomTitles: AxisTitles(
                    side: AxisSide.bottom,
                    axisLabelsProvider: (viewportSpace) {
                      return viewportSpace.map((space) {
                        final index = space.value.toInt();
                        if (index >= 0 && index < sortedDates.length) {
                          return AxisLabelWidget(
                            space: space,
                            isLabelShown: true,
                            label: Text(
                              sortedDates[index].substring(5), // MM-DD
                              style: const TextStyle(color: AppTheme.textHint, fontSize: 10),
                            ),
                          );
                        }
                        return const DummyAxisLabel();
                      }).toList();
                    },
                  ),
                  rightTitles: const AxisTitles(side: AxisSide.right),
                  topTitles: const AxisTitles(side: AxisSide.top),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.1),
                    ),
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

  const _DurationTrendChart({
    required this.exerciseName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<WorkoutService>().logs;
    final exerciseLogs = logs
        .where((log) => log.exerciseName == exerciseName)
        .toList();

    if (exerciseLogs.isEmpty) {
      return _EmptyChartCard();
    }

    // 按日期取最大值
    final Map<String, int> dailyMax = {};
    for (final log in exerciseLogs) {
      if (log.durationSeconds > (dailyMax[log.date] ?? 0)) {
        dailyMax[log.date] = log.durationSeconds;
      }
    }

    final sortedDates = dailyMax.keys.toList()..sort();
    final spots = sortedDates.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      return FlSpot(index.toDouble(), dailyMax[date]!.toDouble());
    }).toList();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$exerciseName 最长时长趋势',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    side: AxisSide.left,
                    axisLabelsProvider: (viewportSpace) {
                      return viewportSpace.map((space) {
                        return AxisLabelWidget(
                          space: space,
                          isLabelShown: true,
                          label: Text(
                            '${(space.value / 60).round()}秒',
                            style: const TextStyle(color: AppTheme.textHint, fontSize: 10),
                          ),
                        );
                      }).toList();
                    },
                  ),
                  bottomTitles: AxisTitles(
                    side: AxisSide.bottom,
                    axisLabelsProvider: (viewportSpace) {
                      return viewportSpace.map((space) {
                        final index = space.value.toInt();
                        if (index >= 0 && index < sortedDates.length) {
                          return AxisLabelWidget(
                            space: space,
                            isLabelShown: true,
                            label: Text(
                              sortedDates[index].substring(5),
                              style: const TextStyle(color: AppTheme.textHint, fontSize: 10),
                            ),
                          );
                        }
                        return const DummyAxisLabel();
                      }).toList();
                    },
                  ),
                  rightTitles: const AxisTitles(side: AxisSide.right),
                  topTitles: const AxisTitles(side: AxisSide.top),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.1),
                    ),
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
    
    // 按周统计有氧时长
    final Map<String, int> weeklyMinutes = {};
    for (final log in logs) {
      if (log.workoutType.name == 'cardio') {
        final weekStart = log.date.substring(0, 7); // YYYY-MM
        final days = log.date.substring(8, 10);
        final weekKey = '$weekStart-W${(int.parse(days) ~/ 7).toString().padLeft(2, '0')}';
        weeklyMinutes[weekKey] = (weeklyMinutes[weekKey] ?? 0) + log.durationSeconds ~/ 60;
      }
    }

    if (weeklyMinutes.isEmpty) {
      return _EmptyChartCard();
    }

    final sortedWeeks = weeklyMinutes.keys.toList()..sort();
    final barGroups = sortedWeeks.asMap().entries.map((entry) {
      return BarGroupData(
        x: entry.key,
        barRods: [
          BarRodData(
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
          const Text(
            '每周有氧总时长',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(side: AxisSide.left),
                  bottomTitles: AxisTitles(
                    side: AxisSide.bottom,
                    axisLabelsProvider: (viewportSpace) {
                      return viewportSpace.map((space) {
                        final index = space.value.toInt();
                        if (index >= 0 && index < sortedWeeks.length) {
                          return AxisLabelWidget(
                            space: space,
                            isLabelShown: true,
                            label: Text(
                              sortedWeeks[index].substring(5),
                              style: const TextStyle(color: AppTheme.textHint, fontSize: 10),
                            ),
                          );
                        }
                        return const DummyAxisLabel();
                      }).toList();
                    },
                  ),
                  rightTitles: const AxisTitles(side: AxisSide.right),
                  topTitles: const AxisTitles(side: AxisSide.top),
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
    
    if (checkIns.isEmpty) {
      return _EmptyChartCard();
    }

    final last14Days = checkIns.take(14).toList().reversed.toList();
    final barGroups = last14Days.asMap().entries.map((entry) {
      return BarGroupData(
        x: entry.key,
        barRods: [
          BarRodData(
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
          const Text(
            '近14天完成率',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(side: AxisSide.left),
                  bottomTitles: AxisTitles(
                    side: AxisSide.bottom,
                    axisLabelsProvider: (viewportSpace) {
                      return viewportSpace.map((space) {
                        final index = space.value.toInt();
                        if (index >= 0 && index < last14Days.length) {
                          return AxisLabelWidget(
                            space: space,
                            isLabelShown: true,
                            label: Text(
                              last14Days[index].date.substring(5),
                              style: const TextStyle(color: AppTheme.textHint, fontSize: 10),
                            ),
                          );
                        }
                        return const DummyAxisLabel();
                      }).toList();
                    },
                  ),
                  rightTitles: const AxisTitles(side: AxisSide.right),
                  topTitles: const AxisTitles(side: AxisSide.top),
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
            Text(
              '暂无数据',
              style: TextStyle(color: AppTheme.textHint, fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              '完成训练后数据将在这里展示',
              style: TextStyle(color: AppTheme.textHint, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// fl_chart 需要的辅助类
class DummyAxisLabel extends AxisLabelWidget {
  const DummyAxisLabel() : super(space: 0, isLabelShown: false, label: Text(''));
}

class AxisLabelWidget extends AxisLabel {
  AxisLabelWidget({
    required double space,
    required bool isLabelShown,
    required Widget label,
  }) : super(
          space: space,
          isLabelShown: isLabelShown,
          label: label,
        );
}
