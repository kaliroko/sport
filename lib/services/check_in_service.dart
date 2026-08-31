/// 打卡服务
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:metamorphosis_checkin/database/app_database.dart';
import 'package:metamorphosis_checkin/models/daily_check_in.dart';
import 'package:rxdart/rxdart.dart';

class CheckInService with ChangeNotifier {
  DailyCheckIn? _todayCheckIn;
  List<DailyCheckIn> _historicalCheckIns = [];
  final BehaviorSubject<double> _completionRateStream = BehaviorSubject<double>();
  final StreamController<int> _streakStream = StreamController<int>();

  // Getters
  DailyCheckIn? get todayCheckIn => _todayCheckIn;
  List<DailyCheckIn> get historicalCheckIns => _historicalCheckIns;
  Stream<double> get completionRateStream => _completionRateStream.stream;
  Stream<int> get streakStream => _streakStream.stream;

  String get todayDate => DateTime.now().toIso8601String().split('T').first;

  /// 初始化服务
  Future<void> init() async {
    await _loadTodayCheckIn();
    _historicalCheckIns = await getHistoricalCheckIns(days: 90);
    _notifyChange();
  }

  /// 加载今日打卡记录
  Future<void> _loadTodayCheckIn() async {
    final checkIn = await DatabaseManager.checkInRepository.getCheckIn(todayDate);
    if (checkIn != null) {
      _todayCheckIn = checkIn;
    } else {
      // 创建新的打卡记录
      final now = DateTime.now();
      _todayCheckIn = DailyCheckIn(
        date: todayDate,
        createdAt: now,
        updatedAt: now,
      );
    }
    _notifyChange();
  }

  /// 切换任务状态
  Future<void> toggleTask(String taskId, bool value) async {
    if (_todayCheckIn == null) return;

    final updated = _todayCheckIn!.copyWith(
      updatedAt: DateTime.now(),
    );

    switch (taskId) {
      case 'water_morning':
        _todayCheckIn = updated.copyWith(waterMorning: value);
        break;
      case 'face_massage_morning':
        _todayCheckIn = updated.copyWith(faceMassageMorning: value);
        break;
      case 'breakfast_healthy':
        _todayCheckIn = updated.copyWith(breakfastHealthy: value);
        break;
      case 'lunch_controlled':
        _todayCheckIn = updated.copyWith(lunchControlled: value);
        break;
      case 'water_2l':
        _todayCheckIn = updated.copyWith(water2l: value);
        break;
      case 'no_snacks':
        _todayCheckIn = updated.copyWith(noSnacks: value);
        break;
      case 'dinner_controlled':
        _todayCheckIn = updated.copyWith(dinnerControlled: value);
        break;
      case 'workout_done':
        _todayCheckIn = updated.copyWith(workoutDone: value);
        break;
      case 'face_massage_night':
        _todayCheckIn = updated.copyWith(faceMassageNight: value);
        break;
      case 'sleep_before_23':
        _todayCheckIn = updated.copyWith(sleepBefore23: value);
        break;
    }

    await DatabaseManager.checkInRepository.saveCheckIn(_todayCheckIn!);
    _notifyChange();
  }

  /// 一键完成所有任务
  Future<void> completeAllTasks() async {
    if (_todayCheckIn == null) return;

    final now = DateTime.now();
    _todayCheckIn = DailyCheckIn(
      date: todayDate,
      waterMorning: true,
      faceMassageMorning: true,
      breakfastHealthy: true,
      lunchControlled: true,
      water2l: true,
      noSnacks: true,
      dinnerControlled: true,
      workoutDone: true,
      faceMassageNight: true,
      sleepBefore23: true,
      createdAt: _todayCheckIn!.createdAt,
      updatedAt: now,
      note: _todayCheckIn!.note,
    );
    await DatabaseManager.checkInRepository.saveCheckIn(_todayCheckIn!);
    _notifyChange();
  }

  /// 设置备注
  Future<void> setNote(String note) async {
    if (_todayCheckIn == null) return;
    _todayCheckIn = _todayCheckIn!.copyWith(
      note: note,
      updatedAt: DateTime.now(),
    );
    await DatabaseManager.checkInRepository.saveCheckIn(_todayCheckIn!);
  }

  /// 获取完成率
  double get completionRate {
    return _todayCheckIn?.completionRate ?? 0.0;
  }

  /// 更新完成率流
  void _notifyChange() {
    _completionRateStream.add(completionRate);
    notifyListeners();
  }

  /// 获取连续打卡天数
  Future<int> getConsecutiveDays() async {
    return await DatabaseManager.checkInRepository.getConsecutiveDays();
  }

  /// 获取最佳连续记录
  Future<int> getBestStreak() async {
    return await DatabaseManager.checkInRepository.getBestStreak();
  }

  /// 获取历史打卡记录
  Future<List<DailyCheckIn>> getHistoricalCheckIns({int days = 60}) async {
    return await DatabaseManager.checkInRepository.getRecentCheckIns(days);
  }

  /// 关闭服务
  void dispose() {
    _completionRateStream.close();
    _streakStream.close();
  }
}
