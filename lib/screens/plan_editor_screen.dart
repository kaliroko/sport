/// 训练计划管理页：新建 / 编辑 / 删除自定义训练计划
///
/// 数据落在早已建好却一直闲置的 `workout_plans` 表里，
/// 日程表只存动作名，动作定义从 WorkoutPlans.allMovements 还原。
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:metamorphosis_checkin/models/workout_plan.dart';
import 'package:metamorphosis_checkin/services/workout_plan_service.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';
import 'package:metamorphosis_checkin/utils/constants.dart';
import 'package:metamorphosis_checkin/utils/responsive_utils.dart';
import 'package:metamorphosis_checkin/widgets/app_background.dart';
import 'package:provider/provider.dart';

class PlanEditorScreen extends StatelessWidget {
  const PlanEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<WorkoutPlanService>();
    final customPlans = service.customPlans;

    return Stack(
      fit: StackFit.expand,
      children: [
        const AppBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('训练计划', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 18), fontWeight: FontWeight.bold)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.scalePadding(context, 16),
              0,
              ResponsiveUtils.scalePadding(context, 16),
              ResponsiveUtils.bottomSafePadding(context),
            ),
            children: [
              // 当前计划 + 进度
              GlassCard(
                padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('当前计划', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 16), fontWeight: FontWeight.bold)),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
                  Text(service.selectedPlan.name, style: TextStyle(color: AppTheme.primaryColor, fontSize: ResponsiveUtils.scaleFont(context, 15), fontWeight: FontWeight.w600)),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 4)),
                  Text(
                    '进行到第 ${service.currentDay} / ${service.selectedPlan.durationDays} 天',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 12)),
                  ),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 12)),
                  Row(children: [
                    Expanded(child: GlassButton.custom(
                      onTap: () => _showJumpDialog(context, service),
                      height: ResponsiveUtils.scaleButtonHeight(context, 42),
                      child: const Text('跳到某一天', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    )),
                    SizedBox(width: ResponsiveUtils.scaleSpacing(context, 10)),
                    Expanded(child: GlassButton.custom(
                      onTap: () => service.restartPlan(),
                      height: ResponsiveUtils.scaleButtonHeight(context, 42),
                      child: const Text('重新开始', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    )),
                  ]),
                ]),
              ),
              SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),

              // 新建
              GlassCard(
                padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('我的自定义计划', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 16), fontWeight: FontWeight.bold)),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 6)),
                  Text(
                    '内置计划之外，可以按自己的器械条件和时间安排组合动作。',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 12)),
                  ),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 12)),
                  GlassButton.custom(
                    onTap: () => _openEditor(context, service, null),
                    width: double.infinity,
                    height: ResponsiveUtils.scaleButtonHeight(context, 46),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('新建自定义计划', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
              ),

              if (customPlans.isNotEmpty) ...[
                SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
                ...customPlans.map((plan) => Padding(
                  padding: EdgeInsets.only(bottom: ResponsiveUtils.scaleSpacing(context, 10)),
                  child: _CustomPlanCard(
                    plan: plan,
                    isSelected: plan.id == service.selectedPlanId,
                    onSelect: () => service.selectPlan(plan.id),
                    onEdit: () => _openEditor(context, service, plan),
                    onDelete: () => _confirmDelete(context, service, plan),
                  ),
                )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _openEditor(BuildContext context, WorkoutPlanService service, WorkoutPlan? plan) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PlanEditScreen(existing: plan),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, WorkoutPlanService service, WorkoutPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text('删除计划', style: TextStyle(color: Colors.white)),
        content: Text('确定要删除「${plan.name}」吗？', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('取消', style: TextStyle(color: AppTheme.primaryColor))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('删除', style: TextStyle(color: AppTheme.errorColor))),
        ],
      ),
    );
    if (confirmed == true) {
      await service.deleteCustomPlan(plan.id);
    }
  }

  Future<void> _showJumpDialog(BuildContext context, WorkoutPlanService service) async {
    final total = service.selectedPlan.durationDays;
    final controller = TextEditingController(text: '${service.currentDay}');
    final day = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text('跳到第几天', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '1 - $total',
            hintStyle: const TextStyle(color: AppTheme.textHint),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('取消', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text.trim())),
            child: Text('确定', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
    if (day != null) await service.jumpToDay(day);
  }
}

