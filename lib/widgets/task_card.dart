/// 任务卡片组件
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:metamorphosis_checkin/utils/constants.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';

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
    return GlassCard(
      height: height ?? 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isChecked
                  ? AppTheme.checkedColor.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                task.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  task.name,
                  style: TextStyle(
                    color: isChecked ? AppTheme.checkedColor : AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.description,
                  style: const TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 11,
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
