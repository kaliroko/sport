/// 日历热力图组件
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';

class CompletionHeatmap extends StatelessWidget {
  final Map<String, double> completionData;
  final int weeks;

  const CompletionHeatmap({
    super.key,
    required this.completionData,
    this.weeks = 9,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: weeks * 7));
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '完成率热力图',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildWeekLabels(),
          const SizedBox(height: 8),
          _buildHeatmapGrid(startDate),
        ],
      ),
    );
  }

  Widget _buildWeekLabels() {
    return Row(
      children: List.generate(7, (index) {
        final days = ['一', '二', '三', '四', '五', '六', '日'];
        return Expanded(
          child: Center(
            child: Text(
              days[index],
              style: const TextStyle(color: AppTheme.textHint, fontSize: 10),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeatmapGrid(DateTime startDate) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: weeks * 7,
      itemBuilder: (context, index) {
        final date = startDate.add(Duration(days: index));
        final dateStr = date.toIso8601String().split('T').first;
        final completion = completionData[dateStr] ?? 0.0;
        
        final isToday = dateStr == DateTime.now().toIso8601String().split('T').first;
        
        return Container(
          decoration: BoxDecoration(
            color: _getCompletionColor(completion),
            borderRadius: BorderRadius.circular(4),
            border: isToday ? Border.all(color: AppTheme.primaryColor, width: 2) : null,
          ),
        );
      },
    );
  }

  Color _getCompletionColor(double completion) {
    if (completion == 0) return Colors.grey.withValues(alpha: 0.2);
    if (completion < 30) return const Color(0xFF81C784).withValues(alpha: 0.3);
    if (completion < 60) return const Color(0xFF81C784).withValues(alpha: 0.5);
    if (completion < 80) return const Color(0xFF81C784).withValues(alpha: 0.7);
    return const Color(0xFF81C784);
  }
}
