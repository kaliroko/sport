/// 数据统计页
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:metamorphosis_checkin/services/check_in_service.dart';
import 'package:metamorphosis_checkin/services/workout_service.dart';
import 'package:metamorphosis_checkin/services/user_profile_service.dart';
import 'package:metamorphosis_checkin/widgets/completion_heatmap.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';
import 'package:metamorphosis_checkin/utils/responsive_utils.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) => const _StatsScreenContent();
}

class _StatsScreenContent extends StatefulWidget {
  const _StatsScreenContent();

  @override
  State<_StatsScreenContent> createState() => _StatsScreenContentState();
}

class _StatsScreenContentState extends State<_StatsScreenContent> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AdaptiveLiquidGlassLayer(
      settings: const LiquidGlassSettings(blur: 0), // 无用的逐卡模糊，去掉可大幅降 GPU 负载
      quality: GlassQuality.standard,
      blendAmount: 10.0,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 20)),
                child: Text('运动记录', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 28), fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          SliverPadding(
            padding: ResponsiveUtils.scaleHorizontalEdgeInsets(context, 20),
            sliver: SliverToBoxAdapter(child: const _CheckInCalendar()),
          ),
          SliverToBoxAdapter(child: SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16))),
          SliverPadding(
            padding: ResponsiveUtils.scaleHorizontalEdgeInsets(context, 20),
            sliver: SliverToBoxAdapter(child: const _DailyCompletionChart()),
          ),
          SliverToBoxAdapter(child: SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16))),
          SliverPadding(
            padding: ResponsiveUtils.scaleHorizontalEdgeInsets(context, 20),
            sliver: SliverToBoxAdapter(child: const _WeightTrendChart()),
          ),
          SliverToBoxAdapter(child: SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16))),
          SliverPadding(
            padding: ResponsiveUtils.scaleHorizontalEdgeInsets(context, 20),
            sliver: SliverToBoxAdapter(child: const _CardioDurationChart()),
          ),
          SliverToBoxAdapter(child: SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16))),
          SliverPadding(
            padding: ResponsiveUtils.scaleHorizontalEdgeInsets(context, 20),
            sliver: SliverToBoxAdapter(child: const _CompletionHeatmapWidget()),
          ),
          SliverToBoxAdapter(child: SizedBox(height: ResponsiveUtils.bottomSafePadding(context))),
        ],
      ),
    );
  }
}

// ─── 打卡日历 ─────────────────────────────────────────────────────────────────
class _CheckInCalendar extends StatelessWidget {
  const _CheckInCalendar();

