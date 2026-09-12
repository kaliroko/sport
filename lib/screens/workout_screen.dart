/// 训练页
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:metamorphosis_checkin/services/user_profile_service.dart';
import 'package:metamorphosis_checkin/utils/constants.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';
import 'package:metamorphosis_checkin/utils/responsive_utils.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _WorkoutScreenContent();
  }
}

class _WorkoutScreenContent extends StatefulWidget {
  const _WorkoutScreenContent();

  @override
  State<_WorkoutScreenContent> createState() => _WorkoutScreenContentState();
}

class _WorkoutScreenContentState extends State<_WorkoutScreenContent>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  int? _selectedExerciseIndex;
  bool _isTimerActive = false;
  int _timerSeconds = 0;
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  String getTodayWorkoutType() {
    final dayOfWeek = DateTime.now().weekday;
    if (dayOfWeek == 1 || dayOfWeek == 3 || dayOfWeek == 5) return '力量训练';
    if (dayOfWeek == 2 || dayOfWeek == 4) return '有氧训练';
    if (dayOfWeek == 6) return '高强度有氧';
    return '休息日';
  }

  List<MovementConfig> getTodayMovements() {
    return AppConstants.strengthMovements;
  }

  void startTimer(int seconds) {
    setState(() {
      _timerSeconds = seconds;
      _isTimerActive = true;
    });
    _timerController.forward(from: 0);
    _tickTimer();
  }

  void _tickTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isTimerActive) {
        setState(() {
          _timerSeconds--;
          if (_timerSeconds <= 0) {
            _isTimerActive = false;
            _timerController.stop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('计时完成！')],
                ),
                backgroundColor: AppTheme.successColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
        if (_isTimerActive) _tickTimer();
      }
    });
  }

  void stopTimer() {
    setState(() => _isTimerActive = false);
    _timerController.stop();
  }

  void _startExercise(MovementConfig movement, String weekConfig) {
    setState(() => _selectedExerciseIndex = AppConstants.strengthMovements.indexOf(movement));
    if (movement.type == MovementType.duration) {
      final match = RegExp(r'(\d+)秒').firstMatch(weekConfig);
      final seconds = int.tryParse(match?.group(1) ?? '40') ?? 40;
      startTimer(seconds);
    }
    // reps 类型直接显示完成弹窗
    if (movement.type == MovementType.reps) {
      _showRepStartDialog(movement, weekConfig);
    }
  }

  Future<void> _showRepStartDialog(MovementConfig movement, String config) async {
    await GlassDialog.show<void>(
      context: context,
      title: movement.name,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('目标: $config', style: TextStyle(color: AppTheme.secondaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          Text('动作要领: ${movement.description}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          if (movement.commonMistakes.isNotEmpty) ...[
            SizedBox(height: 8),
            Text('注意:', style: TextStyle(color: AppTheme.errorColor, fontSize: 12, fontWeight: FontWeight.w500)),
            ...movement.commonMistakes.map((m) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text('✗ $m', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            )),
          ],
        ],
      ),
      actions: [
        GlassDialogAction(
          label: '了解了',
          isPrimary: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final workoutType = getTodayWorkoutType();
    final movements = getTodayMovements();
    final week = context.watch<UserProfileService>().profile?.currentWeek ?? 1;
    final phaseName = ['适应期', '减脂期', '塑形期', '冲刺期'][(week - 1) ~/ 2 % 4];

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
                padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('今日训练', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 26), fontWeight: FontWeight.bold)),
                    SizedBox(height: ResponsiveUtils.scaleSpacing(context, 10)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.scalePadding(context, 16), vertical: 8),
                      decoration: BoxDecoration(
                        color: workoutType == '休息日'
                            ? AppTheme.infoColor.withValues(alpha: 0.2)
                            : AppTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        workoutType,
                        style: TextStyle(
                          color: workoutType == '休息日' ? AppTheme.infoColor : AppTheme.primaryColor,
                          fontSize: ResponsiveUtils.scaleFont(context, 14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '第${week}周 · $phaseName',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 13)),
                    ),
                    SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
                  ],
                ),
              ),
            ),
          ),

          // 训练动作列表
          if (workoutType == '休息日')
            SliverPadding(
              padding: ResponsiveUtils.scaleHorizontalEdgeInsets(context, 16),
              sliver: SliverToBoxAdapter(child: _buildRestDayContent()),
            )
          else
            SliverPadding(
              padding: ResponsiveUtils.scaleHorizontalEdgeInsets(context, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final movement = movements[index];
                    final weekConfig = _getWeekConfig(movement, week);
                    return Padding(
                      padding: EdgeInsets.only(bottom: ResponsiveUtils.scaleSpacing(context, 12)),
                      child: _ExerciseCard(
                        movement: movement,
                        weekConfig: weekConfig,
                        onTap: () => _startExercise(movement, weekConfig),
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

          SliverToBoxAdapter(child: SizedBox(height: ResponsiveUtils.bottomSafePadding(context))),
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

  Widget _buildRestDayContent() {
    return GlassCard(
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 24)),
      child: Column(
        children: [
          Text('😴', style: TextStyle(fontSize: ResponsiveUtils.scaleFont(context, 48))),
          SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
          Text('今天是周日，好好休息！', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, textAlign: TextAlign.center)),
          SizedBox(height: 8),
          Text('可以散步或拉伸10分钟，但不要剧烈运动', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final MovementConfig movement;
  final String weekConfig;
  final VoidCallback onTap;

  const _ExerciseCard({required this.movement, required this.weekConfig, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(movement.type == MovementType.duration ? Icons.timer : Icons.fitness_center, color: AppTheme.primaryColor, size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(movement.name, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text('锻炼: ${movement.targetMuscle}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.secondaryColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: Text(weekConfig, style: TextStyle(color: AppTheme.secondaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text('要领: ${movement.description}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          if (movement.commonMistakes.isNotEmpty) ...[
            SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: movement.commonMistakes.map((m) => Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.errorColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('✗ $m', style: TextStyle(color: AppTheme.errorColor, fontSize: 10)),
              )).toList(),
            ),
          ],
          SizedBox(height: 12),
          GlassButton.custom(
            onTap: onTap,
            width: double.infinity,
            height: ResponsiveUtils.scaleButtonHeight(context, 46),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(movement.type == MovementType.duration ? Icons.timer : Icons.fitness_center, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  movement.type == MovementType.duration ? '开始计时' : '开始训练',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerFloatingHeader extends SliverPersistentHeaderDelegate {
  final int seconds;
  final VoidCallback onStop;

  _TimerFloatingHeader({required this.seconds, required this.onStop});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GlassCard(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.timer, color: AppTheme.warningColor),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('组间休息', style: TextStyle(color: Colors.white, fontSize: 14)),
                Text('$seconds 秒', style: TextStyle(color: AppTheme.warningColor, fontSize: 24, fontWeight: FontWeight.bold)),
              ]),
            ),
            GlassButton.custom(
              onTap: onStop,
              height: 48,
              child: const Text('完成', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    final old = oldDelegate as _TimerFloatingHeader;
    return seconds != old.seconds;
  }
}