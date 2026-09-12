/// 语音播报服务（TTS）
///
/// 训练时不用一直盯着屏幕：动作开始、每组完成、休息倒数都会播报。
///
/// 所有调用都包了 try/catch —— 设备没有中文语音引擎、或者用户禁用了
/// 系统的文字转语音服务时，TTS 会静默失效，但绝不能影响训练流程本身。
library;

import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  /// 是否启用。由 AppSettingsService 在读取/修改设置时同步过来。
  bool enabled = true;

  Future<void> init() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// 播报一句话。会先打断上一句，避免倒数时语音堆积。
  Future<void> speak(String text) async {
    if (!enabled || !_ready) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // 播报失败不应影响训练
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
