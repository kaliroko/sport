/// 打卡数据仓库
library;

import 'package:metamorphosis_checkin/database/database.dart';
import 'package:metamorphosis_checkin/models/daily_check_in.dart';

class CheckInRepository {
  final Database _db;

  CheckInRepository(this._db);

  /// 获取指定日期的打卡记录
  Future<DailyCheckIn?> getCheckIn(String date) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'daily_check_ins',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isEmpty) return null;
    return DailyCheckIn.fromMap(maps.first);
  }

  /// 获取所有打卡记录
  Future<List<DailyCheckIn>> getAllCheckIns() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'daily_check_ins',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => DailyCheckIn.fromMap(maps[i]));
  }

  /// 获取最近N天的打卡记录
  Future<List<DailyCheckIn>> getRecentCheckIns(int days) async {
    final DateTime startDate = DateTime.now().subtract(Duration(days: days));
    final String startDateStr = startDate.toIso8601String().split('T').first;
    
    final List<Map<String, dynamic>> maps = await _db.query(
      'daily_check_ins',
      where: 'date >= ?',
      whereArgs: [startDateStr],
      orderBy: 'date ASC',
    );
    return List.generate(maps.length, (i) => DailyCheckIn.fromMap(maps[i]));
  }

  /// 插入或更新打卡记录
  Future<void> saveCheckIn(DailyCheckIn checkIn) async {
    await _db.insert(
      'daily_check_ins',
      checkIn.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取连续打卡天数
  Future<int> getConsecutiveDays() async {
    int consecutiveDays = 0;
    DateTime currentDate = DateTime.now();
    
    while (true) {
      final String dateStr = currentDate.toIso8601String().split('T').first;
      final checkIn = await getCheckIn(dateStr);
      
      if (checkIn == null || checkIn.completionRate < 80) {
        break;
      }
      
      consecutiveDays++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }
    
    return consecutiveDays;
  }

  /// 获取最佳连续记录
  Future<int> getBestStreak() async {
    final allCheckIns = await getAllCheckIns();
    if (allCheckIns.isEmpty) return 0;
    
    int bestStreak = 0;
    int currentStreak = 0;
    
    for (final checkIn in allCheckIns) {
      if (checkIn.completionRate >= 80) {
        currentStreak++;
        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }
    
    return bestStreak;
  }

  /// 获取统计数据
  Future<Map<String, dynamic>> getStatistics() async {
    final allCheckIns = await getAllCheckIns();
    
    if (allCheckIns.isEmpty) {
      return {
        'total_days': 0,
        'completion_rate': 0.0,
        'current_streak': 0,
        'best_streak': 0,
      };
    }
    
    double totalRate = 0;
    for (final checkIn in allCheckIns) {
      totalRate += checkIn.completionRate;
    }
    
    final currentStreak = await getConsecutiveDays();
    final bestStreak = await getBestStreak();
    
    return {
      'total_days': allCheckIns.length,
      'completion_rate': totalRate / allCheckIns.length,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
    };
  }
}
