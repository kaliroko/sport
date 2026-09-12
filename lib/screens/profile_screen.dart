/// 个人资料页
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:metamorphosis_checkin/services/user_profile_service.dart';
import 'package:metamorphosis_checkin/services/debug_upload_service.dart';
import 'package:metamorphosis_checkin/services/notification_service.dart';
import 'package:metamorphosis_checkin/models/user_profile.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';
import 'package:metamorphosis_checkin/utils/responsive_utils.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfileScreenContent();
  }
}

class _ProfileScreenContent extends StatefulWidget {
  const _ProfileScreenContent();

  @override
  State<_ProfileScreenContent> createState() => _ProfileScreenContentState();
}

class _ProfileScreenContentState extends State<_ProfileScreenContent> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AdaptiveLiquidGlassLayer(
      settings: const LiquidGlassSettings(),
      quality: GlassQuality.standard,
      blendAmount: 10.0,
      child: CustomScrollView(
        slivers: [
          // 顶部用户信息
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 20)),
                child: Column(
                  children: [
                    Consumer<UserProfileService>(
                      builder: (context, service, _) {
                        final hasProfile = service.profile != null;
                        return GestureDetector(
                          onTap: hasProfile ? () => _showEditProfileDialog(context) : null,
                          child: Column(
                            children: [
                              Container(
                                width: ResponsiveUtils.scaleFont(context, 80),
                                height: ResponsiveUtils.scaleFont(context, 80),
                                decoration: BoxDecoration(
                                  color: hasProfile
                                      ? AppTheme.primaryColor.withValues(alpha: 0.3)
                                      : AppTheme.textHint.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: hasProfile ? AppTheme.primaryColor : AppTheme.textHint,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  hasProfile ? Icons.person : Icons.add,
                                  size: ResponsiveUtils.scaleIcon(context, 40),
                                  color: hasProfile ? Colors.white : AppTheme.textHint,
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.scaleSpacing(context, 12)),
                              Text(
                                service.profile?.name ?? '点击设置昵称',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: ResponsiveUtils.scaleFont(context, 24),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                hasProfile ? '第${service.profile!.currentWeek}周 · ${service.profile!.bmiCategory}' : '还未设置个人资料',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: ResponsiveUtils.scaleFont(context, 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: ResponsiveUtils.scaleSpacing(context, 24)),
                  ],
                ),
              ),
            ),
          ),

          // 个人数据卡片
          SliverPadding(
            padding: ResponsiveUtils.scaleHorizontalEdgeInsets(context, 20),
            sliver: SliverToBoxAdapter(child: const _ProfileDataCard()),
          ),
          SliverToBoxAdapter(child: SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16))),

          // 每日激励金句
          SliverPadding(
            padding: ResponsiveUtils.scaleHorizontalEdgeInsets(context, 20),
            sliver: SliverToBoxAdapter(child: const _DailyQuoteCard()),
          ),
          SliverToBoxAdapter(child: SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16))),

          // 本周训练进度
          SliverPadding(
            padding: ResponsiveUtils.scaleHorizontalEdgeInsets(context, 20),
            sliver: SliverToBoxAdapter(child: const _WeeklyProgressCard()),
          ),
          SliverToBoxAdapter(child: SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16))),

          // 设置选项
          SliverPadding(
            padding: ResponsiveUtils.scaleHorizontalEdgeInsets(context, 20),
            sliver: SliverToBoxAdapter(child: _SettingsSection(state: this)),
          ),
          SliverToBoxAdapter(child: SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16))),

          // 调试选项
          SliverPadding(
            padding: ResponsiveUtils.scaleHorizontalEdgeInsets(context, 20),
            sliver: SliverToBoxAdapter(child: const _DebugSection()),
          ),
          SliverToBoxAdapter(child: SizedBox(height: ResponsiveUtils.bottomSafePadding(context))),
        ],
      ),
    );
  }

  // ─── 编辑资料弹窗 ───────────────────────────────────────────────────────────
  Future<void> _showEditProfileDialog(BuildContext context) async {
    final profile = context.read<UserProfileService>().profile!;
    final nameCtrl = TextEditingController(text: profile.name);
    final ageCtrl = TextEditingController(text: profile.age.toString());
    final heightCtrl = TextEditingController(text: profile.heightCm.toStringAsFixed(0));
    final weightCtrl = TextEditingController(text: profile.weightKg.toStringAsFixed(1));

    await GlassDialog.show<String?>(
      context: context,
      title: '编辑资料',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EditField(controller: nameCtrl, label: '昵称', icon: Icons.badge),
          SizedBox(height: 12),
          _EditField(controller: ageCtrl, label: '年龄', icon: Icons.cake),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _EditField(controller: heightCtrl, label: '身高(cm)', icon: Icons.height),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _EditField(controller: weightCtrl, label: '体重(kg)', icon: Icons.monitor_weight),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ChipSelector<String>(
                  label: '状态',
                  selected: profile.schoolType == SchoolType.boarder ? '住校' : '走读',
                  options: const ['走读', '住校'],
                  onSelected: (v) {},
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
          GlassDialogAction(
            label: '取消',
            onPressed: () => Navigator.pop(context),
          ),
          GlassDialogAction(
            label: '保存',
            isPrimary: true,
            onPressed: () async {
          bool anyConfirmed = false;
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('昵称不能为空'), backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating),
                  );
                }
                return;
              }
              final age = int.tryParse(ageCtrl.text) ?? profile.age;
              final height = double.tryParse(heightCtrl.text) ?? profile.heightCm;
              final weight = double.tryParse(weightCtrl.text) ?? profile.weightKg;
              await context.read<UserProfileService>().saveProfile(profile.copyWith(
                name: name,
                age: age,
                heightCm: height,
                weightKg: weight,
              ));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('资料已更新'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating),
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
    );
  }

  // ─── 阶段选择 ──────────────────────────────────────────────────────────────
  Future<void> _showPhaseSelector(BuildContext context) async {
    final profile = context.read<UserProfileService>().profile;
    final currentWeek = profile?.currentWeek ?? 1;
    final week = await GlassDialog.show<int?>(
      context: context,
      title: '选择训练阶段',
        message: '选择你当前所在阶段，系统将调整训练计划难度',
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(8, (i) {
            final week = i + 1;
            final phase = ['适应期', '减脂期', '塑形期', '冲刺期', '适应期', '减脂期', '塑形期', '冲刺期'][i];
            final isSelected = week == currentWeek;
            return GlassButton.custom(
              onTap: () => Navigator.pop(context, week),
              width: 80,
              height: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$week周', style: TextStyle(color: isSelected ? AppTheme.primaryColor : Colors.white, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  Text(phase, style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                ],
              ),
            );
          }),
        ),
        actions: [
          GlassDialogAction(label: '取消', onPressed: () => Navigator.pop(context)),
          GlassDialogAction(label: '确认', isPrimary: true, onPressed: () => Navigator.pop(context, currentWeek)),
        ],
    );
    if (week != null && context.mounted) {
      await context.read<UserProfileService>().updateWeek(week);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已切换到第 $week 周'), backgroundColor: AppTheme.primaryColor, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  // ─── 提醒设置 ──────────────────────────────────────────────────────────────
  Future<void> _showReminderDialog(BuildContext context) async {
    final notificationService = NotificationService();
    final waterCtrl = TextEditingController(text: '09:00');
    final sleepCtrl = TextEditingController(text: '22:00');
    bool waterEnabled = false;
    bool sleepEnabled = false;

    await GlassDialog.show<void>(
      context: context,
      title: '提醒设置',
      content: StatefulBuilder(
        builder: (ctx, setDlgState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(Icons.water_drop, color: AppTheme.primaryColor),
                title: Text('喝水提醒', style: TextStyle(color: Colors.white)),
                subtitle: Text('每天 09:00 / 11:00 / 14:00 / 16:00 / 19:00', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                trailing: Switch(value: waterEnabled, onChanged: (v) => setDlgState(() => waterEnabled = v)),
              ),
              Divider(color: AppTheme.textHint),
              ListTile(
                leading: Icon(Icons.bedtime, color: AppTheme.infoColor),
                title: Text('早睡提醒', style: TextStyle(color: Colors.white)),
                subtitle: Text('每天 22:00 提醒', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                trailing: Switch(value: sleepEnabled, onChanged: (v) => setDlgState(() => sleepEnabled = v)),
              ),
              SizedBox(height: 12),
              if (waterEnabled)
                TextField(controller: waterCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: '早起提醒时间', labelStyle: TextStyle(color: AppTheme.textSecondary), prefixIcon: Icon(Icons.water_drop, color: AppTheme.primaryColor), filled: true, fillColor: Colors.white.withValues(alpha: 0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
              if (sleepEnabled) ...[
                SizedBox(height: 8),
                TextField(controller: sleepCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: '早睡提醒时间', labelStyle: TextStyle(color: AppTheme.textSecondary), prefixIcon: Icon(Icons.bedtime, color: AppTheme.infoColor), filled: true, fillColor: Colors.white.withValues(alpha: 0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
              ],
            ],
          ),
      ),
      actions: [
          GlassDialogAction(label: '取消', onPressed: () => Navigator.pop(context)),
          GlassDialogAction(
            label: '保存',
            isPrimary: true,
            onPressed: () async {
          bool anyConfirmed = false;
              if (waterEnabled) {
                await notificationService.scheduleWaterReminder(9, 0);
                anyConfirmed = true;
              }
              if (sleepEnabled) {
                await notificationService.scheduleDailyReminder(id: 999, title: '早点休息', body: '今晚争取23点前入睡！', time: DateTime.now().add(const Duration(days: 1)).copyWith(hour: 22, minute: 0));
                anyConfirmed = true;
              }
              if (anyConfirmed) {
                Navigator.pop(context);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提醒已设置 ✓'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating));
              }
            },
          ),
        ],
      ),
  }

  // ─── 导出数据 ──────────────────────────────────────────────────────────────
  Future<void> _showExportDialog(BuildContext context) async {
    await GlassDialog.show<void>(
      context: context,
      title: '导出数据',
      content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('选择导出格式', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            SizedBox(height: 12),
            _ExportOption(icon: Icons.description, title: '导出为 CSV', desc: '表格格式，可用 Excel 打开'),
            _ExportOption(icon: Icons.code, title: '导出为 JSON', desc: '开发者格式，保留完整数据'),
            _ExportOption(icon: Icons.picture_as_pdf, title: '导出为 PDF', desc: '打印友好格式'),
          ],
        ),
      actions: [
        GlassDialogAction(label: '取消', onPressed: () => Navigator.pop(context)),
        GlassDialogAction(label: 'CSV', isPrimary: true, onPressed: () {
          Navigator.pop(context);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('CSV 导出功能开发中...'), backgroundColor: AppTheme.infoColor, behavior: SnackBarBehavior.floating),
            );
          }
        }),
      ],
    );
  }

  // ─── 云备份 ────────────────────────────────────────────────────────────────
  void _showCloudBackupDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white),
            SizedBox(width: 8),
            Text('云备份功能暂未开启，请连接服务器后使用'),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─── 辅助组件 ─────────────────────────────────────────────────────────────────

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  const _EditField({required this.controller, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: label == '年龄' || label.startsWith('身高') ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _ChipSelector<T> extends StatelessWidget {
  final String label;
  final String selected;
  final List<T> options;
  final ValueChanged<T> onSelected;
  const _ChipSelector({required this.label, required this.selected, required this.options, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: options.map((opt) {
            final text = opt.toString();
            final isSelected = text == selected;
            return FilterChip(
              label: Text(text, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontSize: 12)),
              selected: isSelected,
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.4),
              onSelected: (v) => onSelected(opt),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _ExportOption({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(desc, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint),
      onTap: () {},
    );
  }
}

// ─── 各 Section ───────────────────────────────────────────────────────────────

class _ProfileDataCard extends StatelessWidget {
  const _ProfileDataCard();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileService>().profile;
    return GlassCard(
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('个人数据', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 18), fontWeight: FontWeight.bold)),
          SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
          Row(
            children: [
              _DataItem(icon: Icons.cake, label: '年龄', value: '${profile?.age ?? 16}岁'),
              SizedBox(width: ResponsiveUtils.scaleSpacing(context, 24)),
              _DataItem(icon: Icons.height, label: '身高', value: '${profile?.heightCm ?? 170}cm'),
            ],
          ),
          SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
          Row(
            children: [
              _DataItem(icon: Icons.monitor_weight, label: '体重', value: '${profile?.weightKg ?? 65}kg'),
              SizedBox(width: ResponsiveUtils.scaleSpacing(context, 24)),
              _DataItem(icon: Icons.calculate, label: 'BMI', value: '${(profile?.bmi ?? 22.5).toStringAsFixed(1)}\n${profile?.bmiCategory ?? '正常'}'),
            ],
          ),
          SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
          Row(
            children: [
              _DataItem(
                icon: profile?.schoolType == SchoolType.boarder ? Icons.school : Icons.home,
                label: '状态',
                value: profile?.schoolType == SchoolType.boarder ? '住校' : '走读',
              ),
              SizedBox(width: ResponsiveUtils.scaleSpacing(context, 24)),
              _DataItem(icon: Icons.flag, label: '当前阶段', value: '第${profile?.currentWeek ?? 1}周'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DataItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DataItem({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: ResponsiveUtils.scaleIcon(context, 24)),
          SizedBox(height: 4),
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 12))),
          SizedBox(height: 2),
          Text(value, style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 14), fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── 每日激励金句 ──────────────────────────────────────────────────────────────
class _DailyQuoteCard extends StatelessWidget {
  const _DailyQuoteCard();

  String _getQuote() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return _quotes[dayOfYear % _quotes.length];
  }

  static const List<String> _quotes = [
    '自律即自由。——康德',
    '你流过的每一滴汗，都不会背叛你。',
    '不是看到希望才坚持，是坚持了才看到希望。',
    '今天的痛苦，是明天力量的源泉。',
    '简单的事情重复做，你就是专家。',
    '不要假装努力，结果不会陪你演戏。',
    '你现在的努力，藏着未来的运气。',
    '所有逆袭，都是有备而来。',
    '没有奇迹，只有积累。',
    '每一次坚持，都是对未来的投资。',
    '身体和灵魂，总有一个在路上。',
    '种一棵树最好的时间是十年前，其次是现在。',
    '你不需要很厉害才能开始，但你需要开始才能很厉害。',
    '所有的失去，都会以另一种方式归来。',
    '这个世界不会亏待每一个认真努力的人。',
    '你的对手在看书，你的仇人在磨刀，你的闺蜜在减肥，隔壁老王在练腰。',
    '今天偷的懒，都是明天挖的坑。',
    '逼自己一把，人生没有极限。',
    '将来的你，一定会感谢现在拼命的自己。',
    '所谓万丈深渊，下去，也是前程万里。——木心',
    '星光不问赶路人，时光不负有心人。',
    '乾坤未定，你我皆是黑马。',
    '最痛苦的不是失败，而是"我本可以"。',
    '你害怕什么，就去面对什么，你会发现它并没有想象中可怕。',
    '把每个平凡的日子都过好，就是不平凡。',
    '与其羡慕别人的光芒，不如点亮自己的灯。',
    '没有伞的孩子，必须努力奔跑。',
    '人生就像骑自行车，要保持平衡就得往前走。——爱因斯坦',
    '行动是治愈恐惧的良药，犹豫只会加剧恐惧。',
    '成功不是将来才有的，而是从决定去做的那一刻起，持续累积而成。',
    '当你觉得为时已晚的时候，恰恰是最早的时候。',
    '自律的人不一定成功，但不自律的人一定不成功。',
    '你想要的，都得自己去挣。',
    '别在最该努力的年纪，选择了安逸。',
    '今天的克制，是为了明天更大的自由。',
    '不要让你的野心，配不上你的努力。',
    '所有的惊艳，都来自长久的准备。',
    '努力不一定成功，但放弃一定失败。',
    '你的每一分努力，都在为未来铺路。',
    '真正的强者，不是没有眼泪的人，而是含泪奔跑的人。',
    '只有极度自律，才能极度自由。',
    '把每一天都当作最后一天的努力，你才不会后悔。',
    '你跑得多快不重要，重要的是你永远在跑。',
    '今天多流一滴汗，明天少流一滴泪。',
    '人生最重要的不是所站的位置，而是所朝的方向。',
    '成功呈概率分布，关键是你能不能坚持到成功开始呈现的那一刻。',
    '与其抱怨黑暗，不如提灯前行。',
    '你所浪费的今天，是昨天死去的人奢望的明天。',
    '生活不会辜负每一个默默努力的人。',
    '当你觉得累的时候，说明你在走上坡路。',
  ];

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 8)),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.auto_awesome, color: AppTheme.warningColor, size: ResponsiveUtils.scaleIcon(context, 20)),
              ),
              SizedBox(width: ResponsiveUtils.scaleSpacing(context, 10)),
              Text(
                '每日金句',
                style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 16), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.scaleSpacing(context, 14)),
          Text(
            '"${_getQuote()}"',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: ResponsiveUtils.scaleFont(context, 15),
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 本周训练进度 ─────────────────────────────────────────────────────────────
class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileService>().profile;
    final currentWeek = profile?.currentWeek ?? 1;
    final totalWeeks = 8;
    final progress = currentWeek / totalWeeks;

    // 训练日：第1-4周周一/三/五，第5-8周周二/四/六
    final isSecondHalf = currentWeek > 4;
    final trainingDays = isSecondHalf
        ? ['一', '三', '五']
        : ['二', '四', '六'];
    final todayName = ['日', '一', '二', '三', '四', '五', '六'][DateTime.now().weekday % 7];
    final isTrainingToday = trainingDays.contains(todayName);

    final phaseNames = ['适应期', '减脂期', '塑形期', '冲刺期'];
    final currentPhaseIdx = ((currentWeek - 1) ~/ 2) % 4;
    final phaseName = phaseNames[currentPhaseIdx];

    return GlassCard(
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 8)),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.fitness_center, color: AppTheme.primaryColor, size: ResponsiveUtils.scaleIcon(context, 20)),
                  ),
                  SizedBox(width: ResponsiveUtils.scaleSpacing(context, 10)),
                  Text(
                    '训练进度',
                    style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 16), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${currentWeek}/$totalWeeks 周',
                  style: TextStyle(color: AppTheme.successColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),

          // 阶段名称 + 进度条
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phaseName,
                      style: TextStyle(color: AppTheme.primaryColor, fontSize: ResponsiveUtils.scaleFont(context, 14), fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                      color: AppTheme.primaryColor,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '已完成 ${((progress) * 100).round()}%',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveUtils.scaleSpacing(context, 16)),
              // 今日状态
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isTrainingToday
                      ? AppTheme.warningColor.withValues(alpha: 0.2)
                      : AppTheme.textHint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(
                      isTrainingToday ? Icons.fitness_center : Icons.bedtime,
                      color: isTrainingToday ? AppTheme.warningColor : AppTheme.textSecondary,
                      size: ResponsiveUtils.scaleIcon(context, 20),
                    ),
                    SizedBox(height: 4),
                    Text(
                      isTrainingToday ? '今日训练' : '今日休息',
                      style: TextStyle(
                        color: isTrainingToday ? AppTheme.warningColor : AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.scaleSpacing(context, 14)),

          // 周训练日历
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['日', '一', '二', '三', '四', '五', '六'].map((day) {
              final isToday = day == todayName;
              final isTrainingDay = trainingDays.contains(day);
              return Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppTheme.primaryColor
                          : isTrainingDay
                              ? AppTheme.primaryColor.withValues(alpha: 0.25)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: AppTheme.primaryColor, width: 2)
                          : isTrainingDay
                              ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4), width: 1)
                              : null,
                    ),
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: isToday ? Colors.white : isTrainingDay ? AppTheme.primaryColor : AppTheme.textHint,
                          fontSize: 13,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    isTrainingDay ? '练' : '歇',
                    style: TextStyle(
                      color: isTrainingDay ? AppTheme.primaryColor.withValues(alpha: 0.7) : AppTheme.textHint.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppTheme.primaryColor, alpha: 1.0, label: '今日'),
              SizedBox(width: 12),
              _LegendDot(color: AppTheme.primaryColor, alpha: 0.25, label: '训练日'),
              SizedBox(width: 12),
              _LegendDot(color: AppTheme.textHint, alpha: 0.1, label: '休息日'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final double alpha;
  final String label;
  const _LegendDot({required this.color, required this.alpha, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color.withValues(alpha: alpha), shape: BoxShape.circle)),
        SizedBox(width: 4),
        Text(label, style: TextStyle(color: AppTheme.textHint, fontSize: 10)),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final _ProfileScreenContentState state;
  const _SettingsSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('设置', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 18), fontWeight: FontWeight.bold)),
          SizedBox(height: ResponsiveUtils.scaleSpacing(context, 12)),
          _SettingsItem(icon: Icons.edit, title: '编辑资料', onTap: () {
            if (context.read<UserProfileService>().profile != null) {
              state._showEditProfileDialog(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('请先完成引导页设置'), backgroundColor: AppTheme.warningColor, behavior: SnackBarBehavior.floating),
              );
            }
          }),
          Divider(color: AppTheme.textHint),
          _SettingsItem(icon: Icons.tune, title: '选择阶段', subtitle: '第${context.watch<UserProfileService>().profile?.currentWeek ?? 1}周', onTap: () => state._showPhaseSelector(context)),
          Divider(color: AppTheme.textHint),
          _SettingsItem(icon: Icons.notifications, title: '提醒设置', onTap: () => state._showReminderDialog(context)),
          Divider(color: AppTheme.textHint),
          _SettingsItem(icon: Icons.download, title: '导出数据', onTap: () => state._showExportDialog(context)),
          Divider(color: AppTheme.textHint),
          _SettingsItem(icon: Icons.cloud, title: '云备份', subtitle: '已关闭', onTap: () => state._showCloudBackupDialog(context)),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _SettingsItem({required this.icon, required this.title, this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(color: AppTheme.textHint)) : null,
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint),
      onTap: onTap,
    );
  }
}

