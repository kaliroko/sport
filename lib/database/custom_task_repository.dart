/// 自定义习惯仓库
library;

import 'package:metamorphosis_checkin/models/custom_task.dart';
import 'package:sqflite/sqflite.dart';

class CustomTaskRepository {
  final Database _db;
  CustomTaskRepository(this._db);

  Future<List<CustomTask>> getAll() async {
    final maps = await _db.query('custom_tasks', orderBy: 'created_at ASC');
    return List.generate(maps.length, (i) => CustomTask.fromMap(maps[i]));
  }

  Future<void> insert(CustomTask task) async {
    await _db.insert('custom_tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    await _db.delete('custom_tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> update(CustomTask task) async {
    await _db.update(
      'custom_tasks',
      task.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }
}
