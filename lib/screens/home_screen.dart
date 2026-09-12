/// 首页 - 每日打卡
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:metamorphosis_checkin/services/check_in_service.dart';
import 'package:metamorphosis_checkin/models/custom_task.dart';
import 'package:metamorphosis_checkin/models/daily_check_in.dart';
import 'package:metamorphosis_checkin/utils/constants.dart';
import 'package:metamorphosis_checkin/utils/md3_spring_curve.dart';
import 'package:metamorphosis_checkin/widgets/task_card.dart';
import 'package:metamorphosis_checkin/widgets/progress_ring.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';
import 'package:metamorphosis_checkin/utils/responsive_utils.dart';
import 'package:metamorphosis_checkin/database/app_database.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const _HomeScreenContent();
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

  // 连续打卡 / 最佳记录：由异步查询填充后缓存。
  // 不能在 build() 里直接插值 Future（会渲染成 "Instance of 'Future<int>'"），
  // 也不能在 build() 里发起查询（每次重建都会打两次数据库）。
  int _streak = 0;
  int _bestStreak = 0;

  @override
  void initState() {
    super.initState();
    // 初始值必须是 1.0：ScaleTransition 的 scale 直接取 _checkAnimation.value，
    // 而 Md3SpringCurve.transform(0.0) == 0.0。若保持 AnimationController 默认的
    // 0.0，进度环会被 Transform.scale 缩放到 0 —— 首页刚打开时整块环和中间的
    // 百分比数字都是不可见的，只有触发庆祝动画后才会出现。
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0,
    );
    _checkAnimation = CurvedAnimation(parent: _checkController, curve: const Md3StandardSpring());
    _loadStreaks();
  }

  /// 从数据库刷新连续打卡天数（打卡状态变化后调用）
  Future<void> _loadStreaks() async {
    if (!mounted) return;
    final service = context.read<CheckInService>();
    final results = await Future.wait([
      service.getConsecutiveDays(),
      service.getBestStreak(),
    ]);
    if (!mounted) return;
    setState(() {
      _streak = results[0];
      _bestStreak = results[1];
    });
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
          children: [const Icon(Icons.check_circle, color: Colors.white),
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

  Future<void> _completeAllCheckIn(CheckInService service) async {
    await service.completeAllTasks();
    await _loadStreaks();
    if (!mounted) return;
    setState(() => _showCelebration = true);
    // 必须 from: 0 —— 控制器平时停在 1.0，无参 forward() 在已达上界时是空操作，
    // 会导致第二次及以后的庆祝动画完全不播放。
    _checkController.forward(from: 0);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showCelebration = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final service = context.watch<CheckInService>();
    final today = DateTime.now();
    final dateStr = '${today.year}年${today.month}月${today.day}日';
    // DateTime.weekday: 1=周一 … 7=周日，必须减 1 再索引；
    // 原写法 [today.weekday] 在周日（7）会越界抛 RangeError 导致首页白屏。
    final weekday = ['一', '二', '三', '四', '五', '六', '日'][today.weekday - 1];
    final isAllComplete = service.completionRate >= 100;
    final checkedCount = AppConstants.dailyTasks
        .where((t) => _isTaskChecked(service, t.id))
        .length;

    return Stack(
      // 显式声明撑满。默认的 StackFit.loose 会给非定位子节点下发松约束，
      // 当前只是靠 RenderViewport 自己取 constraints.biggest 才没塌陷，
      // 属于隐式依赖；换成 expand 后语义明确，也不会被后续改动破坏。
      fit: StackFit.expand,
      children: [
        AdaptiveLiquidGlassLayer(
          settings: const LiquidGlassSettings(blur: 0), // 见 app.dart 说明：省掉每张卡一个 BackdropFilter 层
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dateStr, style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 13))),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.scalePadding(context, 10), vertical: 4),
                              decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                              child: Text('周$weekday', style: TextStyle(color: AppTheme.primaryColor, fontSize: ResponsiveUtils.scaleFont(context, 11), fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 6)),
                        Text('今天也要加油哦！💪', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 24), fontWeight: FontWeight.bold)),
                        if (!isAllComplete)
                          Text('坚持就是胜利，你已经很棒了！', style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 13)))
                        else
                          Text('太棒了！今日目标全部达成 🎉', style: TextStyle(color: AppTheme.successColor, fontSize: ResponsiveUtils.scaleFont(context, 13), fontWeight: FontWeight.w600)),
                        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),

                        // ─── 心情选择器 ───
                        _MoodSelector(service: service),
                        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 12)),

                        // ─── 饮水追踪 ───
                        _WaterTracker(service: service),
                        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),

                        // ─── 融合卡片：环形图 + 统计 ───
                        GlassCard(
                          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.scalePadding(context, 20), vertical: ResponsiveUtils.scalePadding(context, 16)),
                          child: Row(
                            children: [
                              ScaleTransition(
                                scale: _checkAnimation,
                                child: ProgressRing(
                                  progress: service.completionRate,
                                  // 环形图尺寸与线宽都是几何尺寸，用 scaleSize
                                  // 等比缩放（不套用 8.0 字号下限）。
                                  size: ResponsiveUtils.scaleSize(context, 88),
                                  strokeWidth: ResponsiveUtils.scaleSize(context, 7),
                                  foregroundColor: isAllComplete ? AppTheme.successColor : AppTheme.primaryColor,
                                  labelText: '${service.completionRate.round()}%',
                                ),
                              ),
                              SizedBox(width: ResponsiveUtils.scaleSpacing(context, 16)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _StatRow(icon: Icons.local_fire_department, iconColor: AppTheme.warningColor, label: '连续打卡', value: '$_streak天', sub: '最佳 $_bestStreak天'),
                                    SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
                                    _StatRow(icon: Icons.check_circle, iconColor: AppTheme.successColor, label: '今日完成', value: '$checkedCount / ${AppConstants.dailyTasks.length}', sub: isAllComplete ? '全部达成 ✅' : '还差 ${AppConstants.dailyTasks.length - checkedCount}项'),
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
                            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('✨ 一键完成今日打卡', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))]),
                          ),
                        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 12)),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── 固定任务列表 ───
              SliverPadding(
                padding: ResponsiveUtils.scaleHorizontalEdgeInsets(context, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = AppConstants.dailyTasks[index];
                      final isChecked = _isTaskChecked(service, task.id);
                      return Padding(
                        padding: EdgeInsets.only(bottom: ResponsiveUtils.scaleSpacing(context, 10)),
                        child: TaskCard(task: task, isChecked: isChecked, onToggle: () async {
                          await service.toggleTask(task.id, !isChecked);
                          await _loadStreaks();
                          if (!mounted) return;
                          if (!isChecked) {
                            _showTaskSuccess(context, task.name);
                            final remaining = AppConstants.dailyTasks.where((t) => !_isTaskChecked(service, t.id)).length;
                            if (remaining == 0) {
                              setState(() => _showCelebration = true);
                              // 必须 from: 0 —— 控制器平时停在 1.0，无参 forward() 在已达上界时是空操作，
    // 会导致第二次及以后的庆祝动画完全不播放。
    _checkController.forward(from: 0);
                              Future.delayed(const Duration(seconds: 2), () {
                                if (mounted) setState(() => _showCelebration = false);
                              });
                            }
                          }
                        }),
                      );
                    },
                    childCount: AppConstants.dailyTasks.length,
                  ),
                ),
              ),

              // ─── 自定义任务列表 ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.scalePadding(context, 16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('我的习惯', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 16), fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => _showAddCustomTaskDialog(context, service),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [Icon(Icons.add, size: 14, color: AppTheme.primaryColor), SizedBox(width: 4), Text('添加', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12))]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: ResponsiveUtils.scaleHorizontalEdgeInsets(context, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final custom = service.customTasks[index];
                      final isChecked = service.todayCheckIn?.customTasks[custom.id] ?? false;
                      return Padding(
                        padding: EdgeInsets.only(bottom: ResponsiveUtils.scaleSpacing(context, 10)),
                        child: _CustomTaskCard(task: custom, isChecked: isChecked, onToggle: () {
                          service.toggleCustomTask(custom.id, !isChecked);
                          if (!isChecked) _showTaskSuccess(context, custom.name);
                        }, onDelete: () => _confirmDeleteCustomTask(context, service, custom)),
                      );
                    },
                    childCount: service.customTasks.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: ResponsiveUtils.bottomSafePadding(context))),
            ],
          ),
        ),

        // 完成庆祝动画
        if (_showCelebration)
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.5), child: Center(
              child: AnimatedBuilder(animation: _checkAnimation, builder: (context, child) {
                return Transform.scale(scale: _checkAnimation.value, child: GlassCard(
                  padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.scalePadding(context, 40), vertical: ResponsiveUtils.scalePadding(context, 32)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('🎉', style: TextStyle(fontSize: ResponsiveUtils.scaleFont(context, 64))),
                    SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
                    Text('今日打卡完成！', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 24), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
                    Text('你太棒了，明天继续！', style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 14)), textAlign: TextAlign.center),
                  ]),
                ));
              }),
            )),
          ),
      ],
    );
  }

  bool _isTaskChecked(CheckInService service, String taskId) {
    final checkIn = service.todayCheckIn;
    if (checkIn == null) return false;
    switch (taskId) {
      case 'face_massage_morning': return checkIn.faceMassageMorning;
      case 'breakfast_healthy': return checkIn.breakfastHealthy;
      case 'lunch_controlled': return checkIn.lunchControlled;
      case 'no_snacks': return checkIn.noSnacks;
      case 'dinner_controlled': return checkIn.dinnerControlled;
      case 'workout_done': return checkIn.workoutDone;
      case 'face_massage_night': return checkIn.faceMassageNight;
      case 'sleep_before_23': return checkIn.sleepBefore23;
      default: return false;
    }
  }
}

