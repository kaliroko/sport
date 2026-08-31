/// 数据库管理器
library;

import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static Database? _database;
  static const int _version = 1;
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
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // 每日打卡表
    await db.execute('''
      CREATE TABLE daily_check_ins (
        date TEXT PRIMARY KEY,
        water_morning INTEGER DEFAULT 0,
        face_massage_morning INTEGER DEFAULT 0,
        breakfast_healthy INTEGER DEFAULT 0,
        lunch_controlled INTEGER DEFAULT 0,
        water_2l INTEGER DEFAULT 0,
        no_snacks INTEGER DEFAULT 0,
        dinner_controlled INTEGER DEFAULT 0,
        workout_done INTEGER DEFAULT 0,
        face_massage_night INTEGER DEFAULT 0,
        sleep_before_23 INTEGER DEFAULT 0,
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
    // 运动日志索引
    await db.execute('CREATE INDEX idx_workouts_date ON workout_logs(date)');
    // 身体测量索引
    await db.execute('CREATE INDEX idx_measurements_date ON body_measurements(date)');
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
