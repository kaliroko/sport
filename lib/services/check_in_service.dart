/// 打卡服务
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:metamorphosis_checkin/database/app_database.dart';
import 'package:metamorphosis_checkin/models/daily_check_in.dart';
import 'package:metamorphosis_checkin/models/custom_task.dart';
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
  Future<void> completeAllTasks() async {
    if (_todayCheckIn == null) return;
    final now = DateTime.now();
    _todayCheckIn = DailyCheckIn(
      date: todayDate,
      waterMl: _todayCheckIn!.waterMl,
      faceMassageMorning: true, breakfastHealthy: true, lunchControlled: true,
      noSnacks: true, dinnerControlled: true, workoutDone: true,
      faceMassageNight: true, sleepBefore23: true,
      customTasks: _todayCheckIn!.customTasks,
      mood: _todayCheckIn!.mood,
      note: _todayCheckIn!.note,
      createdAt: _todayCheckIn!.createdAt,
      updatedAt: now,
    );
    await DatabaseManager.checkInRepository.saveCheckIn(_todayCheckIn!);
    _notifyChange();
  }

  double get completionRate => _todayCheckIn?.completionRate ?? 0.0;

  void _notifyChange() {
    _completionRateStream.add(completionRate);
    notifyListeners();
  }

  /// 公开刷新接口，供外部调用以通知监听者
  void refresh() => notifyListeners();

  Future<int> getConsecutiveDays() async => await DatabaseManager.checkInRepository.getConsecutiveDays();
  Future<int> getBestStreak() async => await DatabaseManager.checkInRepository.getBestStreak();
  Future<List<DailyCheckIn>> getHistoricalCheckIns({int days = 60}) async =>
      await DatabaseManager.checkInRepository.getRecentCheckIns(days);

  /// 获取今日饮水进度百分比（1500ml达标）
  double get waterProgress => (_todayCheckIn?.waterMl ?? 0) / 1500 * 100;

  @override
  void dispose() {
    _completionRateStream.close();
    _streakStream.close();
    super.dispose();
  }
}