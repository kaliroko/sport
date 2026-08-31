/// 运动服务
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:metamorphosis_checkin/database/app_database.dart';
import 'package:metamorphosis_checkin/models/workout_log.dart';

class WorkoutService with ChangeNotifier {
  List<WorkoutLog> _logs = [];
  final BehaviorSubject<double> _progressStream = BehaviorSubject<double>();

  List<WorkoutLog> get logs => _logs;
  Stream<double> get progressStream => _progressStream.stream;

  /// 初始化服务
  Future<void> init() async {
    await _loadLogs();
  }

  /// 加载运动日志
  Future<void> _loadLogs() async {
    _logs = await DatabaseManager.workoutRepository.getRecentWorkoutLogs(90);
    notifyListeners();
  }

  /// 添加运动日志
  Future<void> addLog(WorkoutLog log) async {
    await DatabaseManager.workoutRepository.insertWorkoutLog(log);
    _logs.insert(0, log);
    notifyListeners();
  }

  /// 获取今日运动日志
  List<WorkoutLog> getTodayLogs() {
    final today = DateTime.now().toIso8601String().split('T').first;
    return _logs.where((log) => log.date == today).toList();
  }

  /// 获取某动作的总次数
  Future<int> getTotalReps(String exerciseName) async {
    return await DatabaseManager.workoutRepository.getTotalReps(exerciseName);
  }

  /// 获取某动作的最长时长
  Future<int> getLongestDuration(String exerciseName) async {
    return await DatabaseManager.workoutRepository.getLongestDuration(exerciseName);
  }

  /// 获取每周有氧总时长
  Future<List<Map<String, dynamic>>> getWeeklyCardioDuration() async {
    return await DatabaseManager.workoutRepository.getWeeklyCardioDuration();
  }

  /// 获取运动统计数据
  Future<Map<String, dynamic>> getStatistics() async {
    final allLogs = await DatabaseManager.workoutRepository.getAllWorkoutLogs();
    
    int totalSets = 0;
    int totalReps = 0;
    int totalDurationSeconds = 0;
    
    for (final log in allLogs) {
      totalSets += log.sets;
      totalReps += log.reps * log.sets;
      totalDurationSeconds += log.durationSeconds;
    }
    
    return {
      'total_workouts': allLogs.length,
      'total_sets': totalSets,
      'total_reps': totalReps,
      'total_duration_minutes': totalDurationSeconds ~/ 60,
    };
  }

  void dispose() {
    _progressStream.close();
  }
}
