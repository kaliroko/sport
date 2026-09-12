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

  /// 今日某动作已完成的组数。
  ///
  /// 直接由今日的 workout_logs 派生，而不是放在页面 State 里 ——
  /// 切 Tab 会销毁重建页面，App 重启也会丢内存状态，
  /// 从数据库派生才能保证训练进度不丢。
  int completedSetsFor(String exerciseName) {
    final today = DateTime.now().toIso8601String().split('T').first;
    return _logs
        .where((log) => log.date == today && log.exerciseName == exerciseName)
        .length;
  }

  /// 今日已记录的总组数
  int get todaySetCount {
    final today = DateTime.now().toIso8601String().split('T').first;
    return _logs.where((log) => log.date == today).length;
  }

  /// 今日已完成动作数 / 总动作数（用于训练页进度展示）
  int completedExerciseCount(List<String> exerciseNames) {
    return exerciseNames.where((n) => completedSetsFor(n) > 0).length;
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

  @override
  void dispose() {
    _progressStream.close();
    super.dispose();
  }
}
