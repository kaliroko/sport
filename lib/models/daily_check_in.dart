/// 每日打卡记录模型
library;

import 'dart:convert';

import 'package:metamorphosis_checkin/utils/constants.dart';

enum Mood { neutral, happy, sad }

class DailyCheckIn {
  final String date;
  final int waterMl; // 当日总饮水毫升数（按杯累加）
  final bool waterMorning; // 晨起温水（原来是纯 UI 任务，没有存储列）
  final bool faceMassageMorning;
  final bool breakfastHealthy;
  final bool lunchControlled;
  final bool noSnacks;
  final bool dinnerControlled;
  final bool workoutDone;
  final bool faceMassageNight;
  final bool sleepBefore23;
  final Map<String, bool> customTasks; // id -> 是否完成
  final Mood mood;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyCheckIn({
    required this.date,
    this.waterMl = 0,
    this.waterMorning = false,
    this.faceMassageMorning = false,
    this.breakfastHealthy = false,
    this.lunchControlled = false,
    this.noSnacks = false,
    this.dinnerControlled = false,
    this.workoutDone = false,
    this.faceMassageNight = false,
    this.sleepBefore23 = false,
    this.customTasks = const {},
    this.mood = Mood.neutral,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// 计算完成率 (0-100)
  double get completionRate {
    final tasks = _allTasks();
    final completed = tasks.where((v) => v).length;
    return tasks.isEmpty ? 0 : (completed / tasks.length) * 100;
  }

  /// 全部任务列表（固定 10 项 + 自定义任务）
  ///
  /// 必须与 AppConstants.dailyTasks 的 10 项严格一一对应，否则首页显示的
  /// 「今日完成 X / 10」会和环形图百分比对不上：
  ///   water_morning        → waterMorning
  ///   face_massage_morning → faceMassageMorning
  ///   breakfast_healthy    → breakfastHealthy
  ///   lunch_controlled     → lunchControlled
  ///   water_goal           → waterMl >= AppConstants.waterGoalMl
  ///   no_snacks            → noSnacks
  ///   dinner_controlled    → dinnerControlled
  ///   workout_done         → workoutDone
  ///   face_massage_night   → faceMassageNight
  ///   sleep_before_23      → sleepBefore23
  List<bool> _allTasks() {
    return [
      waterMorning,
      faceMassageMorning,
      breakfastHealthy,
      lunchControlled,
      waterMl >= AppConstants.waterGoalMl, // 达标线统一取常量，不再写死
      noSnacks,
      dinnerControlled,
      workoutDone,
      faceMassageNight,
      sleepBefore23,
      ...customTasks.values,
    ];
  }

  /// 自定义任务 ID 列表
  List<String> get customTaskIds => customTasks.keys.toList();

  /// 从Map创建对象
  factory DailyCheckIn.fromMap(Map<String, dynamic> map) {
    final customTasksJson = map['custom_tasks'] as String?;
    final Map<String, bool> customTasks = {};
    if (customTasksJson != null && customTasksJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(customTasksJson) as Map<String, dynamic>;
        customTasks.addAll(
          decoded.map((k, v) => MapEntry(k, v as bool)),
        );
      } catch (_) {}
    }
    return DailyCheckIn(
      date: map['date'] as String,
      waterMl: (map['water_ml'] as int?) ?? 0,
      // 列不存在时返回 null，null == 1 为 false，行为安全
      waterMorning: (map['water_morning'] as int?) == 1,
      faceMassageMorning: (map['face_massage_morning'] as int?) == 1,
      breakfastHealthy: (map['breakfast_healthy'] as int?) == 1,
      lunchControlled: (map['lunch_controlled'] as int?) == 1,
      noSnacks: (map['no_snacks'] as int?) == 1,
      dinnerControlled: (map['dinner_controlled'] as int?) == 1,
      workoutDone: (map['workout_done'] as int?) == 1,
      faceMassageNight: (map['face_massage_night'] as int?) == 1,
      sleepBefore23: (map['sleep_before_23'] as int?) == 1,
      customTasks: customTasks,
      mood: Mood.values[(map['mood'] as int?) ?? 0],
      note: map['note'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'water_ml': waterMl,
      'water_morning': waterMorning ? 1 : 0,
      'face_massage_morning': faceMassageMorning ? 1 : 0,
      'breakfast_healthy': breakfastHealthy ? 1 : 0,
      'lunch_controlled': lunchControlled ? 1 : 0,
      'no_snacks': noSnacks ? 1 : 0,
      'dinner_controlled': dinnerControlled ? 1 : 0,
      'workout_done': workoutDone ? 1 : 0,
      'face_massage_night': faceMassageNight ? 1 : 0,
      'sleep_before_23': sleepBefore23 ? 1 : 0,
      'custom_tasks': customTasks.isEmpty ? '' : jsonEncode(customTasks),
      'mood': mood.index,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 复制并更新字段
  DailyCheckIn copyWith({
    int? waterMl,
    bool? waterMorning,
    bool? faceMassageMorning,
    bool? breakfastHealthy,
    bool? lunchControlled,
    bool? noSnacks,
    bool? dinnerControlled,
    bool? workoutDone,
    bool? faceMassageNight,
    bool? sleepBefore23,
    Map<String, bool>? customTasks,
    Mood? mood,
    String? note,
    DateTime? updatedAt,
  }) {
    return DailyCheckIn(
      date: date,
      waterMl: waterMl ?? this.waterMl,
      waterMorning: waterMorning ?? this.waterMorning,
      faceMassageMorning: faceMassageMorning ?? this.faceMassageMorning,
      breakfastHealthy: breakfastHealthy ?? this.breakfastHealthy,
      lunchControlled: lunchControlled ?? this.lunchControlled,
      noSnacks: noSnacks ?? this.noSnacks,
      dinnerControlled: dinnerControlled ?? this.dinnerControlled,
      workoutDone: workoutDone ?? this.workoutDone,
      faceMassageNight: faceMassageNight ?? this.faceMassageNight,
      sleepBefore23: sleepBefore23 ?? this.sleepBefore23,
      customTasks: customTasks ?? this.customTasks,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// 加水
  DailyCheckIn addWater(int ml) => copyWith(waterMl: waterMl + ml);

  /// 直接设定饮水总量（供「点第几杯」的交互使用）。
  /// 夹在 0 ~ 目标值之间：原先 addWater 没有上限，可以点到几千毫升。
  DailyCheckIn setWater(int ml) => copyWith(
        waterMl: ml.clamp(0, AppConstants.waterGoalMl).toInt(),
      );

  /// 从JSON字符串创建
  factory DailyCheckIn.fromJson(String source) =>
      DailyCheckIn.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// 转换为JSON字符串
  String toJson() => jsonEncode(toMap());

  @override
  String toString() {
    return 'DailyCheckIn(date: $date, water: ${waterMl}ml, rate: ${completionRate.round()}%, mood: $mood)';
  }
}
