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

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfileService()..init()),
        ChangeNotifierProvider(create: (_) => DebugUploadService()),
      ],
      child: const _ProfileScreenContent(),
    );
  }
}

class _ProfileScreenContent extends StatelessWidget {
  const _ProfileScreenContent();

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 头像
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.watch<UserProfileService>().profile?.name ?? '自律者',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '正在自律中...',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // 个人数据卡片
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: const _ProfileDataCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 成就徽章
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: const _BadgesSection(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 设置选项
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: const _SettingsSection(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 调试选项
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: const _DebugSection(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _ProfileDataCard extends StatelessWidget {
  const _ProfileDataCard();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileService>().profile;
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '个人数据',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _DataItem(
                icon: Icons.cake,
                label: '年龄',
                value: '${profile?.age ?? 16}岁',
              ),
              const SizedBox(width: 24),
              _DataItem(
                icon: Icons.height,
                label: '身高',
                value: '${profile?.heightCm ?? 170}cm',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _DataItem(
                icon: Icons.monitor_weight,
                label: '体重',
                value: '${profile?.weightKg ?? 65}kg',
              ),
              const SizedBox(width: 24),
              _DataItem(
                icon: Icons.calculate,
                label: 'BMI',
                value: '${(profile?.bmi ?? 22.5).toStringAsFixed(1)}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _DataItem(
                icon: profile?.schoolType == SchoolType.boarder ? Icons.school : Icons.home,
                label: '状态',
                value: profile?.schoolType == SchoolType.boarder ? '住校' : '走读',
              ),
              const SizedBox(width: 24),
              _DataItem(
                icon: Icons.flag,
                label: '当前阶段',
                value: '第${profile?.currentWeek ?? 1}周',
              ),
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

  const _DataItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '成就徽章',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: AppConstants.badges.map((badge) {
              return BadgeWidget(
                badge: badge,
                isUnlocked: false, // 实际应检查是否解锁
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '设置',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _SettingsItem(
            icon: Icons.edit,
            title: '编辑资料',
            onTap: () {},
          ),
          const Divider(color: AppTheme.textHint),
          _SettingsItem(
            icon: Icons.tune,
            title: '选择阶段',
            onTap: () {},
          ),
          const Divider(color: AppTheme.textHint),
          _SettingsItem(
            icon: Icons.notifications,
            title: '提醒设置',
            onTap: () {},
          ),
          const Divider(color: AppTheme.textHint),
          _SettingsItem(
            icon: Icons.download,
            title: '导出数据',
            onTap: () {},
          ),
          const Divider(color: AppTheme.textHint),
          _SettingsItem(
            icon: Icons.cloud,
            title: '云备份',
            subtitle: '已关闭',
            onTap: () {},
          ),
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

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(color: AppTheme.textHint),
            )
          : null,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '调试工具',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _DebugItem(
            icon: Icons.cloud_upload,
            title: '上传全部数据',
            subtitle: '打卡 + 运动 + 设备信息',
            color: AppTheme.primaryColor,
            onTap: () => _showDebugPanel(context),
          ),
          const Divider(color: AppTheme.textHint),
          _DebugItem(
            icon: Icons.fitness_center,
            title: '上传运动数据',
            subtitle: '最近7天运动记录',
            color: AppTheme.secondaryColor,
            onTap: () => _uploadWorkoutOnly(context),
          ),
          const Divider(color: AppTheme.textHint),
          _DebugItem(
            icon: Icons.check_circle,
            title: '上传打卡数据',
            subtitle: '最近7天打卡记录',
            color: AppTheme.successColor,
            onTap: () => _uploadCheckInOnly(context),
          ),
          const Divider(color: AppTheme.textHint),
          _DebugItem(
            icon: Icons.wifi,
            title: '测试连接',
            subtitle: '测试服务器连通性',
            color: AppTheme.warningColor,
            onTap: () => _testConnection(context),
          ),
        ],
      ),
    );
  }

  void _showDebugPanel(BuildContext context) {
    final service = context.read<DebugUploadService>();
    showDialog(
      context: context,
      builder: (ctx) => _DebugPanelDialog(service: service),
    );
  }

  Future<void> _uploadWorkoutOnly(BuildContext context) async {
    final service = context.read<DebugUploadService>();
    final result = await service.uploadWorkoutData();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success ? '运动数据已上传' : '上传失败: ${result.error}'),
          backgroundColor: result.success ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _uploadCheckInOnly(BuildContext context) async {
    final service = context.read<DebugUploadService>();
    final result = await service.uploadCheckInData();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success ? '打卡数据已上传' : '上传失败: ${result.error}'),
          backgroundColor: result.success ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _testConnection(BuildContext context) async {
    final service = context.read<DebugUploadService>();
    final result = await service.testConnection();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }
}

class _DebugItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DebugItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(color: AppTheme.textHint),
            )
          : null,
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.service.serverUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1a1a2e),
      title: const Text(
        '调试面板',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('服务器地址:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'http://192.168.x.x:8080/api/debug/upload',
                hintStyle: const TextStyle(color: AppTheme.textHint),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Consumer<DebugUploadService>(
              builder: (context, service, _) {
                return Text(
                  '状态: ${service.lastStatus}',
                  style: TextStyle(
                    color: service.lastStatus.contains('成功')
                        ? AppTheme.successColor
                        : service.lastStatus.contains('失败')
                            ? AppTheme.errorColor
                            : AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            widget.service.setServerUrl(_urlController.text);
            Navigator.pop(context);
          },
          child: const Text('保存', style: TextStyle(color: AppTheme.primaryColor)),
        ),
      ],
    );
  }
}
