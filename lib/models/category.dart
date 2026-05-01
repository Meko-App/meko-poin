class Category {
  final int? id;
  final String name;
  final String code;
  final bool isBundle;
  final bool isCountable;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Category({
    this.id,
    required this.name,
    required this.code,
    this.isBundle = false,
    this.isCountable = false,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: (map['name'] ?? '') as String,
      code: (map['code'] ?? '') as String,
      isBundle: (map['is_bundle'] ?? 0) == 1,
      isCountable: (map['is_countable'] ?? 0) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'is_bundle': isBundle ? 1 : 0,
      'is_countable': isCountable ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
