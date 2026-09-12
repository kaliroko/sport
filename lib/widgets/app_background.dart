/// 应用背景：内置渐变预设 或 用户自定义图片
///
/// 由 AppSettingsService 驱动，切换壁纸后立即生效。
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:metamorphosis_checkin/services/app_settings_service.dart';
import 'package:provider/provider.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsService>();

    Widget background;
    if (settings.usesImageWallpaper) {
      background = Transform.scale(
        // 稍稍放大再模糊：ImageFiltered 会让边缘出现透明羽化，
        // 放大 15% 可以把羽化区域推出屏幕外。
        scale: 1.15,
        child: Image.file(
          File(settings.wallpaperImagePath!),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          // 图片损坏/被删时退回渐变，不要出现白屏
          errorBuilder: (context, error, stackTrace) => DecoratedBox(
            decoration: BoxDecoration(gradient: settings.preset.gradient),
          ),
        ),
      );
    } else {
      background = DecoratedBox(
        decoration: BoxDecoration(gradient: settings.preset.gradient),
      );
    }

    final double blur = settings.wallpaperBlur;
    if (blur > 0) {
      background = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: background,
      );
    }

    final double darken = settings.wallpaperDarken;
    if (darken > 0) {
      background = Stack(
        fit: StackFit.expand,
        children: [
          background,
          // 压暗一层：自定义照片当背景时，卡片上的白字可能看不清
          ColoredBox(color: Colors.black.withValues(alpha: darken)),
        ],
      );
    }

    // 背景是静态的。用 RepaintBoundary 把「模糊 + 压暗」的结果缓存成一层，
    // 之后滚动页面不会每帧重算整屏模糊 —— 否则这个背景会成为
    // 比之前修掉的逐卡 BackdropFilter 更严重的 GPU 负担。
    return RepaintBoundary(child: background);
  }
}
