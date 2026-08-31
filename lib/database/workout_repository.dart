/// 运动日志数据仓库
library;

import 'package:metamorphosis_checkin/models/workout_log.dart';
import 'package:sqflite/sqflite.dart';

class WorkoutRepository {
  final Database _db;

  WorkoutRepository(this._db);

  /// 获取指定日期的运动日志
  Future<List<WorkoutLog>> getWorkoutLogs(String date) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'workout_logs',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at ASC',
    );
    return List.generate(maps.length, (i) => WorkoutLog.fromMap(maps[i]));
  }

  /// 获取所有运动日志
  Future<List<WorkoutLog>> getAllWorkoutLogs() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'workout_logs',
      orderBy: 'date DESC, created_at DESC',
    );
    return List.generate(maps.length, (i) => WorkoutLog.fromMap(maps[i]));
  }

  /// 获取最近N天的运动日志
  Future<List<WorkoutLog>> getRecentWorkoutLogs(int days) async {
    final DateTime startDate = DateTime.now().subtract(Duration(days: days));
    final String startDateStr = startDate.toIso8601String().split('T').first;
    
    final List<Map<String, dynamic>> maps = await _db.query(
      'workout_logs',
      where: 'date >= ?',
      whereArgs: [startDateStr],
      orderBy: 'date DESC, created_at DESC',
    );
    return List.generate(maps.length, (i) => WorkoutLog.fromMap(maps[i]));
  }

  /// 插入运动日志
  Future<int> insertWorkoutLog(WorkoutLog log) async {
    return await _db.insert(
      'workout_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  /// 更新运动日志
  Future<int> updateWorkoutLog(WorkoutLog log) async {
    return await _db.update(
      'workout_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  /// 删除运动日志
  Future<int> deleteWorkoutLog(int id) async {
    return await _db.delete(
      'workout_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取某动作的总次数
  Future<int> getTotalReps(String exerciseName) async {
    final result = await _db.rawQuery(
      'SELECT SUM(reps) as total FROM workout_logs WHERE exercise_name = ?',
      [exerciseName],
    );
    return result.first['total'] as int? ?? 0;
  }

  /// 获取某动作的最长时长
  Future<int> getLongestDuration(String exerciseName) async {
    final result = await _db.rawQuery(
      'SELECT MAX(duration_seconds) as max_duration FROM workout_logs WHERE exercise_name = ?',
      [exerciseName],
    );
    return result.first['max_duration'] as int? ?? 0;
  }

  /// 获取每周有氧总时长
  Future<List<Map<String, dynamic>>> getWeeklyCardioDuration() async {
    final result = await _db.rawQuery('''
      SELECT 
        strftime('%Y-%W', date) as week,
        SUM(duration_seconds) / 60 as total_minutes
      FROM workout_logs
      WHERE workout_type = 'cardio'
      GROUP BY strftime('%Y-%W', date)
      ORDER BY week DESC
      LIMIT 12
    ''');
    
    return List.generate(result.length, (i) {
      return {
        'week': result[i]['week'],
        'minutes': result[i]['total_minutes'] ?? 0,
      };
    });
  }
}