  @override
  Widget build(BuildContext context) {
    final checkIns = context.watch<CheckInService>().historicalCheckIns;
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    // DateTime.weekday: 1=周一 … 7=周日，周一作为第 0 列
    final leading = DateTime(year, month, 1).weekday - 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // 补齐成整周，行数随月份变化（不再固定 42 格）
    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;

    // 构建打卡数据 map
    final Map<String, double> rateMap = {};
    for (final c in checkIns) rateMap[c.date] = c.completionRate;

    // 按周切分：每行严格 7 格，空位为 null，保证与表头七列对齐。
    // 原来的 Wrap + 固定 36dp 单元格在不同宽度下每行格数会变（窄屏 6 格、
    // 宽屏 8 格），与表头的 7 列完全对不上，这里改为 Expanded 七等分。
    final weeks = <List<DateTime?>>[];
    for (int start = 0; start < totalCells; start += 7) {
      weeks.add(List<DateTime?>.generate(7, (i) {
        final dayOffset = start + i - leading;
        if (dayOffset < 0 || dayOffset >= daysInMonth) return null;
        return DateTime(year, month, dayOffset + 1);
      }));
    }

    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final cellSize = ResponsiveUtils.scaleSize(context, 34);

    return GlassCard(
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${year}年${month}月 打卡日历', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 16), fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        // 表头
        Row(children: weekdays.map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 11)))))).toList()),
        SizedBox(height: 6),
        // 日期网格：固定 7 列，列宽随屏幕自适应
        ...weeks.map((week) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: week
                .map((dt) => Expanded(child: Center(child: _buildDayCell(context, dt, now, rateMap, cellSize))))
                .toList(),
          ),
        )),
        SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _LegendDot(color: AppTheme.successColor, label: '100%'),
          SizedBox(width: 8),
          _LegendDot(color: AppTheme.primaryColor, label: '60-99%'),
          SizedBox(width: 8),
          _LegendDot(color: AppTheme.errorColor, label: '<60%'),
          SizedBox(width: 8),
          _LegendDot(color: Colors.white.withValues(alpha: 0.2), label: '未打卡'),
        ]),
      ]),
    );
  }

  /// 单个日期格子；[dt] 为 null 表示该列属于上/下月的空位。
  Widget _buildDayCell(
    BuildContext context,
    DateTime? dt,
    DateTime now,
    Map<String, double> rateMap,
    double cellSize,
  ) {
    if (dt == null) return SizedBox(width: cellSize, height: cellSize);

    final rate = rateMap[dt.toIso8601String().split('T').first];
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;

    Color cellColor;
    if (rate != null) {
      if (rate >= 100) {
        cellColor = AppTheme.successColor.withValues(alpha: 0.7);
      } else if (rate >= 60) {
        cellColor = AppTheme.primaryColor.withValues(alpha: 0.5);
      } else {
        cellColor = AppTheme.errorColor.withValues(alpha: 0.4);
      }
    } else {
      cellColor = Colors.white.withValues(alpha: 0.06);
    }

    return Container(
      width: cellSize,
      height: cellSize,
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(6),
        border: isToday ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Center(
        child: Text(
          '${dt.day}',
          style: TextStyle(
            color: isToday ? Colors.white : AppTheme.textSecondary,
            fontSize: ResponsiveUtils.scaleFont(context, 11),
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))), SizedBox(width: 4), Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 10))]);
  }
}

// ─── 近14天完成率趋势 ──────────────────────────────────────────────────────────
class _DailyCompletionChart extends StatelessWidget {
  const _DailyCompletionChart();

  @override
  Widget build(BuildContext context) {
    final checkIns = context.watch<CheckInService>().historicalCheckIns;
    if (checkIns.isEmpty) return _EmptyChartCard();

    final last14Days = checkIns.take(14).toList().reversed.toList();
    final spots = last14Days.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.completionRate)).toList();

    return GlassCard(
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('近14天完成率趋势', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 16), fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        SizedBox(
          height: ResponsiveUtils.scaleChartHeight(context, 180),
          child: LineChart(LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, _) => Text('${v.round()}%', style: TextStyle(color: AppTheme.textHint, fontSize: 10)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, _) {
                final idx = v.toInt();
                return idx >= 0 && idx < last14Days.length ? Text(last14Days[idx].date.substring(5), style: TextStyle(color: AppTheme.textHint, fontSize: 10)) : const Text('');
              })),
              rightTitles: const AxisTitles(), topTitles: const AxisTitles(),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: AppTheme.primaryColor, barWidth: 2, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: AppTheme.primaryColor.withValues(alpha: 0.1)))],
            minY: 0, maxY: 100,
          )),
        ),
      ]),
    );
  }
}

// ─── 体重趋势 ─────────────────────────────────────────────────────────────────
class _WeightTrendChart extends StatelessWidget {
  const _WeightTrendChart();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileService>().profile;
    // 简化版：显示当前体重 + 趋势提示（完整折线图需要更多数据）
    if (profile == null) return _EmptyChartCard();

