/// 外观设置页：壁纸（内置渐变预设 / 相册自定义图片）+ 模糊与压暗调节
///
/// 本页自己渲染 AppBackground，这样调节参数时可以**实时预览**效果。
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:metamorphosis_checkin/services/app_settings_service.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';
import 'package:metamorphosis_checkin/utils/responsive_utils.dart';
import 'package:metamorphosis_checkin/utils/wallpaper_presets.dart';
import 'package:metamorphosis_checkin/widgets/app_background.dart';
import 'package:provider/provider.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsService>();

    return Stack(
      fit: StackFit.expand,
      children: [
        const AppBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('外观设置', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 18), fontWeight: FontWeight.bold)),
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
              // ─── 自定义图片 ───
              GlassCard(
                padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('自定义图片', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 16), fontWeight: FontWeight.bold)),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 6)),
                  Text(
                    '从相册选一张图作为背景。图片会复制到应用私有目录，'
                    '之后删除相册原图也不会影响壁纸。',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 12)),
                  ),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 12)),
                  GlassButton.custom(
                    onTap: () => _pickImage(context, settings),
                    width: double.infinity,
                    height: ResponsiveUtils.scaleButtonHeight(context, 46),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.photo_library, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('从相册选择', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  if (settings.usesImageWallpaper) ...[
                    SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
                    Text('当前正在使用自定义图片', style: TextStyle(color: AppTheme.successColor, fontSize: ResponsiveUtils.scaleFont(context, 11))),
                  ],
                ]),
              ),
              SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),

              // ─── 内置预设 ───
              GlassCard(
                padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('内置配色', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 16), fontWeight: FontWeight.bold)),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 12)),
                  Wrap(
                    spacing: ResponsiveUtils.scaleSpacing(context, 12),
                    runSpacing: ResponsiveUtils.scaleSpacing(context, 12),
                    children: WallpaperPresets.all.map((preset) {
                      final bool selected = !settings.usesImageWallpaper &&
                          settings.wallpaperPresetId == preset.id;
                      final double swatch = ResponsiveUtils.scaleSize(context, 68);
                      return GestureDetector(
                        onTap: () => settings.selectPreset(preset.id),
                        child: Column(children: [
                          Container(
                            width: swatch,
                            height: swatch,
                            decoration: BoxDecoration(
                              gradient: preset.gradient,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? AppTheme.primaryColor : Colors.white24,
                                width: selected ? 3 : 1,
                              ),
                            ),
                            child: selected
                                ? const Center(child: Icon(Icons.check_circle, color: Colors.white, size: 22))
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(preset.name, style: TextStyle(
                            color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
                            fontSize: ResponsiveUtils.scaleFont(context, 11),
                          )),
                        ]),
                      );
                    }).toList(),
                  ),
                ]),
              ),
              SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),

              // ─── 文字大小 ───
              GlassCard(
                padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('文字大小', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 16), fontWeight: FontWeight.bold)),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 6)),
                  Text(
                    '统一放大或缩小全 App 的文字，会叠加在系统的无障碍字号之上。',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 12)),
                  ),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 12)),

                  // 档位选择
                  Row(
                    children: List.generate(AppSettingsService.textScaleOptions.length, (i) {
                      final option = AppSettingsService.textScaleOptions[i];
                      final selected = (settings.textScale - option).abs() < 0.01;
                      final isLast = i == AppSettingsService.textScaleOptions.length - 1;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: isLast ? 0 : ResponsiveUtils.scaleSpacing(context, 8),
                          ),
                          child: GestureDetector(
                            onTap: () => settings.setTextScale(option),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.scalePadding(context, 10)),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppTheme.primaryColor.withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: selected ? AppTheme.primaryColor : Colors.transparent),
                              ),
                              child: Center(
                                child: Text(
                                  AppSettingsService.textScaleLabels[i],
                                  style: TextStyle(
                                    color: selected ? Colors.white : AppTheme.textSecondary,
                                    fontSize: ResponsiveUtils.scaleFont(context, 13),
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 12)),

                  // 实时预览：用固定的基准字号展示，不受当前倍率影响，
                  // 否则调一次预览也跟着变大，看不出相对变化。
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 12)),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('预览：今天也要加油哦！'),
                      const SizedBox(height: 4),
                      Text('坚持就是胜利，你已经很棒了！',
                          style: TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text('连续打卡 7 天 · 完成率 90%',
                          style: TextStyle(color: AppTheme.textHint)),
                    ]),
                  ),

                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('当前倍率', style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 12))),
                    Text('${(settings.textScale * 100).round()}%',
                        style: TextStyle(color: AppTheme.primaryColor, fontSize: ResponsiveUtils.scaleFont(context, 13), fontWeight: FontWeight.w600)),
                  ]),
                  Slider(
                    value: settings.textScale,
                    min: AppSettingsService.minTextScale,
                    max: AppSettingsService.maxTextScale,
                    divisions: 26,
                    activeColor: AppTheme.primaryColor,
                    inactiveColor: Colors.white24,
                    label: '${(settings.textScale * 100).round()}%',
                    onChanged: settings.setTextScale,
                  ),
                ]),
              ),
              SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),

              // ─── 调节 ───
              GlassCard(
                padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('调节', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 16), fontWeight: FontWeight.bold)),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),

                  _SliderRow(
                    label: '背景模糊',
                    value: settings.wallpaperBlur,
                    min: 0,
                    max: 24,
                    display: settings.wallpaperBlur.toStringAsFixed(0),
                    onChanged: settings.setBlur,
                  ),
                  _SliderRow(
                    label: '压暗程度',
                    value: settings.wallpaperDarken,
                    min: 0,
                    max: 0.7,
                    display: '${(settings.wallpaperDarken * 100).toStringAsFixed(0)}%',
                    onChanged: settings.setDarken,
                    hint: '自定义照片偏亮时调高，保证卡片文字能看清',
                  ),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(BuildContext context, AppSettingsService settings) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      final path = result?.files.single.path;
      if (path == null || path.isEmpty) return;

      final ok = await settings.setImageWallpaper(path);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '壁纸已更新' : '壁纸设置失败，请换一张图片重试'),
        backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('选择图片失败: $e'),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final String? hint;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: ResponsiveUtils.scaleFont(context, 13))),
        Text(display, style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 13), fontWeight: FontWeight.w600)),
      ]),
      Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        activeColor: AppTheme.primaryColor,
        inactiveColor: Colors.white24,
        onChanged: onChanged,
      ),
      if (hint != null)
        Text(hint!, style: TextStyle(color: AppTheme.textHint, fontSize: ResponsiveUtils.scaleFont(context, 11))),
    ]);
  }
}
