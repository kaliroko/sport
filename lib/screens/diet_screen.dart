/// 饮食页
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:metamorphosis_checkin/services/user_profile_service.dart';
import 'package:metamorphosis_checkin/utils/constants.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';

class DietScreen extends StatelessWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProfileService()..init(),
      child: const _DietScreenContent(),
    );
  }
}

class _DietScreenContent extends StatelessWidget {
  const _DietScreenContent();

  @override
  Widget build(BuildContext context) {
    return AdaptiveLiquidGlassLayer(
      settings: const LiquidGlassSettings(),
      quality: GlassQuality.standard,
      blendAmount: 10.0,
      child: CustomScrollView(
        slivers: [
          // 顶部区域
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '饮食指导',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.watch<UserProfileService>().profile?.schoolType == SchoolType.boarder
                          ? '住校生专属建议'
                          : '走读生专属建议',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // 饮食口诀卡片
                    _DietTipCard(),
                    const SizedBox(height: 16),
                    
                    // 三餐建议
                    _MealSuggestionsCard(),
                    const SizedBox(height: 16),
                    
                    // 食物红绿灯
                    _FoodTrafficLightCard(),
                  ],
                ),
              ),
            ),
          ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

class _DietTipCard extends StatelessWidget {
  const _DietTipCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: AppTheme.warningColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '饮食口诀',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '一拳头主食 + 一掌心蛋白质 + 两拳头蔬菜',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '太油的菜用免费汤或开水涮一下再吃\n不喝菜汤，不拌饭',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealSuggestionsCard extends StatelessWidget {
  const _MealSuggestionsCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '三餐建议',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _MealItem(
            time: '早餐',
            icon: '🌅',
            content: '必须包含：1个鸡蛋 + 1杯牛奶/无糖豆浆 + 主食（玉米半根/全麦面包1片）\n禁止：油条、煎饼、手抓饼、含糖饮料',
          ),
          const Divider(color: AppTheme.textHint),
          _MealItem(
            time: '午餐',
            icon: '☀️',
            content: '按口诀打菜：一拳头米饭 + 一掌心瘦肉/鸡蛋/豆腐 + 两拳头蔬菜\n太油的菜用水涮一下',
          ),
          const Divider(color: AppTheme.textHint),
          _MealItem(
            time: '晚餐',
            icon: '🌙',
            content: '参照午餐原则，主食减半或换成玉米/红薯，多吃蔬菜，少油少盐\n七分饱，不吃夜宵',
          ),
          const Divider(color: AppTheme.textHint),
          _MealItem(
            time: '加餐',
            icon: '🍎',
            content: '如果饿，只吃：半根黄瓜 / 1个水煮蛋 / 1小杯无糖酸奶（三选一）\n禁止：辣条、饼干、面包、饮料',
          ),
        ],
      ),
    );
  }
}

class _MealItem extends StatelessWidget {
  final String time;
  final String icon;
  final String content;

  const _MealItem({
    required this.time,
    required this.icon,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodTrafficLightCard extends StatelessWidget {
  const _FoodTrafficLightCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '食物红绿灯',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // 绿灯食物
          _FoodCategory(
            title: '绿灯食物 ✅',
            color: AppTheme.successColor,
            foods: AppConstants.greenLightFoods.map((f) => f.name).toList(),
          ),
          const SizedBox(height: 16),
          
          // 红灯食物
          _FoodCategory(
            title: '红灯食物 ❌',
            color: AppTheme.errorColor,
            foods: AppConstants.redLightFoods.map((f) => f.name).toList(),
          ),
        ],
      ),
    );
  }
}

class _FoodCategory extends StatelessWidget {
  final String title;
  final Color color;
  final List<String> foods;

  const _FoodCategory({
    required this.title,
    required this.color,
    required this.foods,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: foods.map((food) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                food,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}