// ─── 统计行 ────────────────────────────────────────────────────────────────────
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
    // 关键：Row 中的非 flex 子节点会拿到无界的主轴约束（maxWidth: infinity），
    // 里面的 Text 因此既不换行也不省略，文字一长就直接水平溢出。
    // 用 Expanded 约束列宽，并给每个 Text 加 maxLines + ellipsis 兜底。
    // 尺寸也补上响应式缩放——这里是首页唯一一处原先硬编码字号的组件，
    // 会导致左侧进度环缩小而文字不缩，小屏上比例失调。
    return Row(children: [
      Icon(icon, color: iconColor, size: ResponsiveUtils.scaleIcon(context, 18)),
      SizedBox(width: ResponsiveUtils.scaleSpacing(context, 6)),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 11))),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 14), fontWeight: FontWeight.bold)),
          Text(sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppTheme.textHint, fontSize: ResponsiveUtils.scaleFont(context, 10))),
        ]),
      ),
    ]);
  }
}

// ─── 心情选择器 ────────────────────────────────────────────────────────────────
class _MoodSelector extends StatelessWidget {
  final CheckInService service;
  const _MoodSelector({required this.service});

  @override
  Widget build(BuildContext context) {
    final mood = service.todayCheckIn?.mood ?? Mood.neutral;
    return GlassCard(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.scalePadding(context, 16), vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('今日心情', style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 12))),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _MoodChip(mood: Mood.happy, emoji: '😊', label: '开心', service: service, selected: mood == Mood.happy),
            _MoodChip(mood: Mood.neutral, emoji: '😐', label: '一般', service: service, selected: mood == Mood.neutral),
            _MoodChip(mood: Mood.sad, emoji: '😔', label: '低落', service: service, selected: mood == Mood.sad),
          ],
        ),
      ]),
    );
  }
}

