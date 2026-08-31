/// 用户资料服务
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:metamorphosis_checkin/database/app_database.dart';
import 'package:metamorphosis_checkin/models/user_profile.dart';

class UserProfileService with ChangeNotifier {
  UserProfile? _profile;
  final StreamController<bool> _hasProfileStream = StreamController<bool>();

  UserProfile? get profile => _profile;
  bool get hasProfile => _profile != null;
  Stream<bool> get hasProfileStream => _hasProfileStream.stream;

  /// 初始化服务
  Future<void> init() async {
    _profile = await DatabaseManager.profileRepository.getProfile();
    _hasProfileStream.add(_profile != null);
    notifyListeners();
  }

  /// 检查是否有用户资料
  Future<bool> checkHasProfile() async {
    return await DatabaseManager.profileRepository.hasProfile();
  }

  /// 保存用户资料
  Future<void> saveProfile(UserProfile profile) async {
    await DatabaseManager.profileRepository.saveProfile(profile);
    _profile = profile;
    _hasProfileStream.add(true);
    notifyListeners();
  }

  /// 更新当前阶段
  Future<void> updateWeek(int week) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(
      currentWeek: week,
      updatedAt: DateTime.now(),
    );
    await DatabaseManager.profileRepository.saveProfile(_profile!);
    notifyListeners();
  }

  /// 更新身体数据
  Future<void> updateWeight(double weightKg) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(
      weightKg: weightKg,
      updatedAt: DateTime.now(),
    );
    await DatabaseManager.profileRepository.saveProfile(_profile!);
    notifyListeners();
  }
}
