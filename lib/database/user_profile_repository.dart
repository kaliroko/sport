/// 用户资料数据仓库
library;

import 'package:metamorphosis_checkin/database/database.dart';
import 'package:metamorphosis_checkin/models/user_profile.dart';

class UserProfileRepository {
  final Database _db;

  UserProfileRepository(this._db);

  /// 获取用户资料
  Future<UserProfile?> getProfile() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'user_profiles',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  /// 插入或更新用户资料
  Future<void> saveProfile(UserProfile profile) async {
    await _db.insert(
      'user_profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 检查是否已有用户资料
  Future<bool> hasProfile() async {
    final count = await _db.rawSelect(
      'SELECT COUNT(*) FROM user_profiles',
    );
    return (count.first['COUNT(*)'] as int) > 0;
  }
}
