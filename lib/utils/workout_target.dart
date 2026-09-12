/// 训练目标解析
///
/// 训练页（动作列表）与实时监督训练页共用同一套解析逻辑，
/// 避免两处各写一份造成组数/次数理解不一致。
library;

import 'package:metamorphosis_checkin/utils/constants.dart';

/// 一个动作的目标：组数 + 次数或秒数 + 组间休息秒数
class SetTarget {
  final int sets;
  final int reps; // 次数型使用，计时型为 0
  final int seconds; // 计时型使用，次数型为 0
  final int restSeconds;

  const SetTarget({
    required this.sets,
    this.reps = 0,
    this.seconds = 0,
    this.restSeconds = 45,
  });

  /// 是否计时型动作（平板支撑、靠墙静蹲等）
  bool get isDuration => seconds > 0;

  /// 这一组预计需要多少秒。
  ///
  /// 计时型直接用目标秒数；次数型按每次约 3 秒估算 ——
  /// 因为打卡必须「等计时跑完才算数」，次数型动作也要有一个计时窗口。
  int get perSetSeconds => seconds > 0 ? seconds : reps * 3;

  /// 单组的剂量文案，如「15 个」「40 秒」
  String get doseLabel => isDuration ? '$seconds 秒' : '$reps 个';

  /// 完整目标文案，如「3 组 × 15 个」
  String get fullLabel => '$sets 组 × $doseLabel';
}

/// 按当前周数取该动作的组数/次数配置（week1 / week3 / week5 / week7 四档）
String weekConfigFor(MovementConfig movement, int week) {
  if (week <= 2) return movement.week1;
  if (week <= 4) return movement.week3;
  if (week <= 6) return movement.week5;
  return movement.week7;
}

/// 解析配置字符串：
///   「3组×15个」    → sets 3, reps 15
///   「3组×40秒」    → sets 3, seconds 40
///   「3组×12次/侧」 → sets 3, reps 12
/// 组间休息单独从 movement.restTime（如「60秒」）读取。
SetTarget parseSetTarget(MovementConfig movement, String config) {
  final sets = int.tryParse(RegExp(r'(\d+)\s*组').firstMatch(config)?.group(1) ?? '') ?? 1;
  final restSeconds =
      int.tryParse(RegExp(r'(\d+)').firstMatch(movement.restTime)?.group(1) ?? '') ?? 45;

  if (movement.type == MovementType.duration) {
    final sec = int.tryParse(RegExp(r'(\d+)\s*秒').firstMatch(config)?.group(1) ?? '') ?? 30;
    return SetTarget(sets: sets, seconds: sec, restSeconds: restSeconds);
  }
  final reps = int.tryParse(RegExp(r'×\s*(\d+)').firstMatch(config)?.group(1) ?? '') ?? 10;
  return SetTarget(sets: sets, reps: reps, restSeconds: restSeconds);
}
