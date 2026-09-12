/// 主App入口
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:metamorphosis_checkin/theme/app_theme.dart';
import 'package:metamorphosis_checkin/screens/home_screen.dart';
import 'package:metamorphosis_checkin/screens/workout_screen.dart';
import 'package:metamorphosis_checkin/screens/diet_screen.dart';
import 'package:metamorphosis_checkin/screens/stats_screen.dart';
import 'package:metamorphosis_checkin/screens/profile_screen.dart';
import 'package:metamorphosis_checkin/screens/onboarding_screen.dart';
import 'package:metamorphosis_checkin/services/user_profile_service.dart';
import 'package:metamorphosis_checkin/services/check_in_service.dart';
import 'package:metamorphosis_checkin/services/workout_service.dart';
import 'package:metamorphosis_checkin/services/workout_plan_service.dart';
import 'package:metamorphosis_checkin/services/debug_upload_service.dart';
import 'package:metamorphosis_checkin/database/app_database.dart';

class MetamorphosisApp extends StatelessWidget {
  const MetamorphosisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfileService()..init()),
        ChangeNotifierProvider(create: (_) => CheckInService()..init()),
        ChangeNotifierProvider(create: (_) => WorkoutService()..init()),
        ChangeNotifierProvider(create: (_) => WorkoutPlanService()),
        ChangeNotifierProvider(create: (_) => DebugUploadService()),
      ],
      child: MaterialApp(
        title: '自律',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        // 注册命名路由，避免 onboarding 跳转时崩溃
        routes: {
          '/home': (_) => const MainScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
        },
        home: const _AppInitializer(),
      ),
    );
  }
}

class _AppInitializer extends StatelessWidget {
  const _AppInitializer();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkHasProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              body: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          );
        }
        
        if (snapshot.data == true) {
          return const MainScreen();
        } else {
          return const OnboardingScreen();
        }
      },
    );
  }

  Future<bool> _checkHasProfile() async {
    return await DatabaseManager.profileRepository.hasProfile();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    WorkoutScreen(),
    DietScreen(),
    StatsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景渐变。
        //
        // 这里刻意不使用 LiquidGlassScope.stack：scope 会把这块全屏背景包进一个
        // 带 GlobalKey 的 RepaintBoundary，而底部导航栏的玻璃指示器
        // （AnimatedGlassIndicator → GlassEffect）会在 didChangeDependencies 里
        // 通过 LiquidGlassScope.of(context) 拿到这个 key。于是每次切换 Tab 的
        // 600ms 弹簧动画期间，_handleTick 会以 10fps 对**整屏**调用
        // boundary.toImage(pixelRatio: dpr)（每张都是全分辨率纹理的 GPU 回读，
        // 属于管线停顿），这是切 Tab 掉帧与发热的主要来源之一。
        //
        // 去掉 scope 后 GlassEffect._effectiveKey 恒为 null，捕获循环永不启动
        // —— glass_effect.dart 的判据是
        //   interactionIntensity > 0.01 && _effectiveKey != null。
        // 代价仅是底部指示器失去背景折射采样；它本身已是 blur:0 + 低透明度，
        // 视觉差异可忽略。
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0a0a1a),
                Color(0xFF1a1a2e),
                Color(0xFF16213e),
              ],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: _pages[_selectedIndex],
          bottomNavigationBar: _buildBottomBar(),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GlassBottomBar(
          quality: GlassQuality.standard,
          glassSettings: null,
          tabs: [
            GlassBottomBarTab(
              label: '今日',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              glowColor: AppTheme.primaryColor,
            ),
            GlassBottomBarTab(
              label: '训练',
              icon: Icons.fitness_center_outlined,
              selectedIcon: Icons.fitness_center,
              glowColor: AppTheme.secondaryColor,
            ),
            GlassBottomBarTab(
              label: '饮食',
              icon: Icons.restaurant_outlined,
              selectedIcon: Icons.restaurant,
              glowColor: AppTheme.successColor,
            ),
            GlassBottomBarTab(
              label: '记录',
              icon: Icons.insert_chart_outlined,
              selectedIcon: Icons.insert_chart,
              glowColor: AppTheme.warningColor,
            ),
            GlassBottomBarTab(
              label: '我的',
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              glowColor: AppTheme.badgeGold,
            ),
          ],
          selectedIndex: _selectedIndex,
          onTabSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}