class _MoodChip extends StatelessWidget {
  final Mood mood;
  final String emoji;
  final String label;
  final CheckInService service;
  final bool selected;
  const _MoodChip({required this.mood, required this.emoji, required this.label, required this.service, required this.selected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => service.setMood(mood),
      child: Column(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppTheme.primaryColor : Colors.transparent, width: 2),
          ),
          child: Center(child: Text(emoji, style: TextStyle(fontSize: 24))),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: selected ? AppTheme.primaryColor : AppTheme.textSecondary, fontSize: 11)),
      ]),
    );
  }
}

// ─── 饮水追踪 ──────────────────────────────────────────────────────────────────
class _WaterTracker extends StatelessWidget {
  final CheckInService service;
  const _WaterTracker({required this.service});

  static const int goalMl = 1500;
  static const int cupMl = 250;

  @override
  Widget build(BuildContext context) {
    final waterMl = service.todayCheckIn?.waterMl ?? 0;
    // LinearProgressIndicator 要的是 0.0~1.0 的比例；
    // 原写法先 ×100 再按 0~1 clamp，导致喝一杯就满格。
    final progress = (waterMl / goalMl).clamp(0.0, 1.0);
    return GlassCard(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.scalePadding(context, 16), vertical: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('饮水记录', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            Text('$waterMl / $goalMl ml', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(value: progress, minHeight: 6, borderRadius: BorderRadius.circular(3),
          color: progress >= 1.0 ? AppTheme.successColor : AppTheme.primaryColor,
          backgroundColor: Colors.white.withValues(alpha: 0.1)),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (i) {
            final ml = (i + 1) * cupMl;
            final filled = waterMl >= ml;
            return GestureDetector(
              onTap: () => service.addWater(cupMl),
              child: Container(
                width: 44, height: 52,
                decoration: BoxDecoration(
                  color: filled ? AppTheme.primaryColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(6)),
                  border: filled ? Border.all(color: AppTheme.primaryColor, width: 2) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text(filled ? '✓' : '💧', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 2), Text('${ml ~/ 100}00', style: TextStyle(color: filled ? AppTheme.successColor : AppTheme.textHint, fontSize: 9))],
                ),
              ),
            );
          }),
        ),
      ]),
    );
  }
}

