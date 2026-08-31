/// 训练页
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:metamorphosis_checkin/services/workout_service.dart';
import 'package:metamorphosis_checkin/services/user_profile_service.dart';
import 'package:metamorphosis_checkin/utils/constants.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkoutService()..init()),
        ChangeNotifierProvider(create: (_) => UserProfileService()..init()),
      ],
      child: const _WorkoutScreenContent(),
    );
  }
}

class _WorkoutScreenContent extends StatefulWidget {
  const _WorkoutScreenContent();

  @override
  State<_WorkoutScreenContent> createState() => _WorkoutScreenContentState();
}

class _WorkoutScreenContentState extends State<_WorkoutScreenContent> with TickerProviderStateMixin {
  int? _selectedExerciseIndex;
  bool _isTimerActive = false;
  int _timerSeconds = 0;
  late AnimationController _timerController;
  late Animation<double> _timerAnimation;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _timerAnimation = Tween<double>(begin: 0, end: 1).animate(_timerController);
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  /// 获取今日训练类型
  String getTodayWorkoutType() {
    final week = context.read<UserProfileService>().profile?.currentWeek ?? 1;
    final dayOfWeek = DateTime.now().weekday;
    
    if (dayOfWeek == 1 || dayOfWeek == 3 || dayOfWeek == 5) {
      return '力量训练';
    } else if (dayOfWeek == 2 || dayOfWeek == 4) {
      return '有氧训练';
    } else if (dayOfWeek == 6) {
      return '高强度有氧';
    } else {
      return '休息日';
    }
  }

  /// 获取今日训练动作
  List<MovementConfig> getTodayMovements() {
    final week = context.read<UserProfileService>().profile?.currentWeek ?? 1;
    return AppConstants.strengthMovements;
  }

  /// 开始计时
  void startTimer(int seconds) {
    setState(() {
      _timerSeconds = seconds;
      _isTimerActive = true;
    });
    _timerController.forward(from: 0);
    
    // 每秒递减
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isTimerActive) {
        setState(() {
          _timerSeconds--;
          if (_timerSeconds <= 0) {
            _isTimerActive = false;
            _timerController.stop();
          }
        });
        if (_isTimerActive) startTimer(_timerSeconds);
      }
    });
  }

  /// 停止计时
  void stopTimer() {
    setState(() {
      _isTimerActive = false;
    });
    _timerController.stop();
  }

  @override
  Widget build(BuildContext context) {
    final workoutType = getTodayWorkoutType();
    final movements = getTodayMovements();
    final week = context.watch<UserProfileService>().profile?.currentWeek ?? 1;

    return AdaptiveLiquidGlassLayer(
      settings: const LiquidGlassSettings(),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日训练',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: workoutType == '休息日' 
                            ? AppTheme.infoColor.withValues(alpha: 0.2)
                            : AppTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        workoutType,
                        style: TextStyle(
                          color: workoutType == '休息日' 
                              ? AppTheme.infoColor 
                              : AppTheme.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '第${week}周 ${['适应期', '减脂期', '塑形期', '冲刺期'][(week - 1) ~/ 2]}',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // 训练动作列表
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: workoutType == '休息日'
                ? _buildRestDayContent()
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final movement = movements[index];
                        final weekConfig = _getWeekConfig(movement, week);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ExerciseCard(
                            movement: movement,
                            weekConfig: weekConfig,
                            week: week,
                            onTap: () {
                              setState(() {
                                _selectedExerciseIndex = index;
                              });
                            },
                            onStart: () {
                              if (movement.type == MovementType.duration) {
                                final seconds = int.tryParse(weekConfig.split('×').last.replaceAll('秒', '')) ?? 40;
                                startTimer(seconds);
                              }
                            },
                          ),
                        );
                      },
                      childCount: movements.length,
                    ),
                  ),
          ),

          // 计时器浮动窗口
          if (_selectedExerciseIndex != null && _isTimerActive)
            SliverPersistentHeader(
              pinned: true,
              delegate: _TimerFloatingHeader(
                seconds: _timerSeconds,
                onStop: stopTimer,
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }

  String _getWeekConfig(MovementConfig movement, int week) {
    if (week <= 2) return movement.week1;
    if (week <= 4) return movement.week3;
    if (week <= 6) return movement.week5;
    return movement.week7;
  }

  SliverToBoxAdapter _buildRestDayContent() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: GlassCard(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Text('😴', style: TextStyle(fontSize: 48)),
              SizedBox(height: 16),
              Text(
                '今天是周日，好好休息！',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                '可以散步或拉伸10分钟，但不要剧烈运动',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final MovementConfig movement;
  final String weekConfig;
  final int week;
  final VoidCallback onTap;
  final VoidCallback onStart;

  const _ExerciseCard({
    required this.movement,
    required this.weekConfig,
    required this.week,
    required this.onTap,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  movement.type == MovementType.duration 
                      ? Icons.timer 
                      : Icons.fitness_center,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '锻炼: ${movement.targetMuscle}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  weekConfig,
                  style: const TextStyle(
                    color: AppTheme.secondaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '动作要领: ${movement.description}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: movement.commonMistakes.map((mistake) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '✗ $mistake',
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: 10,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                GlassButton.custom(
                  onTap: onTap,
                  width: double.infinity,
                  height: 48,
                  child: const Text(
                    '开始训练',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (movement.type == MovementType.duration)
                GlassButton.custom(
                  onTap: onStart,
                  height: 48,
                  child: const Text(
                    '计时器',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerFloatingHeader extends SliverPersistentHeaderDelegate {
  final int seconds;
  final VoidCallback onStop;

  _TimerFloatingHeader({
    required this.seconds,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.timer, color: AppTheme.warningColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '组间休息',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    '$seconds 秒',
                    style: const TextStyle(
                      color: AppTheme.warningColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            GlassButton.custom(
              onTap: onStop,
              height: 48,
              child: const Text(
                '完成',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 80;

  @override
  double get minExtent => 80;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}
