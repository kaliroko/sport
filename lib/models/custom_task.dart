/// 自定义习惯任务模型
library;

class CustomTask {
  final String id;
  final String name;
  final String icon; // emoji
  final String category; // 'health', 'fitness', 'study', 'other'
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomTask({
    required this.id,
    required this.name,
    required this.icon,
    this.category = 'other',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'category': category,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory CustomTask.fromMap(Map<String, dynamic> map) {
    return CustomTask(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? '⭐',
      category: map['category'] as String? ?? 'other',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  CustomTask copyWith({String? name, String? icon, String? category, DateTime? updatedAt}) {
    return CustomTask(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'CustomTask($id: $name)';
}
