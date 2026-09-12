/// 个人资料页
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:metamorphosis_checkin/services/user_profile_service.dart';
import 'package:metamorphosis_checkin/services/debug_upload_service.dart';
import 'package:metamorphosis_checkin/utils/constants.dart';
import 'package:metamorphosis_checkin/models/user_profile.dart';
import 'package:metamorphosis_checkin/widgets/badge_widget.dart';
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

          // 成就徽章
          SliverPadding(
            padding: ResponsiveUtils.scaleHorizontalEdgeInsets(context, 20),
            sliver: SliverToBoxAdapter(child: const _BadgesSection()),
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

    await showDialog(
      context: context,
      builder: (_) => GlassDialog.show<String?>(
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
      ),
    );
  }

  // ─── 阶段选择 ──────────────────────────────────────────────────────────────
  Future<void> _showPhaseSelector(BuildContext context) async {
    final profile = context.read<UserProfileService>().profile;
    final currentWeek = profile?.currentWeek ?? 1;
    await showDialog(
      context: context,
      builder: (_) => GlassDialog.show<int?>(
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
      ),
    ).then((week) async {
      if (week != null && context.mounted) {
        await context.read<UserProfileService>().updateWeek(week);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已切换到第 $week 周'), backgroundColor: AppTheme.primaryColor, behavior: SnackBarBehavior.floating),
          );
        }
      }
    });
  }

  // ─── 提醒设置 ──────────────────────────────────────────────────────────────
  void _showReminderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => GlassDialog.show<void>(
        context: context,
        title: '提醒设置',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('提醒时间（暂不可用）', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            SizedBox(height: 8),
            ListTile(
              title: Text('晨起提醒', style: TextStyle(color: Colors.white)),
              subtitle: Text('每天 07:00'),
              trailing: Switch(value: false, onChanged: (v) {}),
            ),
            ListTile(
              title: Text('运动提醒', style: TextStyle(color: Colors.white)),
              subtitle: Text('每天 18:00'),
              trailing: Switch(value: false, onChanged: (v) {}),
            ),
            ListTile(
              title: Text('睡前提醒', style: TextStyle(color: Colors.white)),
              subtitle: Text('每天 22:00'),
              trailing: Switch(value: false, onChanged: (v) {}),
            ),
          ],
        ),
        actions: [
          GlassDialogAction(label: '知道了', isPrimary: true, onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  // ─── 导出数据 ──────────────────────────────────────────────────────────────
  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => GlassDialog.show<void>(
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
      ),
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

class _BadgesSection extends StatelessWidget {
  const _BadgesSection();
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('成就徽章', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 18), fontWeight: FontWeight.bold)),
          SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: AppConstants.badges.map((badge) => BadgeWidget(badge: badge, isUnlocked: false)).toList(),
          ),
        ],
      ),
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
    if (context.mounted) _showResult(result);
  }

  Future<void> _uploadCheckInOnly(BuildContext context) async {
    final service = context.read<DebugUploadService>();
    final result = await service.uploadCheckInData();
    if (context.mounted) _showResult(result);
  }

  Future<void> _testConnection(BuildContext context) async {
    final service = context.read<DebugUploadService>();
    final result = await service.testConnection();
    if (context.mounted) _showResult(result);
  }

  void _showResult(dynamic result) {
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