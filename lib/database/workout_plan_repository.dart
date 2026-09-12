/// 自定义训练计划仓库
///
/// 复用早已建好却一直没人使用的 `workout_plans` 表。
/// 表里的 `schedule` 列存 JSON，形如：
///   {"0": ["标准俯卧撑", "深蹲"], "1": ["平板支撑"]}
/// 存的是**动作名**而不是完整定义，读取时通过
/// `WorkoutPlans.movementByName` 还原成 MovementConfig ——
/// 这样动作要领、常见错误、周次强度配置都能自动跟随内置定义更新。
library;

import 'dart:convert';

import 'package:metamorphosis_checkin/models/workout_plan.dart';
import 'package:metamorphosis_checkin/utils/constants.dart';
import 'package:sqflite/sqflite.dart';

class WorkoutPlanRepository {
  final Database _db;
  WorkoutPlanRepository(this._db);

  Future<List<WorkoutPlan>> getAll() async {
    final rows = await _db.query('workout_plans', orderBy: 'created_at ASC');
    return rows.map(_fromRow).whereType<WorkoutPlan>().toList();
  }

  Future<void> save(WorkoutPlan plan) async {
    await _db.insert(
      'workout_plans',
      {
        'id': plan.id,
        'name': plan.name,
        'description': plan.description,
        'duration_days': plan.durationDays,
        'difficulty': _difficultyToString(plan.difficulty),
        'schedule': jsonEncode({
          for (final entry in plan.dailySchedule.entries)
            '${entry.key}': entry.value.map((m) => m.name).toList(),
        }),
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    await _db.delete('workout_plans', where: 'id = ?', whereArgs: [id]);
  }

  WorkoutPlan? _fromRow(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    final name = row['name'] as String?;
    if (id == null || name == null) return null;

    final Map<int, List<MovementConfig>> schedule = {};
    final raw = row['schedule'] as String?;
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final library = WorkoutPlans.movementByName;
        decoded.forEach((key, value) {
          final dayIndex = int.tryParse(key);
          if (dayIndex == null || value is! List) return;
          final movements = <MovementConfig>[];
          for (final item in value) {
            final movement = library[item];
            if (movement != null) movements.add(movement);
          }
          if (movements.isNotEmpty) schedule[dayIndex] = movements;
        });
      } catch (_) {
        // 日程 JSON 损坏时退化为空日程：计划仍能显示，只是没有动作，
        // 总好过整个列表加载失败。
      }
    }

    return WorkoutPlan(
      id: id,
      name: name,
      description: row['description'] as String? ?? '',
      durationDays: (row['duration_days'] as int?) ?? 7,
      difficulty: _parseDifficulty(row['difficulty'] as String?),
      dailySchedule: schedule,
    );
  }

  static PlanDifficulty _parseDifficulty(String? value) {
    switch (value) {
      case 'intermediate':
        return PlanDifficulty.intermediate;
      case 'advanced':
        return PlanDifficulty.advanced;
      default:
        return PlanDifficulty.beginner;
    }
  }

  static String _difficultyToString(PlanDifficulty difficulty) {
    switch (difficulty) {
      case PlanDifficulty.beginner:
        return 'beginner';
      case PlanDifficulty.intermediate:
        return 'intermediate';
      case PlanDifficulty.advanced:
        return 'advanced';
    }
  }
}
