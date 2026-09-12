/// 欲望空间 —— 本地私密照片页（底部导航第 6 个 Tab）
///
/// 两层结构：
///   1. 未确认 → 18+ 与说明页（勾选 + 确认，持久化，是一个页面而非弹窗）
///   2. 主界面 → **只有一张照片**，铺满可用区域
///
/// 照片仅存于应用私有目录，不做任何上传；页面不预置任何文案。
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:metamorphosis_checkin/services/desire_space_service.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';
import 'package:metamorphosis_checkin/utils/responsive_utils.dart';
import 'package:provider/provider.dart';

class DesireSpaceScreen extends StatelessWidget {
  const DesireSpaceScreen({super.key});

  @override
  Widget build(BuildContext context) => const _DesireSpaceContent();
}

class _DesireSpaceContent extends StatefulWidget {
  const _DesireSpaceContent();

  @override
  State<_DesireSpaceContent> createState() => _DesireSpaceContentState();
}

class _DesireSpaceContentState extends State<_DesireSpaceContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final service = context.watch<DesireSpaceService>();
    if (!service.agreed) return const _AgreementGate();
    return _PhotoView(service: service);
  }
}

// ─── 1. 18+ 与说明页 ─────────────────────────────────────────────────────────
class _AgreementGate extends StatefulWidget {
  const _AgreementGate();

  @override
  State<_AgreementGate> createState() => _AgreementGateState();
}

class _AgreementGateState extends State<_AgreementGate> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.scalePadding(context, 20),
        ResponsiveUtils.scalePadding(context, 24),
        ResponsiveUtils.scalePadding(context, 20),
        ResponsiveUtils.bottomSafePadding(context),
      ),
      children: [
        Text('欲望空间',
            style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 26), fontWeight: FontWeight.bold)),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 4)),
        Text('进入前请先读完这一页',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 13))),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 20)),

        GlassCard(
          padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _paragraph(context, '这一页做什么',
                '它会长期展示一张你自己选择的照片，在冲动上来的时候给自己一个'
                '「停一下」的机会。'),
            SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
            _paragraph(context, '你需要知道的副作用',
                '这是「厌恶 / 羞耻」类动机法。它确实可能短期有效，'
                '但对相当一部分人会加重自责与内耗，反而更容易反复——'
                '这也是它不被现代行为医学推荐的原因。\n\n'
                '如果你发现用完它之后情绪更差、更自责，请立刻停用并删除照片。'),
            SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
            _paragraph(context, '隐私',
                '· 照片复制到应用私有目录，只存在这台设备上\n'
                '· 本页没有任何上传代码，也不会联网发送\n'
                '· 卸载 App 即彻底消失\n'
                '· 选择照片走系统自带的选择器，不需要任何存储权限'),
            SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
            _paragraph(context, '适用范围',
                '仅供 18 岁以上用户使用。如果你未满 18 岁，请不要继续。'),
          ]),
        ),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),

        GlassCard(
          padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 14)),
          child: Row(children: [
            Checkbox(
              value: _checked,
              onChanged: (v) => setState(() => _checked = v ?? false),
              activeColor: AppTheme.primaryColor,
              checkColor: Colors.white,
              side: const BorderSide(color: AppTheme.textHint),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _checked = !_checked),
                child: Text('我已满 18 岁，并已阅读、理解上述说明，愿意自行承担使用后果',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 12), height: 1.4)),
              ),
            ),
          ]),
        ),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),

        Opacity(
          opacity: _checked ? 1.0 : 0.4,
          child: GlassButton.custom(
            onTap: _checked ? () => context.read<DesireSpaceService>().agree() : () {},
            width: double.infinity,
            height: ResponsiveUtils.scaleButtonHeight(context, 50),
            child: const Text('进入欲望空间', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _paragraph(BuildContext context, String title, String body) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: AppTheme.primaryColor, fontSize: ResponsiveUtils.scaleFont(context, 14), fontWeight: FontWeight.bold)),
      SizedBox(height: ResponsiveUtils.scaleSpacing(context, 6)),
      Text(body, style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 12.5), height: 1.6)),
    ]);
  }
}

// ─── 2. 主界面：只有一张照片 ──────────────────────────────────────────────────
class _PhotoView extends StatelessWidget {
  final DesireSpaceService service;
  const _PhotoView({required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部一行：标题 + 少量必要操作（不占地方）
        Padding(
          padding: EdgeInsets.fromLTRB(
            ResponsiveUtils.scalePadding(context, 16),
            ResponsiveUtils.scalePadding(context, 12),
            ResponsiveUtils.scalePadding(context, 12),
            0,
          ),
          child: Row(children: [
            Text('欲望空间',
                style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 20), fontWeight: FontWeight.bold)),
            const Spacer(),
            if (service.hasPhoto) ...[
              TextButton(
                onPressed: () => _pickPhoto(context),
                child: Text('更换',
                    style: TextStyle(color: AppTheme.primaryColor, fontSize: ResponsiveUtils.scaleFont(context, 13))),
              ),
              TextButton(
                onPressed: () => _confirmRemovePhoto(context),
                child: Text('删除',
                    style: TextStyle(color: AppTheme.errorColor.withValues(alpha: 0.85), fontSize: ResponsiveUtils.scaleFont(context, 13))),
              ),
            ],
          ]),
        ),

        // 照片：占满剩余全部空间
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.scalePadding(context, 12),
              ResponsiveUtils.scaleSpacing(context, 8),
              ResponsiveUtils.scalePadding(context, 12),
              // 抬到悬浮导航栏之上，避免照片底部被遮挡
              ResponsiveUtils.bottomBarHeight + ResponsiveUtils.bottomBarMargin + 4,
            ),
            child: GestureDetector(
              onTap: service.hasPhoto ? null : () => _pickPhoto(context),
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: service.hasPhoto
                    ? Image.file(
                        File(service.photoPath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        gaplessPlayback: true,
                        // 图片损坏 / 被删时退回提示页，不要白屏
                        errorBuilder: (context, error, stack) => _prompt(context),
                      )
                    : _prompt(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 未选择照片时的提示
  Widget _prompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: AppTheme.textHint, size: ResponsiveUtils.scaleIcon(context, 56)),
            SizedBox(height: ResponsiveUtils.scaleSpacing(context, 18)),
            Text(
              '上传一张你自己觉得羞涩、\n不愿被别人看到的照片',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.scaleFont(context, 17),
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            SizedBox(height: ResponsiveUtils.scaleSpacing(context, 14)),
            Text('点击这里选择照片',
                style: TextStyle(color: AppTheme.primaryColor, fontSize: ResponsiveUtils.scaleFont(context, 14), fontWeight: FontWeight.w600)),
            SizedBox(height: ResponsiveUtils.scaleSpacing(context, 18)),
            Text('仅保存在本机 · 不会上传到任何地方',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textHint, fontSize: ResponsiveUtils.scaleFont(context, 11.5))),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
      final path = result?.files.single.path;
      if (path == null || path.isEmpty) return;
      final ok = await service.setPhoto(path);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '照片已保存到本机' : '保存失败，请换一张重试'),
        backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('选择照片失败: $e'),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _confirmRemovePhoto(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text('删除照片', style: TextStyle(color: Colors.white)),
        content: Text('照片会从本机彻底删除，无法恢复。', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除', style: TextStyle(color: AppTheme.errorColor))),
        ],
      ),
    );
    if (confirmed == true) await service.removePhoto();
  }
}
