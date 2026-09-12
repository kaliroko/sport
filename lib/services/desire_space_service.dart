/// 「欲望空间」——本地私密照片页
///
/// 设计取舍：
///  1. **全程本地**：照片复制到应用私有目录，项目里没有任何网络上传路径；
///     删掉 App 即彻底消失。
///  2. **首次进入需要确认**：18+ 与说明页（见 DesireSpaceScreen），
///     确认结果持久化。这是一个页面而不是弹窗，不会随便被点掉。
///  3. 页面本身只展示一张照片，不预置任何文案。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metamorphosis_checkin/database/app_database.dart';
import 'package:path_provider/path_provider.dart';

class DesireSpaceService with ChangeNotifier {
  static const String _kAgreed = 'desire_agreed_18';
  static const String _kPhoto = 'desire_photo_path';

  bool _agreed = false;
  String? _photoPath;
  bool _loaded = false;

  bool get agreed => _agreed;
  String? get photoPath => _photoPath;
  bool get isLoaded => _loaded;

  /// 是否真的有一张可用的照片（用户可能把私有目录里的文件删了）
  bool get hasPhoto {
    final path = _photoPath;
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }

  Future<void> init() async {
    final settings = DatabaseManager.settingsRepository;
    _agreed = await settings.getBool(_kAgreed) ?? false;
    _photoPath = await settings.getString(_kPhoto);
    _loaded = true;
    notifyListeners();
  }

  /// 用户确认 18+ 与说明页
  Future<void> agree() async {
    _agreed = true;
    await DatabaseManager.settingsRepository.setBool(_kAgreed, true);
    notifyListeners();
  }

  /// 把用户选中的照片复制到应用私有目录。
  ///
  /// 不直接引用相册原路径：原图可能被删除或权限失效，那样这里会突然空白。
  /// 也不需要任何存储权限 —— file_picker 走的是系统选择器（SAF），
  /// 由用户在系统界面里点选，App 只拿到被授权的那个文件。
  Future<bool> setPhoto(String sourcePath) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${documentsDir.path}/desire_space');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      final extension = sourcePath.contains('.') ? sourcePath.split('.').last : 'jpg';
      final targetPath =
          '${targetDir.path}/photo_${DateTime.now().millisecondsSinceEpoch}.$extension';
      await File(sourcePath).copy(targetPath);

      final old = _photoPath;
      if (old != null && old.isNotEmpty && old != targetPath) {
        final oldFile = File(old);
        if (await oldFile.exists()) {
          try {
            await oldFile.delete();
          } catch (_) {
            // 删除失败不影响新照片生效
          }
        }
      }

      _photoPath = targetPath;
      await DatabaseManager.settingsRepository.setString(_kPhoto, targetPath);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 删除照片（同时删掉私有目录里的文件）
  Future<void> removePhoto() async {
    final path = _photoPath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
    _photoPath = null;
    await DatabaseManager.settingsRepository.remove(_kPhoto);
    notifyListeners();
  }
}
