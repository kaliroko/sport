/// 应用偏好设置：壁纸 + 语音播报
///
/// 全部持久化到 `app_settings` 表，跨启动保留。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metamorphosis_checkin/database/app_database.dart';
import 'package:metamorphosis_checkin/services/tts_service.dart';
import 'package:metamorphosis_checkin/utils/wallpaper_presets.dart';
import 'package:path_provider/path_provider.dart';

class AppSettingsService with ChangeNotifier {
  static const String _kWallpaperMode = 'wallpaper_mode';
  static const String _kWallpaperPreset = 'wallpaper_preset';
  static const String _kWallpaperImage = 'wallpaper_image';
  static const String _kWallpaperBlur = 'wallpaper_blur';
  static const String _kWallpaperDarken = 'wallpaper_darken';
  static const String _kTtsEnabled = 'tts_enabled';
  static const String _kTextScale = 'text_scale';

  static const String modePreset = 'preset';
  static const String modeImage = 'image';

  /// 字号倍率的可选档位
  static const List<double> textScaleOptions = [0.85, 1.0, 1.15, 1.3];
  static const List<String> textScaleLabels = ['小', '标准', '大', '特大'];
  static const double minTextScale = 0.7;
  static const double maxTextScale = 2.0;

  String _wallpaperMode = modePreset;
  String _presetId = WallpaperPresets.defaultId;
  String? _imagePath;
  double _wallpaperBlur = 0;
  double _wallpaperDarken = 0.25;
  bool _ttsEnabled = true;
  double _textScale = 1.0;
  bool _loaded = false;

  String get wallpaperMode => _wallpaperMode;
  String get wallpaperPresetId => _presetId;
  String? get wallpaperImagePath => _imagePath;
  double get wallpaperBlur => _wallpaperBlur;
  double get wallpaperDarken => _wallpaperDarken;
  bool get ttsEnabled => _ttsEnabled;

  /// 用户自定义字号倍率（1.0 = 跟随原本设计）
  double get textScale => _textScale;
  bool get isLoaded => _loaded;

  /// 是否真的应该用自定义图片当背景。
  /// 会校验文件是否存在 —— 用户可能在系统相册里把图删了。
  bool get usesImageWallpaper {
    if (_wallpaperMode != modeImage) return false;
    final path = _imagePath;
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }

  WallpaperPreset get preset => WallpaperPresets.byId(_presetId);

  Future<void> init() async {
    final settings = DatabaseManager.settingsRepository;
    _wallpaperMode = await settings.getString(_kWallpaperMode) ?? modePreset;
    _presetId = await settings.getString(_kWallpaperPreset) ?? WallpaperPresets.defaultId;
    _imagePath = await settings.getString(_kWallpaperImage);
    _wallpaperBlur = await settings.getDouble(_kWallpaperBlur) ?? 0;
    _wallpaperDarken = await settings.getDouble(_kWallpaperDarken) ?? 0.25;
    _ttsEnabled = await settings.getBool(_kTtsEnabled) ?? true;
    _textScale = await settings.getDouble(_kTextScale) ?? 1.0;
    TtsService.instance.enabled = _ttsEnabled;
    _loaded = true;
    notifyListeners();
  }

  /// 选用内置渐变预设
  Future<void> selectPreset(String presetId) async {
    _presetId = presetId;
    _wallpaperMode = modePreset;
    final settings = DatabaseManager.settingsRepository;
    await settings.setString(_kWallpaperPreset, presetId);
    await settings.setString(_kWallpaperMode, modePreset);
    notifyListeners();
  }

  /// 把用户选中的图片**复制到应用私有目录**再使用。
  ///
  /// 不直接引用相册原路径：原图可能被删除、移动，或者在不同 Android 版本上
  /// 因为 SAF/权限变化而失效，那样壁纸就会突然变空白。
  /// 返回 false 表示复制失败（调用方应提示用户）。
  Future<bool> setImageWallpaper(String sourcePath) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final wallpaperDir = Directory('${documentsDir.path}/wallpapers');
      if (!await wallpaperDir.exists()) {
        await wallpaperDir.create(recursive: true);
      }

      final extension = sourcePath.contains('.') ? sourcePath.split('.').last : 'jpg';
      final targetPath =
          '${wallpaperDir.path}/wallpaper_${DateTime.now().millisecondsSinceEpoch}.$extension';
      await File(sourcePath).copy(targetPath);

      // 删掉上一张，避免私有目录里无限堆积
      final old = _imagePath;
      if (old != null && old.isNotEmpty && old != targetPath) {
        final oldFile = File(old);
        if (await oldFile.exists()) {
          try {
            await oldFile.delete();
          } catch (_) {
            // 删除失败不影响新壁纸生效
          }
        }
      }

      _imagePath = targetPath;
      _wallpaperMode = modeImage;
      final settings = DatabaseManager.settingsRepository;
      await settings.setString(_kWallpaperImage, targetPath);
      await settings.setString(_kWallpaperMode, modeImage);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> setBlur(double value) async {
    _wallpaperBlur = value;
    await DatabaseManager.settingsRepository.setDouble(_kWallpaperBlur, value);
    notifyListeners();
  }

  Future<void> setDarken(double value) async {
    _wallpaperDarken = value;
    await DatabaseManager.settingsRepository.setDouble(_kWallpaperDarken, value);
    notifyListeners();
  }

  Future<void> setTtsEnabled(bool value) async {
    _ttsEnabled = value;
    TtsService.instance.enabled = value;
    if (!value) await TtsService.instance.stop();
    await DatabaseManager.settingsRepository.setBool(_kTtsEnabled, value);
    notifyListeners();
  }

  /// 设置全局字号倍率。
  ///
  /// 实际生效方式是 app.dart 里用 MediaQuery.textScaler 统一覆盖，
  /// 因此**不需要**修改任何一处 fontSize 调用点，全 App 立即生效。
  Future<void> setTextScale(double value) async {
    final clamped = value.clamp(minTextScale, maxTextScale).toDouble();
    _textScale = clamped;
    await DatabaseManager.settingsRepository.setDouble(_kTextScale, clamped);
    notifyListeners();
  }
}