// ─── 自定义计划卡片 ───────────────────────────────────────────────────────────
class _CustomPlanCard extends StatelessWidget {
  final WorkoutPlan plan;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomPlanCard({
    required this.plan,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isSelected ? Icons.check_circle : Icons.fitness_center,
              color: isSelected ? AppTheme.successColor : AppTheme.textSecondary,
              size: ResponsiveUtils.scaleIcon(context, 18)),
          SizedBox(width: ResponsiveUtils.scaleSpacing(context, 8)),
          Expanded(child: Text(plan.name,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 15), fontWeight: FontWeight.w600))),
          Text('${plan.durationDays}天', style: TextStyle(color: AppTheme.textHint, fontSize: ResponsiveUtils.scaleFont(context, 11))),
        ]),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 6)),
        Text('${plan.dailySchedule.length} 个训练日 · 共 ${plan.dailySchedule.values.expand((e) => e).length} 个动作',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 11))),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 10)),
        Row(children: [
          if (!isSelected) Expanded(child: GlassButton.custom(
            onTap: onSelect,
            height: ResponsiveUtils.scaleButtonHeight(context, 38),
            child: const Text('使用', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          )),
          if (!isSelected) SizedBox(width: ResponsiveUtils.scaleSpacing(context, 8)),
          Expanded(child: GlassButton.custom(
            onTap: onEdit,
            height: ResponsiveUtils.scaleButtonHeight(context, 38),
            child: const Text('编辑', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          )),
          SizedBox(width: ResponsiveUtils.scaleSpacing(context, 8)),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, color: AppTheme.errorColor.withValues(alpha: 0.8), size: 20),
          ),
        ]),
      ]),
    );
  }
}

// ─── 计划编辑页 ───────────────────────────────────────────────────────────────
class _PlanEditScreen extends StatefulWidget {
  final WorkoutPlan? existing;
  const _PlanEditScreen({this.existing});

  @override
  State<_PlanEditScreen> createState() => _PlanEditScreenState();
}

