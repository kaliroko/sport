/// 首页 - 每日打卡
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:metamorphosis_checkin/services/check_in_service.dart';
import 'package:metamorphosis_checkin/utils/constants.dart';
import 'package:metamorphosis_checkin/utils/md3_spring_curve.dart';
import 'package:metamorphosis_checkin/widgets/task_card.dart';
import 'package:metamorphosis_checkin/widgets/progress_ring.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';
import 'package:metamorphosis_checkin/utils/responsive_utils.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeScreenContent();
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  late AnimationController _checkController;
  late Animation<double> _checkAnimation;
  bool _showCelebration = false;
  String? _lastCheckedTask;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: const Md3StandardSpring(),
    );
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  void _showTaskSuccess(BuildContext context, String taskName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: ResponsiveUtils.scaleSpacing(context, 8)),
            Text('$taskName 打卡成功！', style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 一键完成今日所有打卡
  Future<void> _completeAllCheckIn(CheckInService service) async {
    await service.completeAllTasks();
    setState(() => _showCelebration = true);
    _checkController.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showCelebration = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final service = context.watch<CheckInService>();
    final tasks = AppConstants.dailyTasks;
    final today = DateTime.now();
    final dateStr = '${today.year}年${today.month}月${today.day}日';
    final weekday = ['日', '一', '二', '三', '四', '五', '六'][today.weekday];
    final isAllComplete = service.completionRate >= 100;
    final checkedCount = tasks.where((t) => _isTaskChecked(service, t.id)).length;

    return Stack(
      children: [
        AdaptiveLiquidGlassLayer(
          settings: const LiquidGlassSettings(),
          quality: GlassQuality.standard,
          blendAmount: 10.0,
          child: CustomScrollView(
            slivers: [
              // ─── 顶部区域 ───
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 日期 + 周
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateStr,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: ResponsiveUtils.scaleFont(context, 13),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.scalePadding(context, 10),
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '周$weekday',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: ResponsiveUtils.scaleFont(context, 11),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 6)),

                        // 欢迎语
                        Text(
                          '今天也要加油哦！💪',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveUtils.scaleFont(context, 24),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isAllComplete)
                          Text(
                            '坚持就是胜利，你已经很棒了！',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: ResponsiveUtils.scaleFont(context, 13),
                            ),
                          )
                        else
                          Text(
                            '太棒了！今日目标全部达成 🎉',
                            style: TextStyle(
                              color: AppTheme.successColor,
                              fontSize: ResponsiveUtils.scaleFont(context, 13),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),

                        // ─── 融合卡片：环形图 + 统计 ───
                        GlassCard(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.scalePadding(context, 20),
                            vertical: ResponsiveUtils.scalePadding(context, 16),
                          ),
                          child: Row(
                            children: [
                              // 完成率环形图（紧凑）
                              ScaleTransition(
                                scale: _checkAnimation,
                                child: ProgressRing(
                                  progress: service.completionRate,
                                  size: ResponsiveUtils.scaleFont(context, 88),
                                  strokeWidth: ResponsiveUtils.scaleFont(context, 7),
                                  foregroundColor: isAllComplete
                                      ? AppTheme.successColor
                                      : AppTheme.primaryColor,
                                  labelText: '${service.completionRate.round()}%',
                                ),
                              ),
                              SizedBox(width: ResponsiveUtils.scaleSpacing(context, 16)),
                              // 统计数据
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _StatRow(
                                      icon: Icons.local_fire_department,
                                      iconColor: AppTheme.warningColor,
                                      label: '连续打卡',
                                      value: '${service.getConsecutiveDays()}天',
                                      sub: '最佳 ${service.getBestStreak()}天',
                                    ),
                                    SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
                                    _StatRow(
                                      icon: Icons.check_circle,
                                      iconColor: AppTheme.successColor,
                                      label: '今日完成',
                                      value: '$checkedCount / ${tasks.length}',
                                      sub: isAllComplete ? '全部达成 ✅' : '还差 ${tasks.length - checkedCount}项',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),

                        // 一键打卡按钮
                        if (!isAllComplete)
                          GlassButton.custom(
                            onTap: () => _completeAllCheckIn(service),
                            width: double.infinity,
                            height: ResponsiveUtils.scaleButtonHeight(context, 48),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '✨ 一键完成今日打卡',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: ResponsiveUtils.scaleFont(context, 15),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 12)),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── 任务列表 ───
              SliverPadding(
                padding: ResponsiveUtils.scaleHorizontalEdgeInsets(context, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = tasks[index];
                      final isChecked = _isTaskChecked(service, task.id);
                      return Padding(
                        padding: EdgeInsets.only(bottom: ResponsiveUtils.scaleSpacing(context, 10)),
                        child: TaskCard(
                          height: 80,
                          task: task,
                          isChecked: isChecked,
                          onToggle: () {
                            service.toggleTask(task.id, !isChecked);
                            setState(() => _lastCheckedTask = task.name);
                            if (!isChecked) {
                              _showTaskSuccess(context, task.name);
                              final remaining = tasks
                                  .where((t) => !_isTaskChecked(service, t.id))
                                  .length;
                              if (remaining == 0) {
                                setState(() => _showCelebration = true);
                                _checkController.forward();
                                Future.delayed(const Duration(seconds: 2), () {
                                  if (mounted) setState(() => _showCelebration = false);
                                });
                              }
                            }
                          },
                        ),
                      );
                    },
                    childCount: tasks.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: ResponsiveUtils.bottomSafePadding(context)),
              ),
            ],
          ),
        ),

        // 完成庆祝动画
        if (_showCelebration)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: AnimatedBuilder(
                  animation: _checkAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _checkAnimation.value,
                      child: GlassCard(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.scalePadding(context, 40),
                          vertical: ResponsiveUtils.scalePadding(context, 32),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🎉', style: TextStyle(fontSize: ResponsiveUtils.scaleFont(context, 64))),
                            SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
                            Text(
                              '今日打卡完成！',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveUtils.scaleFont(context, 24),
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
                            Text(
                              '你太棒了，明天继续！',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: ResponsiveUtils.scaleFont(context, 14),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _isTaskChecked(CheckInService service, String taskId) {
    final checkIn = service.todayCheckIn;
    if (checkIn == null) return false;
    switch (taskId) {
      case 'water_morning':
        return checkIn.waterMorning;
      case 'face_massage_morning':
        return checkIn.faceMassageMorning;
      case 'breakfast_healthy':
        return checkIn.breakfastHealthy;
      case 'lunch_controlled':
        return checkIn.lunchControlled;
      case 'water_2l':
        return checkIn.water2l;
      case 'no_snacks':
        return checkIn.noSnacks;
      case 'dinner_controlled':
        return checkIn.dinnerControlled;
      case 'workout_done':
        return checkIn.workoutDone;
      case 'face_massage_night':
        return checkIn.faceMassageNight;
      case 'sleep_before_23':
        return checkIn.sleepBefore23;
      default:
        return false;
    }
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;

  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: ResponsiveUtils.scaleIcon(context, 16)),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: ResponsiveUtils.scaleFont(context, 11),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveUtils.scaleFont(context, 14),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}