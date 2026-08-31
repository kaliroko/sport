/// 每日打卡记录模型
library;

import 'dart:convert';

class DailyCheckIn {
  final String date;
  final bool waterMorning;
  final bool faceMassageMorning;
  final bool breakfastHealthy;
  final bool lunchControlled;
  final bool water2l;
  final bool noSnacks;
  final bool dinnerControlled;
  final bool workoutDone;
  final bool faceMassageNight;
  final bool sleepBefore23;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyCheckIn({
    required this.date,
    this.waterMorning = false,
    this.faceMassageMorning = false,
    this.breakfastHealthy = false,
    this.lunchControlled = false,
    this.water2l = false,
    this.noSnacks = false,
    this.dinnerControlled = false,
    this.workoutDone = false,
    this.faceMassageNight = false,
    this.sleepBefore23 = false,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// 计算完成率 (0-100)
  double get completionRate {
    int completed = [
      waterMorning,
      faceMassageMorning,
      breakfastHealthy,
      lunchControlled,
      water2l,
      noSnacks,
      dinnerControlled,
      workoutDone,
      faceMassageNight,
      sleepBefore23,
    ].where((v) => v).length;
    
    return (completed / 10) * 100;
  }

  /// 从Map创建对象
  factory DailyCheckIn.fromMap(Map<String, dynamic> map) {
    return DailyCheckIn(
      date: map['date'] as String,
      waterMorning: (map['water_morning'] as int) == 1,
      faceMassageMorning: (map['face_massage_morning'] as int) == 1,
      breakfastHealthy: (map['breakfast_healthy'] as int) == 1,
      lunchControlled: (map['lunch_controlled'] as int) == 1,
      water2l: (map['water_2l'] as int) == 1,
      noSnacks: (map['no_snacks'] as int) == 1,
      dinnerControlled: (map['dinner_controlled'] as int) == 1,
      workoutDone: (map['workout_done'] as int) == 1,
      faceMassageNight: (map['face_massage_night'] as int) == 1,
      sleepBefore23: (map['sleep_before_23'] as int) == 1,
      note: map['note'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'water_morning': waterMorning ? 1 : 0,
      'face_massage_morning': faceMassageMorning ? 1 : 0,
      'breakfast_healthy': breakfastHealthy ? 1 : 0,
      'lunch_controlled': lunchControlled ? 1 : 0,
      'water_2l': water2l ? 1 : 0,
      'no_snacks': noSnacks ? 1 : 0,
      'dinner_controlled': dinnerControlled ? 1 : 0,
      'workout_done': workoutDone ? 1 : 0,
      'face_massage_night': faceMassageNight ? 1 : 0,
      'sleep_before_23': sleepBefore23 ? 1 : 0,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 复制并更新字段
  DailyCheckIn copyWith({
    bool? waterMorning,
    bool? faceMassageMorning,
    bool? breakfastHealthy,
    bool? lunchControlled,
    bool? water2l,
    bool? noSnacks,
    bool? dinnerControlled,
    bool? workoutDone,
    bool? faceMassageNight,
    bool? sleepBefore23,
    String? note,
    DateTime? updatedAt,
  }) {
    return DailyCheckIn(
      date: date,
      waterMorning: waterMorning ?? this.waterMorning,
      faceMassageMorning: faceMassageMorning ?? this.faceMassageMorning,
      breakfastHealthy: breakfastHealthy ?? this.breakfastHealthy,
      lunchControlled: lunchControlled ?? this.lunchControlled,
      water2l: water2l ?? this.water2l,
      noSnacks: noSnacks ?? this.noSnacks,
      dinnerControlled: dinnerControlled ?? this.dinnerControlled,
      workoutDone: workoutDone ?? this.workoutDone,
      faceMassageNight: faceMassageNight ?? this.faceMassageNight,
      sleepBefore23: sleepBefore23 ?? this.sleepBefore23,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 从JSON字符串创建
  factory DailyCheckIn.fromJson(String source) =>
      DailyCheckIn.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// 转换为JSON字符串
  String toJson() => jsonEncode(toMap());

  @override
  String toString() {
    return 'DailyCheckIn(date: $date, completionRate: $completionRate%)';
  }
}