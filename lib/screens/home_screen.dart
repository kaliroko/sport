/// 首页 - 每日打卡
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:metamorphosis_checkin/services/check_in_service.dart';
import 'package:metamorphosis_checkin/utils/constants.dart';
import 'package:metamorphosis_checkin/widgets/task_card.dart';
import 'package:metamorphosis_checkin/widgets/progress_ring.dart';
import 'package:metamorphosis_checkin/widgets/stat_card.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CheckInService()..init(),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
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
    final service = context.watch<CheckInService>();
    final tasks = AppConstants.dailyTasks;
    final today = DateTime.now();
    final dateStr = '${today.year}年${today.month}月${today.day}日';
    final weekday = ['日', '一', '二', '三', '四', '五', '六'][today.weekday];
    final isAllComplete = service.completionRate >= 100;

    return Stack(
      children: [
        AdaptiveLiquidGlassLayer(
          settings: RecommendedGlassSettings.standard,
          quality: GlassQuality.standard,
          blendAmount: 10.0,
          child: CustomScrollView(
            slivers: [
              // 顶部区域
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 日期和星期
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateStr,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '周$weekday',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // 欢迎语
                        const Text(
                          '今天也要加油哦！💪',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAllComplete ? '太棒了！今日目标全部达成 🎉' : '坚持就是胜利，你已经很棒了！',
                          style: TextStyle(
                            color: isAllComplete ? AppTheme.successColor : AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: isAllComplete ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 统计卡片行
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: '连续打卡',
                                value: '${service.getConsecutiveDays()}天',
                                icon: Icons.local_fire_department,
                                iconColor: AppTheme.warningColor,
                                subtitle: '最佳记录: ${service.getBestStreak()}天',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                title: '今日完成',
                                value: '${service.completionRate.round()}%',
                                icon: Icons.check_circle,
                                iconColor: AppTheme.successColor,
                                subtitle: '已完成 ${tasks.where((t) => _isTaskChecked(service, t.id)).length}/10项',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 完成率环形图
                        Center(
                          child: Column(
                            children: [
                              ScaleTransition(
                                scale: _checkAnimation,
                                child: ProgressRing(
                                  progress: service.completionRate,
                                  size: 120,
                                  strokeWidth: 10,
                                  foregroundColor: isAllComplete
                                      ? AppTheme.successColor
                                      : AppTheme.primaryColor,
                                  labelText: '${service.completionRate.round()}%',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '今日完成率',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 一键打卡按钮
                        if (!isAllComplete)
                          GlassButton.custom(
                            onTap: () => _completeAllCheckIn(service),
                            width: double.infinity,
                            height: 52,
                            child: const Text(
                              '✨ 一键完成今日打卡',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // 任务列表
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = tasks[index];
                      final isChecked = _isTaskChecked(service, task.id);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TaskCard(
                          task: task,
                          isChecked: isChecked,
                          onToggle: () {
                            service.toggleTask(task.id, !isChecked);
                            // 检查是否全部完成
                            if (!isChecked) {
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
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 32,
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🎉', style: TextStyle(fontSize: 64)),
                            SizedBox(height: 16),
                            Text(
                              '今日打卡完成！',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              '你太棒了，明天继续！',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
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
