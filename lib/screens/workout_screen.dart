/// 训练页
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:metamorphosis_checkin/services/user_profile_service.dart';
import 'package:metamorphosis_checkin/services/workout_plan_service.dart';
import 'package:metamorphosis_checkin/utils/constants.dart';
import 'package:metamorphosis_checkin/models/workout_plan.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';
import 'package:metamorphosis_checkin/utils/responsive_utils.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) => const _WorkoutScreenContent();
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
    _timerController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  // ─── 卡路里估算（kcal）─────────────────────────────────────────────────────
  double estimateCalories(MovementConfig movement, int durationMinutes) {
    // MET 值参考（每小时 kcal/kg）× 体重(kg) × 小时数
    final metValues = {
      '胸': 3.5, '三头肌': 3.0, '肩': 3.0,
      '腿': 4.0, '臀': 3.5, '大腿': 4.0,
      '核心': 3.5, '上腹': 3.5, '下腹': 3.5,
      '腹斜肌': 3.5, '背部': 3.0, '小腿': 3.0,
      '全身': 5.0, '心肺': 5.0,
    };
    double met = 3.5;
    for (final key in metValues.keys) {
      if (movement.targetMuscle.contains(key)) { met = metValues[key]!; break; }
    }
    final profile = context.read<UserProfileService>().profile;
    final weight = profile?.weightKg ?? 65;
    return met * weight * (durationMinutes / 60);
  }

  void startTimer(int seconds) {
    setState(() { _timerSeconds = seconds; _isTimerActive = true; });
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
              SnackBar(content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('计时完成！')]),
                backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating),
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
    setState(() => _selectedExerciseIndex = getTodayMovements().indexOf(movement));
    if (movement.type == MovementType.duration) {
      final match = RegExp(r'(\d+)秒').firstMatch(weekConfig);
      final seconds = int.tryParse(match?.group(1) ?? '40') ?? 40;
      startTimer(seconds);
    }
    if (movement.type == MovementType.reps) {
      _showRepStartDialog(movement, weekConfig);
    }
  }

  Future<void> _showRepStartDialog(MovementConfig movement, String config) async {
    await GlassDialog.show<void>(
      context: context,
      title: movement.name,
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('目标: $config', style: TextStyle(color: AppTheme.secondaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
        SizedBox(height: 12),
        Text('动作要领: ${movement.description}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        if (movement.commonMistakes.isNotEmpty) ...[
          SizedBox(height: 8),
          Text('注意:', style: TextStyle(color: AppTheme.errorColor, fontSize: 12, fontWeight: FontWeight.w500)),
          ...movement.commonMistakes.map((m) => Padding(padding: const EdgeInsets.only(left: 8, top: 2), child: Text('✗ $m', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)))),
        ],
      ]),
      actions: [GlassDialogAction(label: '了解了', isPrimary: true, onPressed: () => Navigator.pop(context))],
    );
  }

  // ─── 获取今日训练内容 ───────────────────────────────────────────────────────
  List<MovementConfig> getTodayMovements() {
    final planService = context.read<WorkoutPlanService>();
    return planService.getTodayMovements();
  }

  String getTodayWorkoutType() {
    final planService = context.read<WorkoutPlanService>();
    return planService.getTodayType();
  }

  String getSelectedPlanName() {
    final planService = context.read<WorkoutPlanService>();
    return WorkoutPlans.all.firstWhere((p) => p.id == planService.selectedPlanId, orElse: () => WorkoutPlans.planBeginnerFatLoss).name;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final workoutType = getTodayWorkoutType();
    final movements = getTodayMovements();
    final planService = context.watch<WorkoutPlanService>();
    final profile = context.watch<UserProfileService>().profile;
    final week = profile?.currentWeek ?? 1;
    final phaseName = ['适应期', '减脂期', '塑形期', '冲刺期'][(week - 1) ~/ 2 % 4];
    final selectedPlan = WorkoutPlans.all.firstWhere((p) => p.id == planService.selectedPlanId, orElse: () => WorkoutPlans.planBeginnerFatLoss);
    final currentDay = planService.currentDay;

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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('今日训练', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 26), fontWeight: FontWeight.bold)),
                    // 计划切换按钮
                    GestureDetector(
                      onTap: () => _showPlanSelector(context, planService),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [Icon(Icons.swap_horiz, size: 14, color: AppTheme.primaryColor), SizedBox(width: 4), Text(selectedPlan.name, style: TextStyle(color: AppTheme.primaryColor, fontSize: 12))]),
                      ),
                    ),
                  ]),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.scalePadding(context, 16), vertical: 8),
                    decoration: BoxDecoration(
                      color: workoutType == '休息日' ? AppTheme.infoColor.withValues(alpha: 0.2) : AppTheme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(workoutType, style: TextStyle(color: workoutType == '休息日' ? AppTheme.infoColor : AppTheme.primaryColor, fontSize: ResponsiveUtils.scaleFont(context, 14), fontWeight: FontWeight.w500)),
                  ),
                  SizedBox(height: 6),
                  Text('第${currentDay}天 / ${selectedPlan.durationDays}天 · $phaseName', style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 13))),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
                ]),
              ),
            ),
          ),

          // 休息日内容
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
                    final calories = estimateCalories(movement, int.tryParse(weekConfig.split('×').last.replaceAll(RegExp(r'[^\d]'), '')) ?? 40);
                    return Padding(
                      padding: EdgeInsets.only(bottom: ResponsiveUtils.scaleSpacing(context, 12)),
                      child: _ExerciseCard(
                        movement: movement,
                        weekConfig: weekConfig,
                        calories: calories,
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
              delegate: _TimerFloatingHeader(seconds: _timerSeconds, onStop: stopTimer),
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
    final suggestions = [
      '今天好好休息，肌肉在恢复中变强 💪',
      '可以散步15分钟，促进血液循环',
      '做10分钟拉伸，保持身体灵活性',
      '今晚早点睡，保证8小时睡眠 😴',
    ];
    final dayOfWeek = DateTime.now().weekday;
    return GlassCard(
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 24)),
      child: Column(children: [
        Text('😴', style: TextStyle(fontSize: ResponsiveUtils.scaleFont(context, 48))),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
        Text('今日建议：${suggestions[(dayOfWeek - 1) % suggestions.length]}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        SizedBox(height: 8),
        Text('休息日同样重要！良好的恢复让训练效果更好', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
        SizedBox(height: 16),
        Row(children: [
          _RestSuggestionTile(icon: '🚶', text: '散步15分钟'),
          SizedBox(width: 12),
          _RestSuggestionTile(icon: '🧘', text: '拉伸10分钟'),
          SizedBox(width: 12),
          _RestSuggestionTile(icon: '😴', text: '早睡'),
        ]),
      ]),
    );
  }
}

