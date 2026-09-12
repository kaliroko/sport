/// 「欲望空间」——私密的戒断动机页
///
/// 设计取舍（重要，请勿移除这些护栏）：
///  1. **全程本地**：照片复制到应用私有目录，项目里没有任何网络上传路径；
///     删掉 App 即彻底消失。
///  2. **首次进入必须主动确认**：18+ 与「本页采用厌恶/羞耻类动机法」的说明，
///     不能只是弹个窗点掉了事 —— 必须是勾选 + 确认，且写入持久化。
///  3. **可选 PIN 锁**：避免他人随手翻到你手机时看到。
///  4. **页面不预置任何性暗示或羞辱文案**：所有提醒文字由用户自己写。
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metamorphosis_checkin/database/app_database.dart';
import 'package:path_provider/path_provider.dart';

class DesireSpaceService with ChangeNotifier {
  static const String _kAgreed = 'desire_agreed_18';
  static const String _kPhoto = 'desire_photo_path';
  static const String _kPin = 'desire_pin';
  static const String _kNotes = 'desire_notes';

  bool _agreed = false;
  String? _photoPath;
  String _pin = '';
  List<String> _notes = [];
  bool _loaded = false;
  bool _unlocked = false;

  bool get agreed => _agreed;
  String? get photoPath => _photoPath;
  bool get hasPin => _pin.isNotEmpty;
  List<String> get notes => List.unmodifiable(_notes);
  bool get isLoaded => _loaded;
  bool get isUnlocked => _unlocked;

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
    _pin = await settings.getString(_kPin) ?? '';
    final rawNotes = await settings.getString(_kNotes);
    if (rawNotes != null && rawNotes.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawNotes);
        if (decoded is List) {
          _notes = decoded.map((e) => '$e').toList();
        }
      } catch (_) {
        _notes = [];
      }
    }
    // 没有设 PIN 时视为已解锁，省掉一次多余点击
    _unlocked = _pin.isEmpty;
    _loaded = true;
    notifyListeners();
  }

  /// 用户确认 18+ 与动机法说明
  Future<void> agree() async {
    _agreed = true;
    await DatabaseManager.settingsRepository.setBool(_kAgreed, true);
    notifyListeners();
  }

  /// 把用户选中的照片复制到应用私有目录。
  /// 不直接引用相册原路径：原图可能被删除或权限失效，那样这里会突然空白。
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

  Future<void> setPin(String pin) async {
    _pin = pin.trim();
    _unlocked = _pin.isEmpty;
    if (_pin.isEmpty) {
      await DatabaseManager.settingsRepository.remove(_kPin);
    } else {
      await DatabaseManager.settingsRepository.setString(_kPin, _pin);
    }
    notifyListeners();
  }

  bool verifyPin(String input) => _pin.isNotEmpty && input.trim() == _pin;

  void unlock() {
    _unlocked = true;
    notifyListeners();
  }

  void lock() {
    if (_pin.isEmpty) return;
    _unlocked = false;
    notifyListeners();
  }

  Future<void> addNote(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _notes.add(trimmed);
    await _persistNotes();
    notifyListeners();
  }

  Future<void> removeNote(int index) async {
    if (index < 0 || index >= _notes.length) return;
    _notes.removeAt(index);
    await _persistNotes();
    notifyListeners();
  }

  Future<void> _persistNotes() async {
    await DatabaseManager.settingsRepository
        .setString(_kNotes, jsonEncode(_notes));
  }
}
