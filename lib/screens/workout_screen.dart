/// 训练页
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:metamorphosis_checkin/services/user_profile_service.dart';
import 'package:metamorphosis_checkin/services/workout_plan_service.dart';
import 'package:metamorphosis_checkin/services/workout_service.dart';
import 'package:metamorphosis_checkin/utils/constants.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';
import 'package:metamorphosis_checkin/utils/responsive_utils.dart';
import 'package:metamorphosis_checkin/utils/workout_target.dart';
import 'package:metamorphosis_checkin/screens/live_workout_screen.dart';

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
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  // ─── 说明 ──────────────────────────────────────────────────────────────────
  // 本页只负责「展示今日动作 + 进入训练」。
  // 打卡全部走实时监督训练页（LiveWorkoutScreen）：计时跑完才会写入
  // workout_logs，因此这里**没有**任何"点一下就打卡"的入口。
  // 已完成组数也由今日日志派生（WorkoutService.completedSetsFor），
  // 所以切 Tab（页面会被销毁重建）甚至重启 App，进度都不会丢。

  @override
  void initState() {
    super.initState();
    // 重新拉一次日志，从数据库恢复今日训练进度
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WorkoutService>().init();
    });
  }

  // ─── 卡路里估算（kcal）─────────────────────────────────────────────────────
  /// 原实现把 weekConfig 里的数字（例如「3组×15个」的 15）当作**分钟数**传入，
  /// 于是 15 个俯卧撑被折算成 15 分钟的运动量，数值严重虚高。
  /// 现在按「组数 × 每组时长」计算：计时型取目标秒数，次数型按每次约 3 秒估算。
  double _estimateCalories(MovementConfig movement, SetTarget target) {
    // MET 值参考（每小时 kcal/kg）
    const metValues = {
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
    final weight = context.read<UserProfileService>().profile?.weightKg ?? 65;
    final perSetSeconds = target.seconds > 0 ? target.seconds : target.reps * 3;
    final totalHours = (perSetSeconds * target.sets) / 3600.0;
    return met * weight * totalHours;
  }

  /// 打开实时监督训练。
  /// [startAt] 指定从第几个动作开始（点某张卡片进来时传它）；
  /// 为 null 时从第一个还没做满的动作继续。
  void _openLiveWorkout(List<MovementConfig> movements, {int? startAt}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LiveWorkoutScreen(movements: movements, initialIndex: startAt),
    ));
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final workoutType = getTodayWorkoutType();
    final movements = getTodayMovements();
    final planService = context.watch<WorkoutPlanService>();
    final profile = context.watch<UserProfileService>().profile;
    final week = profile?.currentWeek ?? 1;
    final phaseName = ['适应期', '减脂期', '塑形期', '冲刺期'][(week - 1) ~/ 2 % 4];
    final selectedPlan = planService.selectedPlan;
    final currentDay = planService.currentDay;

    return AdaptiveLiquidGlassLayer(
      settings: const LiquidGlassSettings(blur: 0), // 无用的逐卡模糊，去掉可大幅降 GPU 负载
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
                  if (movements.isNotEmpty) ...[
                    SizedBox(height: ResponsiveUtils.scaleSpacing(context, 12)),
                    _TrainingProgressBar(movements: movements, week: week),
                    SizedBox(height: ResponsiveUtils.scaleSpacing(context, 10)),
                    GlassButton.custom(
                      onTap: () => _openLiveWorkout(movements),
                      width: double.infinity,
                      height: ResponsiveUtils.scaleButtonHeight(context, 52),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.play_circle_fill, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text('开始实时训练', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ],
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
                    final target = parseSetTarget(movement, weekConfig);
                    final doneSets = context.watch<WorkoutService>().completedSetsFor(movement.name);
                    return Padding(
                      padding: EdgeInsets.only(bottom: ResponsiveUtils.scaleSpacing(context, 12)),
                      child: _ExerciseCard(
                        movement: movement,
                        weekConfig: weekConfig,
                        calories: _estimateCalories(movement, target),
                        completedSets: doneSets,
                        targetSets: target.sets,
                        onOpen: () => _openLiveWorkout(movements, startAt: index),
                      ),
                    );
                  },
                  childCount: movements.length,
                ),
              ),
            ),

          // 倒计时与组间休息都在实时训练页里，这里不再需要浮动计时条
          SliverToBoxAdapter(child: SizedBox(height: ResponsiveUtils.bottomSafePadding(context))),
        ],
      ),
    );
  }

  String _getWeekConfig(MovementConfig movement, int week) =>
      weekConfigFor(movement, week);

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
  final planId = await GlassDialog.show<String?>(
    context: context,
    title: '选择训练计划',
      content: Column(mainAxisSize: MainAxisSize.min, children: planService.availablePlans.map((plan) {
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
    );
  if (planId != null && context.mounted) planService.selectPlan(planId);
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
  final int completedSets;
  final int targetSets;
  final VoidCallback onOpen;
  const _ExerciseCard({
    required this.movement,
    required this.weekConfig,
    required this.calories,
    required this.completedSets,
    required this.targetSets,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFinished = targetSets > 0 && completedSets >= targetSets;
    // 整张卡片可点击 → 进入实时监督训练（会自动从没做完的那一组继续）。
    // 卡片内的「完成这一组」按钮自带点击处理，不会误触发这里。
    return GestureDetector(
      onTap: onOpen,
      child: GlassCard(
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
        SizedBox(height: 10),
        // 组进度：每完成一组点亮一个点。已完成组数来自今日 workout_logs，
        // 所以切 Tab / 重启后依然是准的。
        Row(children: [
          ...List.generate(targetSets, (i) {
            final bool filled = i < completedSets;
            return Container(
              margin: EdgeInsets.only(right: ResponsiveUtils.scaleSpacing(context, 6)),
              width: ResponsiveUtils.scaleSize(context, 22),
              height: ResponsiveUtils.scaleSize(context, 6),
              decoration: BoxDecoration(
                color: filled ? AppTheme.successColor : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
          const SizedBox(width: 4),
          Text('$completedSets / $targetSets 组',
              style: TextStyle(
                color: isFinished ? AppTheme.successColor : AppTheme.textSecondary,
                fontSize: ResponsiveUtils.scaleFont(context, 11),
                fontWeight: FontWeight.w600,
              )),
        ]),
        SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.touch_app, color: AppTheme.textHint, size: 12),
          SizedBox(width: ResponsiveUtils.scaleSpacing(context, 4)),
          Text('点击卡片进入实时训练',
              style: TextStyle(color: AppTheme.textHint, fontSize: ResponsiveUtils.scaleFont(context, 10))),
        ]),
        SizedBox(height: 12),
        GlassButton.custom(
          onTap: onOpen,
          width: double.infinity,
          height: ResponsiveUtils.scaleButtonHeight(context, 46),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(
              isFinished ? Icons.check_circle : Icons.play_circle_fill,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              isFinished ? '已完成（可重练）' : '开始本组训练',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text('≈${calories.toStringAsFixed(1)} kcal', style: TextStyle(color: AppTheme.warningColor, fontSize: 12)),
          ]),
        ),
      ]),
      ),
    );
  }
}

// ─── 今日训练进度 ─────────────────────────────────────────────────────────────
class _TrainingProgressBar extends StatelessWidget {
  final List<MovementConfig> movements;
  final int week;
  const _TrainingProgressBar({required this.movements, required this.week});

  @override
  Widget build(BuildContext context) {
    final workoutService = context.watch<WorkoutService>();

    int doneSets = 0;
    int totalSets = 0;
    for (final m in movements) {
      final target = parseSetTarget(m, weekConfigFor(m, week));
      totalSets += target.sets;
      final done = workoutService.completedSetsFor(m.name);
      doneSets += done > target.sets ? target.sets : done;
    }
    final bool finished = totalSets > 0 && doneSets >= totalSets;
    final double ratio = totalSets == 0 ? 0.0 : doneSets / totalSets;

    return GlassCard(
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(
              finished ? Icons.emoji_events : Icons.fitness_center,
              size: ResponsiveUtils.scaleIcon(context, 16),
              color: finished ? AppTheme.successColor : AppTheme.primaryColor,
            ),
            SizedBox(width: ResponsiveUtils.scaleSpacing(context, 6)),
            Text('今日训练进度',
                style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 13), fontWeight: FontWeight.w600)),
          ]),
          Text('$doneSets / $totalSets 组',
              style: TextStyle(
                color: finished ? AppTheme.successColor : AppTheme.textSecondary,
                fontSize: ResponsiveUtils.scaleFont(context, 12),
                fontWeight: FontWeight.w600,
              )),
        ]),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
        LinearProgressIndicator(
          value: ratio.clamp(0.0, 1.0),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
          color: finished ? AppTheme.successColor : AppTheme.primaryColor,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
        ),
        if (finished) ...[
          SizedBox(height: ResponsiveUtils.scaleSpacing(context, 6)),
          Text('全部完成，已自动同步到首页「运动完成」打卡 ✅',
              style: TextStyle(color: AppTheme.successColor, fontSize: ResponsiveUtils.scaleFont(context, 11))),
        ],
      ]),
    );
  }
}