// ─── 自定义习惯卡片 ────────────────────────────────────────────────────────────
class _CustomTaskCard extends StatelessWidget {
  final CustomTask task;
  final bool isChecked;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  const _CustomTaskCard({required this.task, required this.isChecked, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      // 不再写死 height: 64。IconButton 的最小可点区域是 48dp，
      // 加上上下 padding 至少需要 72dp，固定 64 会把删除图标挤到卡片外。
      // 交给内容自适应高度，小屏或系统大字体下都不会裁切。
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.scalePadding(context, 16),
        vertical: ResponsiveUtils.scalePadding(context, 12),
      ),
      child: Row(
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: isChecked ? AppTheme.checkedColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(task.icon, style: const TextStyle(fontSize: 18)))),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(task.name, style: TextStyle(color: isChecked ? AppTheme.checkedColor : AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          ])),
          Transform.scale(scale: 1.1, child: Checkbox(value: isChecked, onChanged: (_) => onToggle(), activeColor: AppTheme.checkedColor, checkColor: Colors.white, side: const BorderSide(color: AppTheme.textHint))),
          IconButton(icon: Icon(Icons.delete_outline, color: AppTheme.errorColor.withValues(alpha: 0.7), size: 20), onPressed: onDelete),
        ],
      ),
    );
  }
}

// ─── 添加/删除自定义任务 ───────────────────────────────────────────────────────
Future<void> _showAddCustomTaskDialog(BuildContext context, CheckInService service) async {
  final nameCtrl = TextEditingController();
  final icons = ['⭐', '🌟', '💪', '📚', '🏃', '🧘', '🎯', '💤', '🥗', '💊', '✍️', '🎵'];
  String selectedIcon = '⭐';

  await GlassDialog.show<String?>(
    context: context,
    title: '添加新习惯',
    content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: '习惯名称', labelStyle: TextStyle(color: AppTheme.textSecondary), prefixIcon: Icon(Icons.edit, color: AppTheme.primaryColor), filled: true, fillColor: Colors.white.withValues(alpha: 0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
      SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: icons.map((e) => GestureDetector(onTap: () => Navigator.of(context).pop(e), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: selectedIcon == e ? AppTheme.primaryColor.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(e, style: const TextStyle(fontSize: 20)))))).toList()),
    ]),
    actions: [
      GlassDialogAction(label: '取消', onPressed: () => Navigator.of(context).pop()),
      GlassDialogAction(label: '保存', isPrimary: true, onPressed: () async {
        final name = nameCtrl.text.trim();
        if (name.isEmpty) return;
        final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
        await DatabaseManager.customTaskRepository.insert(CustomTask(id: id, name: name, icon: selectedIcon));
        service.refresh();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('「$name」已添加'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
      }),
    ],
  );
}

Future<void> _confirmDeleteCustomTask(BuildContext context, CheckInService service, CustomTask task) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppTheme.backgroundColor,
      title: Text('删除习惯', style: TextStyle(color: Colors.white)),
      content: Text('确定要删除「${task.name}」吗？', style: TextStyle(color: AppTheme.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('取消', style: TextStyle(color: AppTheme.primaryColor))),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('删除', style: TextStyle(color: AppTheme.errorColor))),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await DatabaseManager.customTaskRepository.delete(task.id);
    service.refresh();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已删除「${task.name}」'), backgroundColor: AppTheme.infoColor, behavior: SnackBarBehavior.floating));
  }
}
