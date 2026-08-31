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
import 'package:metamorphosis_checkin/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化液态玻璃
  await LiquidGlassWidgets.initialize();
  
  // 初始化数据库
  await DatabaseManager.init();
  
  runApp(const MetamorphosisApp());
}

class MetamorphosisApp extends StatelessWidget {
  const MetamorphosisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfileService()..init()),
      ],
      child: MaterialApp(
        title: '自律',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _AppInitializer(),
      ),
    );
  }
}

class _AppInitializer extends StatelessWidget {
  const _AppInitializer({super.key});

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
    return LiquidGlassScope.stack(
      background: Container(
        decoration: const BoxDecoration(
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
      content: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: _pages[_selectedIndex],
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GlassBottomBar(
          quality: GlassQuality.premium,
          glassSettings: RecommendedGlassSettings.bottomBar,
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
