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

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:metamorphosis_checkin/services/desire_space_service.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';
import 'package:metamorphosis_checkin/utils/desire_popup_texts.dart';
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
    // 弹窗随机池 = 你在 App 里「添加提醒」写的内容 + desire_popup_texts.dart 里手写的内容
    final pool = <String>[
      ...service.notes,
      ...kDesirePopupTexts,
    ];

    return Stack(
      children: [
        ListView(
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.scalePadding(context, 16),
        ResponsiveUtils.scalePadding(context, 16),
        ResponsiveUtils.scalePadding(context, 16),
        // 额外留出底部弹窗控制栏的高度，避免最后一块内容被它挡住
        ResponsiveUtils.bottomSafePadding(context) + 70,
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
        ),

        // 弹窗层放在内容之上；它的控制条又在所有弹窗之上，
        // 保证任何时候都能一键停下来，不会被自己弹出来的东西挡住。
        _PopupStorm(pool: pool),
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

// ─── 弹窗层 ──────────────────────────────────────────────────────────────────
/// 进入本页后立即开始、源源不断弹出的文字弹窗，散布在屏幕不同位置。
///
/// 工程约束（很重要）：
///  · 并发上限 kDesirePopupMaxConcurrent —— 每个弹窗都是独立 widget + 合成层，
///    不设上限会迅速压垮渲染（掉帧 / 发热，严重时 OOM 闪退）。
///  · 每个弹窗到时间自动消失；点位取自「网格 + 抖动」，比纯随机更均匀。
///  · 用普通 Container 而不是 GlassCard：玻璃卡片每张都会 pushLayer，
///    十几个叠在一起 GPU 就直接爆了。
///  · 底部固定一条控制栏（暂停 / 继续 / 清空），永远在最上层 ——
///    避免弹窗把操作挡死，变成自己出不去。
///  · 点任意弹窗即可单独关掉它。
class _PopupStorm extends StatefulWidget {
  final List<String> pool;
  const _PopupStorm({required this.pool});

  @override
  State<_PopupStorm> createState() => _PopupStormState();
}

class _PopupItem {
  final int id;
  final String text;
  final double fx; // 0~1 横向比例
  final double fy; // 0~1 纵向比例
  final int bornMs;

  _PopupItem({
    required this.id,
    required this.text,
    required this.fx,
    required this.fy,
    required this.bornMs,
  });
}

class _PopupStormState extends State<_PopupStorm> {
  final List<_PopupItem> _items = [];
  final math.Random _random = math.Random();
  Timer? _spawnTimer;
  Timer? _sweepTimer;
  int _nextId = 0;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    // 一进页面立刻先弹一个，不用等第一个周期
    WidgetsBinding.instance.addPostFrameCallback((_) => _spawn());
    _spawnTimer = Timer.periodic(kDesirePopupInterval, (_) => _spawn());
    _sweepTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => _sweep());
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _sweepTimer?.cancel();
    super.dispose();
  }

  void _spawn() {
    if (!mounted || !_running) return;
    if (widget.pool.isEmpty) return;
    if (_items.length >= kDesirePopupMaxConcurrent) return;
    setState(() {
      _items.add(_PopupItem(
        id: _nextId++,
        text: widget.pool[_random.nextInt(widget.pool.length)],
        fx: ((_random.nextInt(3) + _random.nextDouble()) / 3).clamp(0.0, 1.0),
        fy: ((_random.nextInt(5) + _random.nextDouble()) / 5).clamp(0.0, 1.0),
        bornMs: DateTime.now().millisecondsSinceEpoch,
      ));
    });
  }

  void _sweep() {
    if (!mounted) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final life = kDesirePopupLifetime.inMilliseconds;
    if (!_items.any((e) => now - e.bornMs > life)) return;
    setState(() => _items.removeWhere((e) => now - e.bornMs > life));
  }

  void _dismiss(_PopupItem item) {
    setState(() => _items.removeWhere((e) => e.id == item.id));
  }

  void _toggleRunning() {
    setState(() => _running = !_running);
    if (_running) _spawn();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double cardWidth = constraints.maxWidth * kDesirePopupWidthFactor;
      // 用于夹紧位置，保证弹窗不会被挤出屏幕（高度为估算值）
      const double estimatedHeight = 150;
      // 注意用 0.0 而不是 0：math.max 的泛型会按两个实参推断，
      // 传 (int, double) 会推断成 num，赋给 double 直接编译失败。
      final double maxLeft = math.max(0.0, constraints.maxWidth - cardWidth);
      final double maxTop = math.max(0.0, constraints.maxHeight - estimatedHeight);

      return Stack(children: [
        for (final item in _items)
          Positioned(
            left: item.fx * maxLeft,
            top: item.fy * maxTop,
            child: _bubble(context, item, cardWidth),
          ),

        Positioned(
          left: 0,
          right: 0,
          // 抬到悬浮导航栏之上
          bottom: ResponsiveUtils.bottomSafePadding(context),
          child: _controls(context),
        ),
      ]);
    });
  }

  Widget _bubble(BuildContext context, _PopupItem item, double width) {
    return GestureDetector(
      onTap: () => _dismiss(item),
      child: SizedBox(
        width: width,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.scalePadding(context, 14),
            vertical: ResponsiveUtils.scalePadding(context, 12),
          ),
          decoration: BoxDecoration(
            // 接近不透明的实色 + 描边，而不是玻璃卡片
            color: const Color(0xF21A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.secondaryColor.withValues(alpha: 0.65), width: 1.5),
          ),
          child: Text(
            item.text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveUtils.scaleFont(context, 13),
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }

  Widget _controls(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.scalePadding(context, 12)),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.scalePadding(context, 12),
        vertical: ResponsiveUtils.scalePadding(context, 6),
      ),
      decoration: BoxDecoration(
        color: const Color(0xF2101018),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('弹窗 ${_items.length} / $kDesirePopupMaxConcurrent',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 12))),
        Row(children: [
          TextButton(
            onPressed: _toggleRunning,
            child: Text(_running ? '暂停弹窗' : '继续弹窗',
                style: TextStyle(color: AppTheme.primaryColor, fontSize: ResponsiveUtils.scaleFont(context, 12.5))),
          ),
          TextButton(
            onPressed: () => setState(_items.clear),
            child: Text('清空',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 12.5))),
          ),
        ]),
      ]),
    );
  }
}
