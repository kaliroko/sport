/// 任务卡片组件
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:metamorphosis_checkin/utils/constants.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';
import 'package:metamorphosis_checkin/utils/responsive_utils.dart';

class TaskCard extends StatelessWidget {
  final TaskConfig task;
  final bool isChecked;
  final VoidCallback onToggle;
  final double? height;

  const TaskCard({
    super.key,
    required this.task,
    required this.isChecked,
    required this.onToggle,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // 不写死高度：Checkbox 的最小尺寸是 48dp（还要乘 1.2 的缩放），
    // 固定高度在小屏或系统大字体下会把控件挤出卡片。留空即由内容撑开。
    return GlassCard(
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.scalePadding(context, 16),
        vertical: ResponsiveUtils.scalePadding(context, 14),
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveUtils.scaleSize(context, 40),
            height: ResponsiveUtils.scaleSize(context, 40),
            decoration: BoxDecoration(
              color: isChecked
                  ? AppTheme.checkedColor.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                task.icon,
                style: TextStyle(fontSize: ResponsiveUtils.scaleIcon(context, 20)),
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.scaleSpacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  task.name,
                  style: TextStyle(
                    color: isChecked ? AppTheme.checkedColor : AppTheme.textPrimary,
                    fontSize: ResponsiveUtils.scaleFont(context, 14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.description,
                  style: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: ResponsiveUtils.scaleFont(context, 11),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: isChecked,
              onChanged: (value) => onToggle(),
              activeColor: AppTheme.checkedColor,
              checkColor: Colors.white,
              side: const BorderSide(color: AppTheme.textHint),
            ),
          ),
        ],
      ),
    );
  }
}
