/// 打卡数据仓库
library;

import 'package:metamorphosis_checkin/models/daily_check_in.dart';
import 'package:sqflite/sqflite.dart';

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
  ///
  /// 顺带修复：原实现只按数组下标累加，**不校验日期是否连续**，
  /// 于是 1 月 1 日和 1 月 10 日两条记录会被算成「连续 2 天」。
  /// 现在改为比较相邻记录的日期差，跨断档会重新计数。
  Future<int> getBestStreak() async {
    final allCheckIns = await getAllCheckIns(); // date DESC
    if (allCheckIns.isEmpty) return 0;

    int bestStreak = 0;
    int currentStreak = 0;
    DateTime? previousDate;

    for (final checkIn in allCheckIns.reversed) { // 升序
      if (checkIn.completionRate >= 80) {
        final date = DateTime.parse(checkIn.date);
        if (previousDate != null && date.difference(previousDate).inDays == 1) {
          currentStreak++;
        } else {
          currentStreak = 1;
        }
        if (currentStreak > bestStreak) bestStreak = currentStreak;
        previousDate = date;
      } else {
        currentStreak = 0;
        previousDate = null;
      }
    }

    return bestStreak;
  }

  /// 连续「自律守护」天数。
  ///
  /// 今天还没打卡**不算中断** —— 此时从昨天开始往回数。
  /// 否则用户每天早上一打开 App 就看到连续天数归零，体验很差。
  Future<int> getAbstinenceStreak() async {
    DateTime cursor = DateTime.now();
    final todayStr = cursor.toIso8601String().split('T').first;
    final todayRecord = await getCheckIn(todayStr);
    if (todayRecord == null || !todayRecord.abstinence) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    int days = 0;
    while (true) {
      final dateStr = cursor.toIso8601String().split('T').first;
      final checkIn = await getCheckIn(dateStr);
      if (checkIn == null || !checkIn.abstinence) break;
      days++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return days;
  }

  /// 历史最长「自律守护」连续天数（按日期连续性计算）
  Future<int> getBestAbstinenceStreak() async {
    final all = await getAllCheckIns(); // date DESC
    int best = 0;
    int current = 0;
    DateTime? previousDate;

    for (final checkIn in all.reversed) { // 升序
      if (!checkIn.abstinence) {
        current = 0;
        previousDate = null;
        continue;
      }
      final date = DateTime.parse(checkIn.date);
      if (previousDate != null && date.difference(previousDate).inDays == 1) {
        current++;
      } else {
        current = 1;
      }
      if (current > best) best = current;
      previousDate = date;
    }
    return best;
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
