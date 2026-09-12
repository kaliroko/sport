/// 内置壁纸预设
///
/// 全部用渐变定义，不需要打包任何图片资源 —— `assets/wallpapers/` 目录
/// 从一开始就只有 `.gitkeep`，用代码定义渐变既省安装包体积，
/// 又能天然适配任意屏幕比例（不会出现拉伸变形）。
library;

import 'package:flutter/material.dart';

class WallpaperPreset {
  final String id;
  final String name;
  final List<Color> colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const WallpaperPreset({
    required this.id,
    required this.name,
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  LinearGradient get gradient => LinearGradient(
        begin: begin,
        end: end,
        colors: colors,
      );
}

class WallpaperPresets {
  WallpaperPresets._();

  /// 默认预设，与原硬编码背景完全一致（升级后观感不变）
  static const String defaultId = 'midnight';

  static const List<WallpaperPreset> all = [
    WallpaperPreset(
      id: 'midnight',
      name: '午夜蓝',
      colors: [Color(0xFF0a0a1a), Color(0xFF1a1a2e), Color(0xFF16213e)],
    ),
    WallpaperPreset(
      id: 'deep_sea',
      name: '深海',
      colors: [Color(0xFF001219), Color(0xFF005f73), Color(0xFF0a9396)],
    ),
    WallpaperPreset(
      id: 'aurora',
      name: '极光',
      colors: [Color(0xFF0d0221), Color(0xFF3a0ca3), Color(0xFF4cc9f0)],
    ),
    WallpaperPreset(
      id: 'sunset',
      name: '日落',
      colors: [Color(0xFF2b1055), Color(0xFF7597de), Color(0xFFef476f)],
    ),
    WallpaperPreset(
      id: 'forest',
      name: '森林',
      colors: [Color(0xFF0b1a12), Color(0xFF14442f), Color(0xFF2d6a4f)],
    ),
    WallpaperPreset(
      id: 'ember',
      name: '余烬',
      colors: [Color(0xFF1a0b0b), Color(0xFF6a1b1b), Color(0xFFe07a5f)],
    ),
    WallpaperPreset(
      id: 'sand',
      name: '沙丘',
      colors: [Color(0xFF1a1614), Color(0xFF3d332b), Color(0xFF8a7a63)],
    ),
    WallpaperPreset(
      id: 'mono',
      name: '纯黑',
      colors: [Color(0xFF000000), Color(0xFF0d0d0d)],
    ),
  ];

  static WallpaperPreset byId(String id) => all.firstWhere(
        (p) => p.id == id,
        orElse: () => all.first,
      );
}
