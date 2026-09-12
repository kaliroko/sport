/// 欲望空间 —— 私密的戒断动机页（底部导航第 6 个 Tab）
///
/// 三层结构：
///   1. 未确认 → 18+ 与动机法说明的确认页（勾选 + 确认，持久化）
///   2. 已设 PIN 且未解锁 → 解锁页
///   3. 主界面 → 正中央是你自己选的照片，下方是你自己写下的提醒
///
/// 本页**不预置任何性暗示或羞辱文案**：所有文字由用户自己写。
/// 照片仅存于应用私有目录，不做任何上传。
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

  final TextEditingController _pinCtrl = TextEditingController();

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final service = context.watch<DesireSpaceService>();

    if (!service.agreed) return const _AgreementGate();
    if (service.hasPin && !service.isUnlocked) {
      return _PinLock(controller: _pinCtrl, onUnlock: () {
        if (service.verifyPin(_pinCtrl.text)) {
          service.unlock();
          _pinCtrl.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('PIN 不正确'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ));
        }
      });
    }
    return _SpaceContent(service: service);
  }
}

// ─── 1. 18+ 与动机法确认页 ────────────────────────────────────────────────────
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
                '它会长期展示一张你自己选择的照片，配合你自己写下的提醒，'
                '在冲动上来的时候给自己一个「停一下」的机会。'),
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
                '· 建议另外设置一个 PIN 锁，避免他人翻到你手机时看到'),
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
            onTap: _checked
                ? () => context.read<DesireSpaceService>().agree()
                : () {},
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

// ─── 2. PIN 解锁 ─────────────────────────────────────────────────────────────
class _PinLock extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onUnlock;

  const _PinLock({required this.controller, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 24)),
        child: GlassCard(
          padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 20)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lock_outline, color: AppTheme.primaryColor, size: ResponsiveUtils.scaleIcon(context, 40)),
            SizedBox(height: ResponsiveUtils.scaleSpacing(context, 12)),
            Text('欲望空间已锁定',
                style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 18), fontWeight: FontWeight.bold)),
            SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 8,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                hintText: '输入 PIN',
                hintStyle: const TextStyle(color: AppTheme.textHint, letterSpacing: 0),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => onUnlock(),
            ),
            SizedBox(height: ResponsiveUtils.scaleSpacing(context, 12)),
            GlassButton.custom(
              onTap: onUnlock,
              width: double.infinity,
              height: ResponsiveUtils.scaleButtonHeight(context, 46),
              child: const Text('解锁', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── 3. 主界面 ───────────────────────────────────────────────────────────────
class _SpaceContent extends StatelessWidget {
  final DesireSpaceService service;
  const _SpaceContent({required this.service});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.scalePadding(context, 16),
        ResponsiveUtils.scalePadding(context, 16),
        ResponsiveUtils.scalePadding(context, 16),
        ResponsiveUtils.bottomSafePadding(context),
      ),
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('欲望空间',
              style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 24), fontWeight: FontWeight.bold)),
          if (service.hasPin)
            GestureDetector(
              onTap: service.lock,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(Icons.lock, size: ResponsiveUtils.scaleIcon(context, 13), color: AppTheme.textSecondary),
                  SizedBox(width: ResponsiveUtils.scaleSpacing(context, 4)),
                  Text('锁定', style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 12))),
                ]),
              ),
            ),
        ]),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),

        // ─── 正中央的照片 ───
        Center(
          child: GestureDetector(
            onTap: () => _pickPhoto(context),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.46,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.35), width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: service.hasPhoto
                  ? Image.file(
                      File(service.photoPath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stack) => _placeholder(context),
                    )
                  : AspectRatio(aspectRatio: 4 / 3, child: _placeholder(context)),
            ),
          ),
        ),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 10)),

        Row(children: [
          Expanded(child: _smallButton(context, '更换照片', () => _pickPhoto(context))),
          SizedBox(width: ResponsiveUtils.scaleSpacing(context, 8)),
          Expanded(child: _smallButton(context, '添加提醒', () => _addNote(context))),
          SizedBox(width: ResponsiveUtils.scaleSpacing(context, 8)),
          Expanded(child: _smallButton(context, 'PIN 锁', () => _setPin(context))),
        ]),

        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 20)),

        // ─── 用户自己写下的提醒 ───
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('我写给自己',
              style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 16), fontWeight: FontWeight.bold)),
          Text('全部由你自己写', style: TextStyle(color: AppTheme.textHint, fontSize: ResponsiveUtils.scaleFont(context, 11))),
        ]),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 10)),

        if (service.notes.isEmpty)
          GlassCard(
            padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
            child: Text(
              '还没有内容。点「添加提醒」写下几句在冲动时能拉住自己的话——'
              '比如你想成为什么样的人、已经坚持了多久、破功之后会有多后悔。',
              style: TextStyle(color: AppTheme.textHint, fontSize: ResponsiveUtils.scaleFont(context, 12), height: 1.5),
            ),
          )
        else
          ...service.notes.asMap().entries.map((entry) => Padding(
            padding: EdgeInsets.only(bottom: ResponsiveUtils.scaleSpacing(context, 10)),
            child: GlassCard(
              padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 14)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.format_quote, color: AppTheme.primaryColor, size: ResponsiveUtils.scaleIcon(context, 18)),
                SizedBox(width: ResponsiveUtils.scaleSpacing(context, 10)),
                Expanded(child: Text(entry.value,
                    style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 14), height: 1.5))),
                IconButton(
                  onPressed: () => service.removeNote(entry.key),
                  icon: Icon(Icons.close, color: AppTheme.textHint, size: ResponsiveUtils.scaleIcon(context, 16)),
                ),
              ]),
            ),
          )),

        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
        if (service.hasPhoto)
          Center(child: TextButton(
            onPressed: () => _confirmRemovePhoto(context),
            child: Text('删除照片', style: TextStyle(color: AppTheme.errorColor.withValues(alpha: 0.8), fontSize: ResponsiveUtils.scaleFont(context, 12))),
          )),
      ],
    );
  }

  Widget _placeholder(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_photo_alternate_outlined, color: AppTheme.textHint, size: ResponsiveUtils.scaleIcon(context, 48)),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
        Text('点击选择一张照片', style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 14))),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 4)),
        Text('仅保存在本机，不会上传', style: TextStyle(color: AppTheme.textHint, fontSize: ResponsiveUtils.scaleFont(context, 11))),
      ]),
    );
  }

  Widget _smallButton(BuildContext context, String label, VoidCallback onTap) {
    return GlassButton.custom(
      onTap: onTap,
      height: ResponsiveUtils.scaleButtonHeight(context, 40),
      child: Text(label, style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 12), fontWeight: FontWeight.w600)),
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

  Future<void> _addNote(BuildContext context) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text('写给自己', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '写几句在冲动时能拉住自己的话',
            hintStyle: const TextStyle(color: AppTheme.textHint),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('保存', style: TextStyle(color: AppTheme.primaryColor))),
        ],
      ),
    );
    if (text != null) await service.addNote(text);
  }

  Future<void> _setPin(BuildContext context) async {
    final ctrl = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text('设置 PIN 锁', style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('留空并保存即取消 PIN。',
              style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 8,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              counterText: '',
              hintText: '4~8 位数字',
              hintStyle: const TextStyle(color: AppTheme.textHint),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('保存', style: TextStyle(color: AppTheme.primaryColor))),
        ],
      ),
    );
    if (pin != null) await service.setPin(pin);
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
