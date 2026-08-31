/// 身体测量模型
library;

import 'dart:convert';

class BodyMeasurement {
  final String date;
  final double? weightKg;
  final double? waistCm;
  final double? chestCm;
  final double? armCm;
  final String photoFront;
  final String photoSide;
  final int? feelingScore;
  final DateTime createdAt;

  const BodyMeasurement({
    required this.date,
    this.weightKg,
    this.waistCm,
    this.chestCm,
    this.armCm,
    this.photoFront = '',
    this.photoSide = '',
    this.feelingScore,
    required this.createdAt,
  });

  /// 从Map创建对象
  factory BodyMeasurement.fromMap(Map<String, dynamic> map) {
    return BodyMeasurement(
      date: map['date'] as String,
      weightKg: map['weight_kg'] as double?,
      waistCm: map['waist_cm'] as double?,
      chestCm: map['chest_cm'] as double?,
      armCm: map['arm_cm'] as double?,
      photoFront: map['photo_front'] as String? ?? '',
      photoSide: map['photo_side'] as String? ?? '',
      feelingScore: map['feeling_score'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'weight_kg': weightKg,
      'waist_cm': waistCm,
      'chest_cm': chestCm,
      'arm_cm': armCm,
      'photo_front': photoFront,
      'photo_side': photoSide,
      'feeling_score': feelingScore,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 从JSON字符串创建
  factory BodyMeasurement.fromJson(String source) =>
      BodyMeasurement.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// 转换为JSON字符串
  String toJson() => jsonEncode(toMap());

  @override
  String toString() {
    return 'BodyMeasurement(date: $date, weight: $weightKg kg, waist: $waistCm cm)';
  }
}