    return GlassCard(
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('体重趋势', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 16), fontWeight: FontWeight.bold)),
          Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppTheme.successColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Text('目标: ${(profile.weightKg * 0.9).toStringAsFixed(1)}kg', style: TextStyle(color: AppTheme.successColor, fontSize: 12))),
        ]),
        SizedBox(height: 16),
        Row(children: [
          Expanded(child: _WeightStat(icon: Icons.monitor_weight, label: '当前体重', value: '${profile.weightKg.toStringAsFixed(1)}kg')),
          Expanded(child: _WeightStat(icon: Icons.trending_down, label: '目标体重', value: '${(profile.weightKg * 0.9).toStringAsFixed(1)}kg')),
          Expanded(child: _WeightStat(icon: Icons.arrow_downward, label: '还需减', value: '${(profile.weightKg * 0.1).toStringAsFixed(1)}kg')),
        ]),
      ]),
    );
  }
}

class _WeightStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _WeightStat({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: AppTheme.primaryColor, size: ResponsiveUtils.scaleIcon(context, 20)),
      SizedBox(height: 4),
      Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      SizedBox(height: 2),
      Text(value, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
    ]);
  }
}

// ─── 每周有氧总时长 ────────────────────────────────────────────────────────────
class _CardioDurationChart extends StatelessWidget {
  const _CardioDurationChart();

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<WorkoutService>().logs;
    final Map<String, int> weeklyMinutes = {};
    for (final log in logs) {
      if (log.workoutType.name == 'cardio') {
        final weekStart = log.date.substring(0, 7);
        final days = int.tryParse(log.date.substring(8, 10)) ?? 0;
        final weekKey = '$weekStart-W${(days ~/ 7).toString().padLeft(2, '0')}';
        weeklyMinutes[weekKey] = (weeklyMinutes[weekKey] ?? 0) + log.durationSeconds ~/ 60;
      }
    }
    if (weeklyMinutes.isEmpty) return _EmptyChartCard();

    final sortedWeeks = weeklyMinutes.keys.toList()..sort();
    final barGroups = sortedWeeks.asMap().entries.map((entry) {
      return BarChartGroupData(x: entry.key, barRods: [BarChartRodData(toY: weeklyMinutes[entry.value]!.toDouble(), color: AppTheme.primaryColor, width: 24, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]);
    }).toList();

    return GlassCard(
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('每周有氧总时长（分钟）', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 16), fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        SizedBox(
          height: ResponsiveUtils.scaleChartHeight(context, 180),
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, _) {
                final idx = v.toInt();
                return idx >= 0 && idx < sortedWeeks.length ? Text(sortedWeeks[idx].substring(5), style: TextStyle(color: AppTheme.textHint, fontSize: 10)) : const Text('');
              })),
              rightTitles: const AxisTitles(), topTitles: const AxisTitles(),
            ),
            borderData: FlBorderData(show: false),
            barGroups: barGroups, minY: 0,
          )),
        ),
      ]),
    );
  }
}

// ─── 完成率热力图 ─────────────────────────────────────────────────────────────
class _CompletionHeatmapWidget extends StatelessWidget {
  const _CompletionHeatmapWidget();

  @override
  Widget build(BuildContext context) {
    final checkIns = context.watch<CheckInService>().historicalCheckIns;
    final completionData = <String, double>{};
    for (final checkIn in checkIns) completionData[checkIn.date] = checkIn.completionRate;
    return CompletionHeatmap(completionData: completionData);
  }
}

class _EmptyChartCard extends StatelessWidget {
  const _EmptyChartCard();
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 24)),
      child: Center(child: Column(children: [
        Icon(Icons.insert_chart, size: ResponsiveUtils.scaleIcon(context, 48), color: AppTheme.textHint),
        SizedBox(height: 12),
        Text('暂无数据', style: TextStyle(color: AppTheme.textHint, fontSize: ResponsiveUtils.scaleFont(context, 14))),
        SizedBox(height: 4),
        Text('完成训练后数据将在这里展示', style: TextStyle(color: AppTheme.textHint, fontSize: ResponsiveUtils.scaleFont(context, 12))),
      ])),
    );
  }
}
