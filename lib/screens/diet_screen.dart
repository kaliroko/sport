/// 饮食页
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:metamorphosis_checkin/services/user_profile_service.dart';
import 'package:metamorphosis_checkin/utils/constants.dart';
import 'package:metamorphosis_checkin/models/user_profile.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';
import 'package:metamorphosis_checkin/utils/responsive_utils.dart';

class DietScreen extends StatelessWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DietScreenContent();
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
                padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '饮食指导',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.scaleFont(context, 28),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
                    Text(
                      context.watch<UserProfileService>().profile?.schoolType == SchoolType.boarder
                          ? '住校生专属建议'
                          : '走读生专属建议',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: ResponsiveUtils.scaleFont(context, 14),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.scaleSpacing(context, 20)),

                    // 饮食口诀卡片
                    _DietTipCard(),
                    SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),

                    // 三餐建议
                    _MealSuggestionsCard(),
                    SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),

                    // 食物红绿灯
                    _FoodTrafficLightCard(),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(height: ResponsiveUtils.bottomSafePadding(context)),
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
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 10)),
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
              SizedBox(width: ResponsiveUtils.scaleSpacing(context, 12)),
              Text(
                '饮食口诀',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveUtils.scaleFont(context, 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
          Text(
            '一拳头主食 + 一掌心蛋白质 + 两拳头蔬菜',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: ResponsiveUtils.scaleFont(context, 16),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: ResponsiveUtils.scaleSpacing(context, 12)),
          Text(
            '太油的菜用免费汤或开水涮一下再吃\n不喝菜汤，不拌饭',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: ResponsiveUtils.scaleFont(context, 14),
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
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '三餐建议',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveUtils.scaleFont(context, 16),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
          _MealItem(
            time: '早餐',
            icon: '🌅',
            content: '必须包含：1个鸡蛋 + 1杯牛奶/无糖豆浆 + 主食（玉米半根/全麦面包1片）\n禁止：油条、煎饼、手抓饼、含糖饮料',
          ),
          Divider(color: AppTheme.textHint),
          _MealItem(
            time: '午餐',
            icon: '☀️',
            content: '按口诀打菜：一拳头米饭 + 一掌心瘦肉/鸡蛋/豆腐 + 两拳头蔬菜\n太油的菜用水涮一下',
          ),
          Divider(color: AppTheme.textHint),
          _MealItem(
            time: '晚餐',
            icon: '🌙',
            content: '参照午餐原则，主食减半或换成玉米/红薯，多吃蔬菜，少油少盐\n七分饱，不吃夜宵',
          ),
          Divider(color: AppTheme.textHint),
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
      padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.scaleSpacing(context, 8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: TextStyle(fontSize: ResponsiveUtils.scaleIcon(context, 20))),
          SizedBox(width: ResponsiveUtils.scaleSpacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: ResponsiveUtils.scaleFont(context, 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: ResponsiveUtils.scaleFont(context, 12),
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
      padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '食物红绿灯',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveUtils.scaleFont(context, 16),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),

          // 绿灯食物
          _FoodCategory(
            title: '绿灯食物 ✅',
            color: AppTheme.successColor,
            foods: AppConstants.greenLightFoods.map((f) => f.name).toList(),
          ),
          SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),

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
            fontSize: ResponsiveUtils.scaleFont(context, 14),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
        Wrap(
          spacing: ResponsiveUtils.scaleSpacing(context, 8),
          runSpacing: 8,
          children: foods.map((food) {
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.scalePadding(context, 12),
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
                  fontSize: ResponsiveUtils.scaleFont(context, 12),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}