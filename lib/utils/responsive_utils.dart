/// 响应式布局工具
///
/// 同时参考屏幕的「宽度」和「高度」动态缩放字号、间距和 padding，
/// 覆盖小屏（320dp/360dp）、矮屏、横屏以及分屏等场景。
///
/// 设计基准：430 x 900 逻辑像素。
/// 缩放系数取「宽比」与「高比」中的较小值，因此任意一个方向偏小都会
/// 触发整体缩小，避免出现溢出。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class ResponsiveUtils {
  ResponsiveUtils._();

  /// 基准参考尺寸（设计稿按此尺寸优化）
  static const double _referenceWidth = 430.0;
  static const double _referenceHeight = 900.0;

  /// 底部悬浮导航栏尺寸（对应 GlassBottomBar 默认 barHeight = 64 与外边距 16）
  static const double bottomBarHeight = 64.0;
  static const double bottomBarMargin = 16.0;

  /// 全局缩放系数：取宽比和高比中的较小者，上限 1.0（大屏不放大），
  /// 下限 [minRatio]（默认 0.7，保证小屏字号仍可读）。
  static double scaleRatio(BuildContext context, {double minRatio = 0.7}) {
    final size = MediaQuery.of(context).size;
    final widthRatio = size.width / _referenceWidth;
    final heightRatio = size.height / _referenceHeight;
    return math.min(widthRatio, heightRatio).clamp(minRatio, 1.0);
  }

  /// 获取当前屏幕宽度（不含 SafeArea 安全边距）
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// 获取当前屏幕高度
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// 按屏幕比例缩放一个普通尺寸（容器宽高、圆角、线宽等，无下限）。
  ///
  /// 内部保证 `clamp` 的 lower <= upper —— `num.clamp` 在
  /// lower > upper 时会抛 ArgumentError，这里从根上避免该类崩溃。
  static double scaleSize(BuildContext context, double baseSize) {
    if (baseSize <= 0) return baseSize;
    return (baseSize * scaleRatio(context)).clamp(0.0, baseSize);
  }

  /// 缩放字号。[baseSize] 为设计稿（430x900）上的基准字号。
  ///
  /// 8.0 是「可读字号」下限；对小于 8.0 的值不设下限，
  /// 否则会出现 `clamp(8.0, 7.0)` 这种 lower > upper 的必崩调用。
  static double scaleFont(BuildContext context, double baseSize) {
    if (baseSize <= 0) return baseSize;
    return _scaledWithFloor(context, baseSize, 8.0);
  }

  /// 缩放 Padding：两侧 padding 随屏幕比例缩小
  static double scalePadding(BuildContext context, double basePadding) {
    if (basePadding <= 0) return basePadding;
    return _scaledWithFloor(context, basePadding, 8.0);
  }

  /// 缩放间距（SizedBox / gap 值）
  static double scaleSpacing(BuildContext context, double baseSpacing) {
    if (baseSpacing <= 0) return baseSpacing;
    return _scaledWithFloor(context, baseSpacing, 4.0);
  }

  /// 内部：按比例缩放并施加下限 [floor]。
  /// 用 `math.min(floor, baseSize)` 取实际下限，确保 lower <= upper。
  static double _scaledWithFloor(
    BuildContext context,
    double baseSize,
    double floor,
  ) {
    final lower = math.min(floor, baseSize);
    return (baseSize * scaleRatio(context)).clamp(lower, baseSize);
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

  /// 缩放按钮高度（保证可点按区域不低于 40dp）
  static double scaleButtonHeight(BuildContext context, double baseHeight) {
    if (baseHeight <= 0) return baseHeight;
    return _scaledWithFloor(context, baseHeight, 40.0);
  }

  /// 缩放图表高度（保证不低于 120dp）
  static double scaleChartHeight(BuildContext context, double baseHeight) {
    if (baseHeight <= 0) return baseHeight;
    return _scaledWithFloor(context, baseHeight, 120.0);
  }

  /// 判断是否为小屏设备（宽度小于 380dp）
  static bool isSmallScreen(BuildContext context) {
    return screenWidth(context) < 380.0;
  }

  /// 缩放底部空白区域
  static double scaleBottomPadding(BuildContext context) {
    return (80.0 * scaleRatio(context)).clamp(48.0, 100.0);
  }

  /// 计算实际需要的底部安全间距，确保内容能滚动到悬浮导航栏之上。
  ///
  /// = 导航栏高度(64) + 外边距(16) + 系统手势/导航栏安全区 + 视觉缓冲
  ///
  /// 注意：导航栏是固定 64dp，不随屏幕缩放，所以这里不能用等比缩放值，
  /// 否则小屏上最后一张卡片会被导航栏挡住。
  static double bottomSafePadding(BuildContext context) {
    final systemInset = MediaQuery.of(context).padding.bottom;
    final buffer = scaleSpacing(context, 16);
    return bottomBarHeight + bottomBarMargin + systemInset + buffer;
  }
}