// ─── 计划选择器 ────────────────────────────────────────────────────────────────
Future<void> _showPlanSelector(BuildContext context, WorkoutPlanService planService) async {
  await GlassDialog.show<String?>(
    context: context,
    title: '选择训练计划',
      content: Column(mainAxisSize: MainAxisSize.min, children: WorkoutPlans.all.map((plan) {
        final isSelected = plan.id == planService.selectedPlanId;
        return GestureDetector(
          onTap: () => Navigator.pop(context, plan.id),
          child: Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.transparent),
            ),
            child: Row(children: [
              Icon(Icons.fitness_center, color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(plan.name, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text(plan.description, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ])),
              Text('${plan.durationDays}天', style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
            ]),
          ),
        );
      }).toList()),
      actions: [
        GlassDialogAction(label: '取消', onPressed: () => Navigator.pop(context)),
        GlassDialogAction(label: '确认', isPrimary: true, onPressed: () => Navigator.pop(context, planService.selectedPlanId)),
      ],
    ),
  ).then((planId) {
    if (planId != null && context.mounted) planService.selectPlan(planId);
  });
}

// ─── 休息日建议卡片 ────────────────────────────────────────────────────────────
class _RestSuggestionTile extends StatelessWidget {
  final String icon;
  final String text;
  const _RestSuggestionTile({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: AppTheme.infoColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [Text(icon, style: TextStyle(fontSize: 20)), SizedBox(height: 4), Text(text, style: TextStyle(color: AppTheme.infoColor, fontSize: 11))]),
    ));
  }
}

// ─── 动作卡片 ──────────────────────────────────────────────────────────────────
class _ExerciseCard extends StatelessWidget {
  final MovementConfig movement;
  final String weekConfig;
  final double calories;
  final VoidCallback onTap;
  const _ExerciseCard({required this.movement, required this.weekConfig, required this.calories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(movement.type == MovementType.duration ? Icons.timer : Icons.fitness_center, color: AppTheme.primaryColor, size: 24)),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(movement.name, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            SizedBox(height: 2),
            Text('锻炼: ${movement.targetMuscle}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ])),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppTheme.secondaryColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Text(weekConfig, style: TextStyle(color: AppTheme.secondaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
        SizedBox(height: 10),
        Text('要领: ${movement.description}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        if (movement.commonMistakes.isNotEmpty) ...[
          SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 4, children: movement.commonMistakes.map((m) => Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppTheme.errorColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('✗ $m', style: TextStyle(color: AppTheme.errorColor, fontSize: 10)),
          )).toList()),
        ],
        SizedBox(height: 12),
        GlassButton.custom(
          onTap: onTap,
          width: double.infinity,
          height: ResponsiveUtils.scaleButtonHeight(context, 46),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(movement.type == MovementType.duration ? Icons.timer : Icons.fitness_center, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text(movement.type == MovementType.duration ? '开始计时' : '开始训练', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('≈${calories.toStringAsFixed(0)} kcal', style: TextStyle(color: AppTheme.warningColor, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}

// ─── 计时器浮动头 ─────────────────────────────────────────────────────────────
class _TimerFloatingHeader extends SliverPersistentHeaderDelegate {
  final int seconds;
  final VoidCallback onStop;
  _TimerFloatingHeader({required this.seconds, required this.onStop});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(margin: EdgeInsets.fromLTRB(16, 0, 16, 12), child: GlassCard(
      padding: EdgeInsets.all(16),
      child: Row(children: [
        const Icon(Icons.timer, color: AppTheme.warningColor),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('组间休息', style: TextStyle(color: Colors.white, fontSize: 14)),
          Text('$seconds 秒', style: TextStyle(color: AppTheme.warningColor, fontSize: 24, fontWeight: FontWeight.bold)),
        ])),
        GlassButton.custom(onTap: onStop, height: 48, child: const Text('完成', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
      ]),
    ));
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
