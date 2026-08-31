/// 身体测量数据仓库
library;

import 'package:metamorphosis_checkin/database/database.dart';
import 'package:metamorphosis_checkin/models/body_measurement.dart';

class MeasurementRepository {
  final Database _db;

  MeasurementRepository(this._db);

  /// 获取指定日期的测量记录
  Future<BodyMeasurement?> getMeasurement(String date) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'body_measurements',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isEmpty) return null;
    return BodyMeasurement.fromMap(maps.first);
  }

  /// 获取所有测量记录
  Future<List<BodyMeasurement>> getAllMeasurements() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'body_measurements',
      orderBy: 'date ASC',
    );
    return List.generate(maps.length, (i) => BodyMeasurement.fromMap(maps[i]));
  }

  /// 插入或更新测量记录
  Future<void> saveMeasurement(BodyMeasurement measurement) async {
    await _db.insert(
      'body_measurements',
      measurement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取最近的测量记录
  Future<BodyMeasurement?> getLatestMeasurement() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'body_measurements',
      orderBy: 'date DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BodyMeasurement.fromMap(maps.first);
  }
}