class _PlanEditScreenState extends State<_PlanEditScreen> {
  late TextEditingController _nameCtrl;
  late int _durationDays;
  /// dayIndex(0 基) → 动作名列表
  late Map<int, List<String>> _schedule;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _durationDays = existing?.durationDays ?? 7;
    _schedule = existing == null
        ? {}
        : {
            for (final entry in existing.dailySchedule.entries)
              entry.key: entry.value.map((m) => m.name).toList(),
          };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const AppBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(widget.existing == null ? '新建计划' : '编辑计划',
                style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 18), fontWeight: FontWeight.bold)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.scalePadding(context, 16),
              0,
              ResponsiveUtils.scalePadding(context, 16),
              ResponsiveUtils.bottomSafePadding(context),
            ),
            children: [
              GlassCard(
                padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('计划名称', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '例如：宿舍无器械版',
                      hintStyle: const TextStyle(color: AppTheme.textHint),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 14)),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('周期天数', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    Text('$_durationDays 天', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                  Slider(
                    value: _durationDays.toDouble(),
                    min: 3,
                    max: 30,
                    divisions: 27,
                    activeColor: AppTheme.primaryColor,
                    inactiveColor: Colors.white24,
                    label: '$_durationDays 天',
                    onChanged: (v) => setState(() => _durationDays = v.round()),
                  ),
                  Text('提示：日程按天数循环，例如 7 天日程用在 30 天计划里会自动重复 4 轮。',
                      style: TextStyle(color: AppTheme.textHint, fontSize: ResponsiveUtils.scaleFont(context, 11))),
                ]),
              ),
              SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),

              Text('每日安排', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 16), fontWeight: FontWeight.bold)),
              SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
              ...List.generate(_durationDays, (i) => _buildDayRow(context, i)),

              SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
              GlassButton.custom(
                onTap: _save,
                width: double.infinity,
                height: ResponsiveUtils.scaleButtonHeight(context, 48),
                child: const Text('保存计划', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayRow(BuildContext context, int dayIndex) {
    final movements = _schedule[dayIndex] ?? const <String>[];
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.scaleSpacing(context, 8)),
      child: GlassCard(
        padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 12)),
        child: InkWell(
          onTap: () => _pickMovements(context, dayIndex),
          child: Row(children: [
            Container(
              width: ResponsiveUtils.scaleSize(context, 34),
              height: ResponsiveUtils.scaleSize(context, 34),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text('${dayIndex + 1}',
                  style: TextStyle(color: AppTheme.primaryColor, fontSize: ResponsiveUtils.scaleFont(context, 13), fontWeight: FontWeight.bold))),
            ),
            SizedBox(width: ResponsiveUtils.scaleSpacing(context, 10)),
            Expanded(child: Text(
              movements.isEmpty ? '未安排（休息日）' : movements.join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: movements.isEmpty ? AppTheme.textHint : AppTheme.textSecondary,
                fontSize: ResponsiveUtils.scaleFont(context, 12),
              ),
            )),
            const Icon(Icons.edit, color: AppTheme.textHint, size: 16),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickMovements(BuildContext context, int dayIndex) async {
    final library = WorkoutPlans.allMovements;
    final selected = <String>{...?_schedule[dayIndex]};

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.backgroundColor,
          title: Text('第 ${dayIndex + 1} 天', style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('点击选择动作（可不选 = 休息日）', style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: library.map((m) {
                  final on = selected.contains(m.name);
                  return GestureDetector(
                    onTap: () => setDlgState(() {
                      if (on) {
                        selected.remove(m.name);
                      } else {
                        selected.add(m.name);
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: on ? AppTheme.primaryColor.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: on ? AppTheme.primaryColor : Colors.transparent),
                      ),
                      child: Text(m.name, style: TextStyle(color: on ? Colors.white : AppTheme.textSecondary, fontSize: 12)),
                    ),
                  );
                }).toList()),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: AppTheme.textSecondary))),
            TextButton(onPressed: () => Navigator.pop(ctx, selected), child: const Text('确定', style: TextStyle(color: AppTheme.primaryColor))),
          ],
        ),
      ),
    );

    if (result == null) return;
    setState(() {
      if (result.isEmpty) {
        _schedule.remove(dayIndex);
      } else {
        _schedule[dayIndex] = result.toList();
      }
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('请先填写计划名称'),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_schedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('至少要为一天安排动作'),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // 只保留有动作的天，并重新压紧成连续下标 ——
    // movementsForDay 是按 map.length 取模的，下标必須从 0 连续排列。
    final library = WorkoutPlans.movementByName;
    final compact = <int, List<MovementConfig>>{};
    final sortedDays = _schedule.keys.toList()..sort();
    var nextIndex = 0;
    for (final day in sortedDays) {
      final names = _schedule[day] ?? const <String>[];
      final movements = <MovementConfig>[];
      for (final n in names) {
        final m = library[n];
        if (m != null) movements.add(m);
      }
      if (movements.isNotEmpty) {
        compact[nextIndex++] = movements;
      }
    }

    final existing = widget.existing;
    final plan = WorkoutPlan(
      id: existing?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: '自定义计划 · ${compact.length} 个训练日',
      durationDays: _durationDays,
      difficulty: PlanDifficulty.intermediate,
      dailySchedule: compact,
    );

    await context.read<WorkoutPlanService>().saveCustomPlan(plan);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('「$name」已保存'),
      backgroundColor: AppTheme.successColor,
      behavior: SnackBarBehavior.floating,
    ));
  }
}
