/// 训练计划服务
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:metamorphosis_checkin/models/workout_plan.dart';
import 'package:metamorphosis_checkin/utils/constants.dart';

class WorkoutPlanService with ChangeNotifier {
  String _selectedPlanId = 'beginner_fat_loss';
  int _currentDay = 1;

  String get selectedPlanId => _selectedPlanId;
  int get currentDay => _currentDay;

  /// 获取当前计划的今日训练内容
  List<MovementConfig> getTodayMovements() {
    final plan = WorkoutPlans.all.firstWhere(
      (p) => p.id == _selectedPlanId,
      orElse: () => WorkoutPlans.planBeginnerFatLoss,
    );
    final dayIndex = (_currentDay - 1) % plan.durationDays;
    return plan.dailySchedule[dayIndex] ?? WorkoutPlans.planBeginnerFatLoss.dailySchedule[0]!;
  }

  /// 获取今日类型标签
  String getTodayType() {
    final plan = WorkoutPlans.all.firstWhere(
      (p) => p.id == _selectedPlanId,
      orElse: () => WorkoutPlans.planBeginnerFatLoss,
    );
    final dayIndex = (_currentDay - 1) % plan.durationDays;
    final movements = plan.dailySchedule[dayIndex] ?? [];
    // 如果只有拉伸/休息类动作，标注为休息日
    final isStretch = movements.every((m) =>
        m.name.contains('伸展') || m.name.contains('拉伸') || m.name.contains('婴儿'));
    if (isStretch && movements.length <= 2) return '主动恢复';
    if (dayIndex % 7 == 6 && movements.isEmpty) return '休息日';
    return '力量训练';
  }

  /// 切换计划
  void selectPlan(String planId) {
    _selectedPlanId = planId;
    _currentDay = 1;
    notifyListeners();
  }

  /// 进入下一天（每天训练后调用）
  void nextDay() {
    final plan = WorkoutPlans.all.firstWhere(
      (p) => p.id == _selectedPlanId,
      orElse: () => WorkoutPlans.planBeginnerFatLoss,
    );
    if (_currentDay < plan.durationDays) {
      _currentDay++;
      notifyListeners();
    }
  }

  /// 获取所有可用计划
  List<WorkoutPlan> get availablePlans => WorkoutPlans.all;
}
