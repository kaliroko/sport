/// 应用设置仓库（key-value 持久化）
///
/// 用于保存跨启动需要保留的偏好：壁纸、语音播报开关、
/// 当前训练计划与计划起始日期等。
library;

import 'package:sqflite/sqflite.dart';

class SettingsRepository {
  final Database _db;
  SettingsRepository(this._db);

  Future<String?> getString(String key) async {
    final rows = await _db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setString(String key, String value) async {
    await _db.insert(
      'app_settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> remove(String key) async {
    await _db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
  }

  Future<void> clear() async {
    await _db.delete('app_settings');
  }

  // ─── 类型化读写 ────────────────────────────────────────────────────────────

  Future<int?> getInt(String key) async {
    final value = await getString(key);
    return value == null ? null : int.tryParse(value);
  }

  Future<void> setInt(String key, int value) => setString(key, '$value');

  Future<double?> getDouble(String key) async {
    final value = await getString(key);
    return value == null ? null : double.tryParse(value);
  }

  Future<void> setDouble(String key, double value) => setString(key, '$value');

  Future<bool?> getBool(String key) async {
    final value = await getString(key);
    return value == null ? null : value == 'true';
  }

  Future<void> setBool(String key, bool value) =>
      setString(key, value ? 'true' : 'false');

  Future<DateTime?> getDate(String key) async {
    final value = await getString(key);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> setDate(String key, DateTime value) =>
      setString(key, value.toIso8601String());
}
