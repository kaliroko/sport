/// 打卡服务
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:metamorphosis_checkin/database/app_database.dart';
import 'package:metamorphosis_checkin/models/daily_check_in.dart';
import 'package:metamorphosis_checkin/models/custom_task.dart';
import 'package:metamorphosis_checkin/utils/constants.dart';
import 'package:rxdart/rxdart.dart';

class CheckInService with ChangeNotifier {
  DailyCheckIn? _todayCheckIn;
  List<DailyCheckIn> _historicalCheckIns = [];
  List<CustomTask> _customTasks = [];
  final BehaviorSubject<double> _completionRateStream = BehaviorSubject<double>();
  final StreamController<int> _streakStream = StreamController<int>();

  DailyCheckIn? get todayCheckIn => _todayCheckIn;
  List<DailyCheckIn> get historicalCheckIns => _historicalCheckIns;
  List<CustomTask> get customTasks => _customTasks;
  Stream<double> get completionRateStream => _completionRateStream.stream;
  Stream<int> get streakStream => _streakStream.stream;
  String get todayDate => DateTime.now().toIso8601String().split('T').first;

  /// 初始化服务
  Future<void> init() async {
    await _loadTodayCheckIn();
    _historicalCheckIns = await getHistoricalCheckIns(days: 90);
    _customTasks = await DatabaseManager.customTaskRepository.getAll();
    _notifyChange();
  }

  Future<void> _loadTodayCheckIn() async {
    final checkIn = await DatabaseManager.checkInRepository.getCheckIn(todayDate);
    if (checkIn != null) {
      _todayCheckIn = checkIn;
    } else {
      final now = DateTime.now();
      _todayCheckIn = DailyCheckIn(date: todayDate, createdAt: now, updatedAt: now);
    }
    _notifyChange();
  }

  /// 切换固定任务状态
  Future<void> toggleTask(String taskId, bool value) async {
    if (_todayCheckIn == null) return;
    final updated = _todayCheckIn!.copyWith(updatedAt: DateTime.now());
    switch (taskId) {
      // 原实现缺少这两个 case：switch 不匹配时静默什么都不做，
      // 所以首页「晨起温水」「喝够水」两张卡点了没反应。
      case 'water_morning':
        _todayCheckIn = updated.copyWith(waterMorning: value); break;
      case 'water_goal':
        // 「喝够水」没有独立字段，由 waterMl 派生：
        // 勾选即补满目标水量，取消即清零。
        _todayCheckIn = updated.copyWith(
          waterMl: value ? AppConstants.waterGoalMl : 0,
        );
        break;
      case 'face_massage_morning':
        _todayCheckIn = updated.copyWith(faceMassageMorning: value); break;
      case 'breakfast_healthy':
        _todayCheckIn = updated.copyWith(breakfastHealthy: value); break;
      case 'lunch_controlled':
        _todayCheckIn = updated.copyWith(lunchControlled: value); break;
      case 'no_snacks':
        _todayCheckIn = updated.copyWith(noSnacks: value); break;
      case 'dinner_controlled':
        _todayCheckIn = updated.copyWith(dinnerControlled: value); break;
      case 'workout_done':
        _todayCheckIn = updated.copyWith(workoutDone: value); break;
      case 'face_massage_night':
        _todayCheckIn = updated.copyWith(faceMassageNight: value); break;
      case 'sleep_before_23':
        _todayCheckIn = updated.copyWith(sleepBefore23: value); break;
    }
    await DatabaseManager.checkInRepository.saveCheckIn(_todayCheckIn!);
    _notifyChange();
  }

  /// 加水（每次 +ml 毫升，默认 250ml）
  Future<void> addWater(int ml) async {
    if (_todayCheckIn == null) return;
    _todayCheckIn = _todayCheckIn!.addWater(ml);
    await DatabaseManager.checkInRepository.saveCheckIn(_todayCheckIn!);
    _notifyChange();
  }

  /// 设定今日饮水总量（供首页「点第几杯」交互使用）
  Future<void> setWater(int ml) async {
    if (_todayCheckIn == null) return;
    _todayCheckIn = _todayCheckIn!.setWater(ml);
    await DatabaseManager.checkInRepository.saveCheckIn(_todayCheckIn!);
    _notifyChange();
  }

  /// 切换自定义任务
  Future<void> toggleCustomTask(String taskId, bool value) async {
    if (_todayCheckIn == null) return;
    final updatedTasks = Map<String, bool>.from(_todayCheckIn!.customTasks);
    updatedTasks[taskId] = value;
    _todayCheckIn = _todayCheckIn!.copyWith(customTasks: updatedTasks);
    await DatabaseManager.checkInRepository.saveCheckIn(_todayCheckIn!);
    _notifyChange();
  }

  /// 设置心情
  Future<void> setMood(Mood mood) async {
    if (_todayCheckIn == null) return;
    _todayCheckIn = _todayCheckIn!.copyWith(mood: mood);
    await DatabaseManager.checkInRepository.saveCheckIn(_todayCheckIn!);
    _notifyChange();
  }

  /// 一键完成所有固定任务
  ///
  /// 必须同时补上 waterMorning 与水量，否则 10 项里只有 8 项为真：
  /// 完成率停在 80%，按钮不消失、"全部达成"文案不出现，
  /// 用户会以为「一键完成」没生效。
  Future<void> completeAllTasks() async {
    if (_todayCheckIn == null) return;
    final now = DateTime.now();
    final current = _todayCheckIn!;
    _todayCheckIn = DailyCheckIn(
      date: todayDate,
      // 取较大值，避免把用户已经记录的饮水量改小
      waterMl: current.waterMl >= AppConstants.waterGoalMl
          ? current.waterMl
          : AppConstants.waterGoalMl,
      waterMorning: true,
      faceMassageMorning: true, breakfastHealthy: true, lunchControlled: true,
      noSnacks: true, dinnerControlled: true, workoutDone: true,
      faceMassageNight: true, sleepBefore23: true,
      customTasks: current.customTasks,
      mood: current.mood,
      note: current.note,
      createdAt: current.createdAt,
      updatedAt: now,
    );
    await DatabaseManager.checkInRepository.saveCheckIn(_todayCheckIn!);
    _notifyChange();
  }

  /// 标记今日训练完成（训练页做完所有动作后调用）
  Future<void> markWorkoutDone(bool value) => toggleTask('workout_done', value);

  double get completionRate => _todayCheckIn?.completionRate ?? 0.0;

  void _notifyChange() {
    _completionRateStream.add(completionRate);
    notifyListeners();
  }

  /// 重新从数据库加载自定义习惯，并通知监听者。
  ///
  /// 原实现只调 notifyListeners()、不重新查询，导致新增/删除自定义习惯后
  /// 首页列表不更新——必须重启 App 才看得到变化。
  Future<void> refresh() async {
    _customTasks = await DatabaseManager.customTaskRepository.getAll();
    notifyListeners();
  }

  Future<int> getConsecutiveDays() async => await DatabaseManager.checkInRepository.getConsecutiveDays();
  Future<int> getBestStreak() async => await DatabaseManager.checkInRepository.getBestStreak();
  Future<List<DailyCheckIn>> getHistoricalCheckIns({int days = 60}) async =>
      await DatabaseManager.checkInRepository.getRecentCheckIns(days);

  /// 获取今日饮水进度百分比（达标线取 AppConstants.waterGoalMl）
  double get waterProgress =>
      (_todayCheckIn?.waterMl ?? 0) / AppConstants.waterGoalMl * 100;

  @override
  void dispose() {
    _completionRateStream.close();
    _streakStream.close();
    super.dispose();
  }
}