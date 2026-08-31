/// 用户资料模型
library;

import 'dart:convert';

class UserProfile {
  final int? id;
  final String name;
  final int age;
  final double heightCm;
  final double weightKg;
  final SchoolType schoolType;
  final int currentWeek;
  final String schedule;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    this.id,
    this.name = '',
    this.age = 16,
    this.heightCm = 170.0,
    this.weightKg = 65.0,
    this.schoolType = SchoolType.commute,
    this.currentWeek = 1,
    this.schedule = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// 计算BMI
  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  /// BMI分类
  String get bmiCategory {
    if (bmi < 18.5) return '偏瘦';
    if (bmi < 23.9) return '正常';
    if (bmi < 27.9) return '偏重';
    return '肥胖';
  }

  /// 从Map创建对象
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      age: (map['age'] as int?) ?? 16,
      heightCm: (map['height_cm'] as double?) ?? 170.0,
      weightKg: (map['weight_kg'] as double?) ?? 65.0,
      schoolType: _parseSchoolType(map['school_type'] as String?),
      currentWeek: (map['current_week'] as int?) ?? 1,
      schedule: map['schedule'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'school_type': _schoolTypeToString(schoolType),
      'current_week': currentWeek,
      'schedule': schedule,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static SchoolType _parseSchoolType(String? type) {
    switch (type?.toLowerCase()) {
      case 'commute':
        return SchoolType.commute;
      case 'boarder':
        return SchoolType.boarder;
      default:
        return SchoolType.commute;
    }
  }

  static String _schoolTypeToString(SchoolType type) {
    switch (type) {
      case SchoolType.commute:
        return 'commute';
      case SchoolType.boarder:
        return 'boarder';
    }
  }

  /// 从JSON字符串创建
  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// 转换为JSON字符串
  String toJson() => jsonEncode(toMap());

  /// 复制并更新字段
  UserProfile copyWith({
    String? name,
    int? age,
    double? heightCm,
    double? weightKg,
    SchoolType? schoolType,
    int? currentWeek,
    String? schedule,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      schoolType: schoolType ?? this.schoolType,
      currentWeek: currentWeek ?? this.currentWeek,
      schedule: schedule ?? this.schedule,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserProfile(name: $name, age: $age, week: $currentWeek)';
  }
}

enum SchoolType { commute, boarder }