class _DebugSection extends StatelessWidget {
  const _DebugSection();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('调试工具', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 18), fontWeight: FontWeight.bold)),
          SizedBox(height: ResponsiveUtils.scaleSpacing(context, 12)),
          _DebugItem(icon: Icons.cloud_upload, title: '上传全部数据', subtitle: '打卡 + 运动 + 设备信息', color: AppTheme.primaryColor, onTap: () => _uploadAll(context)),
          Divider(color: AppTheme.textHint),
          _DebugItem(icon: Icons.fitness_center, title: '上传运动数据', subtitle: '最近7天运动记录', color: AppTheme.secondaryColor, onTap: () => _uploadWorkoutOnly(context)),
          Divider(color: AppTheme.textHint),
          _DebugItem(icon: Icons.check_circle, title: '上传打卡数据', subtitle: '最近7天打卡记录', color: AppTheme.successColor, onTap: () => _uploadCheckInOnly(context)),
          Divider(color: AppTheme.textHint),
          _DebugItem(icon: Icons.wifi, title: '测试连接', subtitle: '测试服务器连通性', color: AppTheme.warningColor, onTap: () => _testConnection(context)),
        ],
      ),
    );
  }

  void _uploadAll(BuildContext context) {
    final service = context.read<DebugUploadService>();
    showDialog(context: context, builder: (_) => _DebugPanelDialog(service: service));
  }

  Future<void> _uploadWorkoutOnly(BuildContext context) async {
    final service = context.read<DebugUploadService>();
    final result = await service.uploadWorkoutData();
    if (context.mounted) _showResult(context, result);
  }

  Future<void> _uploadCheckInOnly(BuildContext context) async {
    final service = context.read<DebugUploadService>();
    final result = await service.uploadCheckInData();
    if (context.mounted) _showResult(context, result);
  }

  Future<void> _testConnection(BuildContext context) async {
    final service = context.read<DebugUploadService>();
    final result = await service.testConnection();
    if (context.mounted) _showResult(context, result);
  }

  void _showResult(BuildContext context, dynamic result) {
    final success = result is Map && (result['success'] as bool? ?? false);
    final message = result is Map ? (result['error'] as String? ?? '完成') : result.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? message : '失败: $message'), backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor, behavior: SnackBarBehavior.floating),
    );
  }
}

