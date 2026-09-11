/// 响应式布局工具
/// 根据屏幕宽度动态缩放字号、间距和 padding，适配小屏设备（如 375dp、410dp）
library;

import 'package:flutter/material.dart';

class ResponsiveUtils {
  ResponsiveUtils._();

  /// 基准参考宽度（设计稿按此宽度优化）
  static const double _referenceWidth = 430.0;

  /// 获取当前屏幕宽度（不含 SafeArea 安全边距）
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// 获取当前屏幕高度
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// 缩放字体大小：屏幕越窄字号越小，最小不低于 0.8 倍
  /// [baseSize] 为设计师设定的基准字号（对应 ~430dp 宽屏幕）
  static double scaleFont(BuildContext context, double baseSize) {
    final width = screenWidth(context);
    final clampedRatio = (width / _referenceWidth).clamp(0.75, 1.0);
    return (baseSize * clampedRatio).clamp(8.0, baseSize);
  }

  /// 缩放 Padding：两侧 padding 随屏幕宽度等比缩小
  /// [basePadding] 为基准 padding 值（对应 ~430dp 宽屏幕）
  static double scalePadding(BuildContext context, double basePadding) {
    final clampedRatio = (screenWidth(context) / _referenceWidth).clamp(0.6, 1.0);
    return (basePadding * clampedRatio).clamp(8.0, basePadding);
  }

  /// 缩放间距（SizedBox / gap 值）
  static double scaleSpacing(BuildContext context, double baseSpacing) {
    final clampedRatio = (screenWidth(context) / _referenceWidth).clamp(0.65, 1.0);
    return (baseSpacing * clampedRatio).clamp(4.0, baseSpacing);
  }

  /// 缩放内边距（卡片/组件 padding）
  static EdgeInsets scaleEdgeInsets(BuildContext context, double baseValue) {
    final scaled = scalePadding(context, baseValue);
    return EdgeInsets.all(scaled);
  }

  /// 缩放水平内边距
  static EdgeInsets scaleHorizontalEdgeInsets(BuildContext context, double baseValue) {
    final scaled = scalePadding(context, baseValue);
    return EdgeInsets.symmetric(horizontal: scaled);
  }

  /// 缩放垂直内边距
  static EdgeInsets scaleVerticalEdgeInsets(BuildContext context, double baseValue) {
    final scaled = scalePadding(context, baseValue);
    return EdgeInsets.symmetric(vertical: scaled);
  }

  /// 缩放图标尺寸
  static double scaleIcon(BuildContext context, double baseSize) {
    return scaleFont(context, baseSize);
  }

  /// 缩放按钮高度
  static double scaleButtonHeight(BuildContext context, double baseHeight) {
    final clampedRatio = (screenWidth(context) / _referenceWidth).clamp(0.8, 1.0);
    return (baseHeight * clampedRatio).clamp(40.0, baseHeight);
  }

  /// 缩放图表高度
  static double scaleChartHeight(BuildContext context, double baseHeight) {
    final clampedRatio = (screenWidth(context) / _referenceWidth).clamp(0.6, 1.0);
    return (baseHeight * clampedRatio).clamp(120.0, baseHeight);
  }

  /// 判断是否为小屏设备（宽度小于 380dp）
  static bool isSmallScreen(BuildContext context) {
    return screenWidth(context) < 380.0;
  }

  /// 缩放底部空白区域：基于屏幕宽度按比例缩放，适合 Content ScrollView 底部留白
  static double scaleBottomPadding(BuildContext context) {
    final clampedRatio = (screenWidth(context) / _referenceWidth).clamp(0.7, 1.0);
    return (80.0 * clampedRatio).clamp(48.0, 100.0);
  }

  /// 计算实际需要的底部安全间距，防止内容被底部导航栏或手势导航区遮挡
  /// 取值：系统底部安全区 inset + 16dp 缓冲，或直接使用 scaleBottomPadding，取较大值
  static double bottomSafePadding(BuildContext context) {
    final systemInset = MediaQuery.of(context).padding.bottom;
    final scaled = scaleBottomPadding(context);
    // 系统手势导航区通常 0~48dp，加上 glass bottom bar 高度和 margin（约 80dp）
    return (scaled + systemInset).clamp(48.0, 140.0);
  }
}