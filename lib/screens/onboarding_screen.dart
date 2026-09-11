/// 引导页 - 首次启动填写资料
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:metamorphosis_checkin/services/user_profile_service.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';
import 'package:metamorphosis_checkin/models/user_profile.dart';
import 'package:metamorphosis_checkin/utils/responsive_utils.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController(text: '16');
  final _heightController = TextEditingController(text: '170');
  final _weightController = TextEditingController(text: '65');
  SchoolType _schoolType = SchoolType.commute;
  int _currentWeek = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = UserProfile(
      name: _nameController.text,
      age: int.parse(_ageController.text),
      heightCm: double.parse(_heightController.text),
      weightKg: double.parse(_weightController.text),
      schoolType: _schoolType,
      currentWeek: _currentWeek,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await context.read<UserProfileService>().saveProfile(profile);
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLiquidGlassLayer(
      settings: const LiquidGlassSettings(),
      quality: GlassQuality.standard,
      blendAmount: 10.0,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 24)),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: ResponsiveUtils.scaleFont(context, 100),
                      height: ResponsiveUtils.scaleFont(context, 100),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        size: ResponsiveUtils.scaleIcon(context, 50),
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 16)),
                  Center(
                    child: Text(
                      '自律',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.scaleFont(context, 32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '自律养成计划',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: ResponsiveUtils.scaleFont(context, 14),
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 40)),

                  // 姓名
                  Text(
                    '你的名字',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: ResponsiveUtils.scaleFont(context, 14),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
                  GlassCard(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.scalePadding(context, 16),
                      vertical: ResponsiveUtils.scalePadding(context, 12),
                    ),
                    child: TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: '输入你的名字',
                        hintStyle: TextStyle(color: AppTheme.textHint),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 20)),

                  // 年龄和身高
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '年龄',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: ResponsiveUtils.scaleFont(context, 14),
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
                            GlassCard(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.scalePadding(context, 16),
                                vertical: ResponsiveUtils.scalePadding(context, 12),
                              ),
                              child: TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: '16',
                                  hintStyle: TextStyle(color: AppTheme.textHint),
                                  border: InputBorder.none,
                                  suffixText: '岁',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.scaleSpacing(context, 16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '身高',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: ResponsiveUtils.scaleFont(context, 14),
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
                            GlassCard(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.scalePadding(context, 16),
                                vertical: ResponsiveUtils.scalePadding(context, 12),
                              ),
                              child: TextFormField(
                                controller: _heightController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: '170',
                                  hintStyle: TextStyle(color: AppTheme.textHint),
                                  border: InputBorder.none,
                                  suffixText: 'cm',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 20)),

                  // 体重
                  Text(
                    '体重',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: ResponsiveUtils.scaleFont(context, 14),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
                  GlassCard(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.scalePadding(context, 16),
                      vertical: ResponsiveUtils.scalePadding(context, 12),
                    ),
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: '65',
                        hintStyle: TextStyle(color: AppTheme.textHint),
                        border: InputBorder.none,
                        suffixText: 'kg',
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 20)),

                  // 学校类型
                  Text(
                    '学校类型',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: ResponsiveUtils.scaleFont(context, 14),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
                          child: Column(
                            children: [
                              Text('🏠', style: TextStyle(fontSize: ResponsiveUtils.scaleIcon(context, 32))),
                              SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
                              Text(
                                '走读',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: ResponsiveUtils.scaleFont(context, 16),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.scaleSpacing(context, 16)),
                      Expanded(
                        child: GlassCard(
                          padding: EdgeInsets.all(ResponsiveUtils.scalePadding(context, 16)),
                          child: Column(
                            children: [
                              Text('🏫', style: TextStyle(fontSize: ResponsiveUtils.scaleIcon(context, 32))),
                              SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
                              Text(
                                '住校',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: ResponsiveUtils.scaleFont(context, 16),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 20)),

                  // 当前阶段
                  Text(
                    '当前阶段',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: ResponsiveUtils.scaleFont(context, 14),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 8)),
                  Wrap(
                    spacing: ResponsiveUtils.scaleSpacing(context, 8),
                    runSpacing: ResponsiveUtils.scaleSpacing(context, 8),
                    children: List.generate(8, (index) {
                      final week = index + 1;
                      final isSelected = week == _currentWeek;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentWeek = week;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.scalePadding(context, 16),
                            vertical: ResponsiveUtils.scalePadding(context, 8),
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.textHint.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '第${week}周',
                            style: TextStyle(
                              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                              fontSize: ResponsiveUtils.scaleFont(context, 12),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),

                  // 开始按钮
                  GlassButton.custom(
                    onTap: _saveProfile,
                    width: double.infinity,
                    child: Text(
                      '开始自律之旅',
                      style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.scaleFont(context, 16), fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.scaleSpacing(context, 20)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