class _DebugItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  const _DebugItem({required this.icon, required this.title, this.subtitle, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(color: AppTheme.textHint)) : null,
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint),
      onTap: onTap,
    );
  }
}

class _DebugPanelDialog extends StatefulWidget {
  final DebugUploadService service;
  const _DebugPanelDialog({required this.service});
  @override
  State<_DebugPanelDialog> createState() => _DebugPanelDialogState();
}

class _DebugPanelDialogState extends State<_DebugPanelDialog> {
  final _urlController = TextEditingController();
  @override
  void initState() { super.initState(); _urlController.text = widget.service.serverUrl; }
  @override
  void dispose() { _urlController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1a1a2e),
      title: const Text('调试面板', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 320,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('服务器地址:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'http://192.168.x.x:8080/api/debug/upload',
              hintStyle: const TextStyle(color: AppTheme.textHint),
              filled: true, fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5))),
            ),
          ),
          const SizedBox(height: 16),
          Consumer<DebugUploadService>(
            builder: (context, service, _) => Text(
              '状态: ${service.lastStatus}',
              style: TextStyle(color: service.lastStatus.contains('成功') ? AppTheme.successColor : service.lastStatus.contains('失败') ? AppTheme.errorColor : AppTheme.textSecondary, fontSize: 12),
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: AppTheme.textSecondary))),
        TextButton(onPressed: () { widget.service.setServerUrl(_urlController.text); Navigator.pop(context); }, child: const Text('保存', style: TextStyle(color: AppTheme.primaryColor))),
      ],
    );
  }
}