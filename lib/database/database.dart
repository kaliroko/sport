/// 数据库管理器
library;

import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static Database? _database;
  static const int _version = 5;
  static const String _dbName = 'metamorphosis.db';

  DatabaseHelper._();

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final path = join(documentsDir.path, _dbName);
    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // 每日打卡表
    await db.execute('''
      CREATE TABLE daily_check_ins (
        date TEXT PRIMARY KEY,
        water_ml INTEGER DEFAULT 0,
        water_morning INTEGER DEFAULT 0,
        face_massage_morning INTEGER DEFAULT 0,
        breakfast_healthy INTEGER DEFAULT 0,
        lunch_controlled INTEGER DEFAULT 0,
        no_snacks INTEGER DEFAULT 0,
        dinner_controlled INTEGER DEFAULT 0,
        workout_done INTEGER DEFAULT 0,
        face_massage_night INTEGER DEFAULT 0,
        sleep_before_23 INTEGER DEFAULT 0,
        custom_tasks TEXT DEFAULT '',
        mood INTEGER DEFAULT 0,
        note TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 运动日志表
    await db.execute('''
      CREATE TABLE workout_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        workout_type TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        sets INTEGER DEFAULT 0,
        reps INTEGER DEFAULT 0,
        duration_seconds INTEGER DEFAULT 0,
        intensity TEXT DEFAULT '',
        note TEXT DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    // 身体测量表
    await db.execute('''
      CREATE TABLE body_measurements (
        date TEXT PRIMARY KEY,
        weight_kg REAL,
        waist_cm REAL,
        chest_cm REAL,
        arm_cm REAL,
        photo_front TEXT DEFAULT '',
        photo_side TEXT DEFAULT '',
        feeling_score INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    // 用户资料表
    await db.execute('''
      CREATE TABLE user_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT DEFAULT '',
        age INTEGER DEFAULT 16,
        height_cm REAL DEFAULT 170.0,
        weight_kg REAL DEFAULT 65.0,
        school_type TEXT DEFAULT 'commute',
        current_week INTEGER DEFAULT 1,
        schedule TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 成就记录表
    await db.execute('''
      CREATE TABLE achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER DEFAULT 1,
        badge_id TEXT NOT NULL,
        unlocked_at TEXT NOT NULL,
        UNIQUE(badge_id, user_id)
      )
    ''');

    // 打卡索引
    await db.execute('CREATE INDEX idx_checkins_date ON daily_check_ins(date)');
    // 自定义习惯表
    await db.execute('''
      CREATE TABLE custom_tasks (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT DEFAULT '⭐',
        category TEXT DEFAULT 'other',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    // 训练计划表
    await db.execute('''
      CREATE TABLE workout_plans (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        duration_days INTEGER DEFAULT 7,
        difficulty TEXT DEFAULT 'beginner',
        schedule TEXT DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
    // 运动日志索引
    await db.execute('CREATE INDEX idx_workouts_date ON workout_logs(date)');
    // 身体测量索引
    await db.execute('CREATE INDEX idx_measurements_date ON body_measurements(date)');
    // 应用设置表（key-value）
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// 安全加列：先查 PRAGMA table_info，列已存在则跳过。
  ///
  /// 历史迁移链存在不一致（v1 建表语句与 v2 的 ALTER 有重叠），
  /// 直接 ALTER 可能抛 "duplicate column name" 导致启动崩溃，
  /// 因此统一走这个幂等入口。
  static Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final bool exists = info.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 逐版本递进迁移。
    //
    // 原实现是 `if (oldVersion < 2) { /* 空块 */ }` 加 `if (oldVersion == 2)`，
    // 用等值判断导致 v2 之前的用户永远拿不到后续迁移。这里统一改成
    // `<` 递进，并且所有加列都走 _addColumnIfMissing，重复执行也安全。
    if (oldVersion < 3) {
      // v1/v2 → v3: mood + water_ml + custom_tasks + workout_plans
      await _addColumnIfMissing(db, 'daily_check_ins', 'mood', 'INTEGER DEFAULT 0');
      await _addColumnIfMissing(db, 'daily_check_ins', 'water_ml', 'INTEGER DEFAULT 0');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_tasks (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon TEXT DEFAULT '⭐',
          category TEXT DEFAULT 'other',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS workout_plans (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT DEFAULT '',
          duration_days INTEGER DEFAULT 7,
          difficulty TEXT DEFAULT 'beginner',
          schedule TEXT DEFAULT '',
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      // v3 → v4: 「晨起温水」此前只有 AppConstants 里的任务定义，却没有对应的
      // 存储列 —— 首页 _isTaskChecked 找不到 case 而恒返回 false，
      // 导致该任务卡永远无法勾选，也连带让「勾完所有任务」的庆祝判定失效。
      await _addColumnIfMissing(db, 'daily_check_ins', 'water_morning', 'INTEGER DEFAULT 0');
    }
    if (oldVersion < 5) {
      // v4 → v5: 新增 app_settings 表，用于保存壁纸、语音播报开关、
      // 当前训练计划与计划起始日期等跨启动需要保留的偏好。
      // 此前这些状态要么根本不存在（计划天数恒为 1 天），要么只活在内存里。
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    }
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
