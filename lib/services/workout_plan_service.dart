/// 训练计划服务
///
/// 承担三件事：
///  1. 持久化「当前计划」与「计划起始日期」（存 app_settings 表）
///  2. 由起始日期推导当前是第几天（原来是内存计数器，且推进它的
///     nextDay() 从未被调用，导致永远停在第 1 天）
///  3. 合并内置计划与用户自建计划
library;

import 'package:flutter/material.dart';
import 'package:metamorphosis_checkin/database/app_database.dart';
import 'package:metamorphosis_checkin/models/workout_plan.dart';
import 'package:metamorphosis_checkin/utils/constants.dart';

class WorkoutPlanService with ChangeNotifier {
  static const String _kPlanId = 'plan_id';
  static const String _kPlanStart = 'plan_start_date';
  static const String defaultPlanId = 'beginner_fat_loss';

  String _selectedPlanId = defaultPlanId;
  DateTime? _startDate;
  List<WorkoutPlan> _customPlans = const [];
  bool _loaded = false;

  String get selectedPlanId => _selectedPlanId;
  bool get isLoaded => _loaded;

  /// 全部可选计划 = 内置计划 + 用户自建计划
  List<WorkoutPlan> get availablePlans => <WorkoutPlan>[
        ...WorkoutPlans.all,
        ..._customPlans,
      ];

  List<WorkoutPlan> get customPlans => List.unmodifiable(_customPlans);

  WorkoutPlan get selectedPlan => availablePlans.firstWhere(
        (p) => p.id == _selectedPlanId,
        orElse: () => WorkoutPlans.planBeginnerFatLoss,
      );

  int get _durationDays {
    final total = selectedPlan.durationDays;
    return total <= 0 ? 1 : total;
  }

  /// 当前进行到第几天（1 基）。
  ///
  /// 由计划起始日期推导，因此切 Tab、重启 App 都不会丢；
  /// 且会随日历自然推进 —— 这正是「30天计划」应有的语义。
  int get currentDay {
    final start = _startDate;
    if (start == null) return 1;
    final today = DateTime.now();
    final days = DateTime(today.year, today.month, today.day)
        .difference(DateTime(start.year, start.month, start.day))
        .inDays;
    final day = days + 1;
    if (day < 1) return 1;
    return day > _durationDays ? _durationDays : day;
  }

  /// 当前天数在计划日程表里的下标（0 基）
  int get currentDayIndex => (currentDay - 1) % _durationDays;

  /// 初始化：读取持久化的计划与起始日期，并载入自定义计划
  Future<void> init() async {
    final settings = DatabaseManager.settingsRepository;
    _selectedPlanId = await settings.getString(_kPlanId) ?? defaultPlanId;
    _startDate = await settings.getDate(_kPlanStart);
    // 首次使用（或旧版本升级上来）时补一个起始日期，
    // 否则 currentDay 会一直是 1。
    if (_startDate == null) {
      _startDate = DateTime.now();
      await settings.setDate(_kPlanStart, _startDate!);
    }
    await reloadCustomPlans();
    _loaded = true;
    notifyListeners();
  }

  /// 重新从数据库载入自定义计划
  Future<void> reloadCustomPlans() async {
    _customPlans = await DatabaseManager.workoutPlanRepository.getAll();
  }

  /// 获取当前计划的今日训练内容
  List<MovementConfig> getTodayMovements() {
    // 关键修复：原实现是
    //   plan.dailySchedule[dayIndex] ?? planBeginnerFatLoss.dailySchedule[0]!
    // 一旦下标越界就静默串到**另一个计划**的动作。现在由
    // WorkoutPlan.movementsForDay 在计划内部取模，不再跨计划回退。
    return selectedPlan.movementsForDay(currentDayIndex);
  }

  bool _isStretchDay(List<MovementConfig> movements) {
    return movements.isNotEmpty &&
        movements.every((m) =>
            m.name.contains('伸展') ||
            m.name.contains('拉伸') ||
            m.name.contains('婴儿'));
  }

  /// 今日类型标签（展示用）
  String getTodayType() {
    final movements = getTodayMovements();
    if (movements.isEmpty) return '休息日';
    if (_isStretchDay(movements) && movements.length <= 2) return '主动恢复';
    return '力量训练';
  }

  /// 今日训练类型（写入 workout_logs.workout_type）
  ///
  /// 必须是枚举本身，序列化后得到 'strength' / 'cardio' / 'stretch' / 'rest'，
  /// 这样 WorkoutRepository.getWeeklyCardioDuration() 里
  /// `WHERE workout_type = 'cardio'` 才匹配得上。
  WorkoutType getTodayWorkoutType() {
    final movements = getTodayMovements();
    if (movements.isEmpty) return WorkoutType.rest;
    if (_isStretchDay(movements)) return WorkoutType.stretch;

    // 含「心肺」目标肌群的（登山跑/开合跳/高抬腿等）算有氧，
    // 否则「记录」页的每周有氧时长柱状图永远没有数据。
    final isCardio = movements.any((m) => m.targetMuscle.contains('心肺'));
    return isCardio ? WorkoutType.cardio : WorkoutType.strength;
  }

  /// 切换计划，并把起始日期重置为今天
  Future<void> selectPlan(String planId) async {
    _selectedPlanId = planId;
    _startDate = DateTime.now();
    final settings = DatabaseManager.settingsRepository;
    await settings.setString(_kPlanId, planId);
    await settings.setDate(_kPlanStart, _startDate!);
    notifyListeners();
  }

  /// 手动跳到第 [day] 天（等价于把起始日期往前推）
  Future<void> jumpToDay(int day) async {
    final total = _durationDays;
    final int clamped = day < 1 ? 1 : (day > total ? total : day);
    _startDate = DateTime.now().subtract(Duration(days: clamped - 1));
    await DatabaseManager.settingsRepository.setDate(_kPlanStart, _startDate!);
    notifyListeners();
  }

  /// 重新开始当前计划
  Future<void> restartPlan() => jumpToDay(1);

  /// 保存/更新自定义计划
  Future<void> saveCustomPlan(WorkoutPlan plan) async {
    await DatabaseManager.workoutPlanRepository.save(plan);
    await reloadCustomPlans();
    notifyListeners();
  }

  /// 删除自定义计划；若删的正是当前计划，则回退到内置默认计划
  Future<void> deleteCustomPlan(String planId) async {
    await DatabaseManager.workoutPlanRepository.delete(planId);
    await reloadCustomPlans();
    if (_selectedPlanId == planId) {
      await selectPlan(defaultPlanId);
    } else {
      notifyListeners();
    }
  }
}
