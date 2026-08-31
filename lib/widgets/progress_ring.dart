/// 进度环形图组件
library;

import 'package:flutter/material.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';

class ProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? labelText;
  final TextStyle? labelStyle;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 80.0,
    this.strokeWidth = 8.0,
    this.backgroundColor,
    this.foregroundColor,
    this.labelText,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress / 100,
            strokeWidth: strokeWidth,
            backgroundColor: backgroundColor ?? AppTheme.uncheckedColor,
            valueColor: AlwaysStoppedAnimation(
              foregroundColor ?? AppTheme.primaryColor,
            ),
          ),
          if (labelText != null)
            Text(
              labelText!,
              style: labelStyle ?? const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
