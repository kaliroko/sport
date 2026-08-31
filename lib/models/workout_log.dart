/// 运动日志模型
library;

import 'dart:convert';

class WorkoutLog {
  final int? id;
  final String date;
  final WorkoutType workoutType;
  final String exerciseName;
  final int sets;
  final int reps;
  final int durationSeconds;
  final Intensity intensity;
  final String note;
  final DateTime createdAt;

  const WorkoutLog({
    this.id,
    required this.date,
    required this.workoutType,
    required this.exerciseName,
    this.sets = 0,
    this.reps = 0,
    this.durationSeconds = 0,
    this.intensity = Intensity.moderate,
    this.note = '',
    required this.createdAt,
  });

  /// 从Map创建对象
  factory WorkoutLog.fromMap(Map<String, dynamic> map) {
    return WorkoutLog(
      id: map['id'] as int?,
      date: map['date'] as String,
      workoutType: _parseWorkoutType(map['workout_type'] as String),
      exerciseName: map['exercise_name'] as String,
      sets: (map['sets'] as int?) ?? 0,
      reps: (map['reps'] as int?) ?? 0,
      durationSeconds: (map['duration_seconds'] as int?) ?? 0,
      intensity: _parseIntensity(map['intensity'] as String?),
      note: map['note'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'workout_type': _workoutTypeToString(workoutType),
      'exercise_name': exerciseName,
      'sets': sets,
      'reps': reps,
      'duration_seconds': durationSeconds,
      'intensity': _intensityToString(intensity),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static WorkoutType _parseWorkoutType(String type) {
    switch (type.toLowerCase()) {
      case 'strength':
        return WorkoutType.strength;
      case 'cardio':
        return WorkoutType.cardio;
      case 'stretch':
        return WorkoutType.stretch;
      case 'rest':
        return WorkoutType.rest;
      default:
        return WorkoutType.strength;
    }
  }

  static String _workoutTypeToString(WorkoutType type) {
    switch (type) {
      case WorkoutType.strength:
        return 'strength';
      case WorkoutType.cardio:
        return 'cardio';
      case WorkoutType.stretch:
        return 'stretch';
      case WorkoutType.rest:
        return 'rest';
    }
  }

  static Intensity _parseIntensity(String? intensity) {
    switch (intensity?.toLowerCase()) {
      case 'easy':
        return Intensity.easy;
      case 'hard':
        return Intensity.hard;
      case 'exhausting':
        return Intensity.exhausting;
      default:
        return Intensity.moderate;
    }
  }

  static String _intensityToString(Intensity intensity) {
    switch (intensity) {
      case Intensity.easy:
        return 'easy';
      case Intensity.hard:
        return 'hard';
      case Intensity.exhausting:
        return 'exhausting';
      default:
        return 'moderate';
    }
  }

  /// 从JSON字符串创建
  factory WorkoutLog.fromJson(String source) =>
      WorkoutLog.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// 转换为JSON字符串
  String toJson() => jsonEncode(toMap());

  /// 获取总次数
  int get totalReps => sets * reps;

  @override
  String toString() {
    return 'WorkoutLog(date: $date, exercise: $exerciseName, $sets×${reps > 0 ? reps : durationSeconds}s)';
  }
}

enum WorkoutType { strength, cardio, stretch, rest }

enum Intensity { easy, moderate, hard, exhausting }