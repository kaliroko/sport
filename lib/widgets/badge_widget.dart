/// 成就徽章组件
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:metamorphosis_checkin/utils/constants.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';

class BadgeWidget extends StatelessWidget {
  final BadgeConfig badge;
  final bool isUnlocked;

  const BadgeWidget({
    super.key,
    required this.badge,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? AppTheme.badgeGold.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: isUnlocked ? AppTheme.badgeGold : Colors.grey,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                badge.icon,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            style: TextStyle(
              color: isUnlocked ? Colors.white : AppTheme.textHint,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (!isUnlocked)
            const Text(
              '🔒',
              style: TextStyle(fontSize: 10),
            ),
        ],
      ),
    );
  }
}
