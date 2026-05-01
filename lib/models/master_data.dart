class MasterData {
  final int? id;
  final int userId;
  final int? categoryId;
  final int packagingId;
  final String name;
  final String category;
  final String? categoryCode;
  final bool isBundle;
  final bool isCountable;
  final int? price;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  MasterData({
    this.id,
    required this.userId,
    this.categoryId,
    required this.packagingId,
    required this.name,
    required this.category,
    this.categoryCode,
    this.isBundle = false,
    this.isCountable = false,
    this.price,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory MasterData.fromMap(Map<String, dynamic> map) {
    return MasterData(
      id: map['id'],
      userId: map['user_id'],
      categoryId: map['category_id'] as int?,
      packagingId: map['packaging_id'] ?? 0,
      name: map['name'],
      category: (map['category_name'] ?? map['category'] ?? '') as String,
      categoryCode: map['category_code'] as String?,
      isBundle: (map['is_bundle'] ?? 0) == 1,
      isCountable: (map['is_countable'] ?? 0) == 1,
      price: map['price'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      deletedAt:
          map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'packaging_id': packagingId,
      'name': name,
      'category': category,
      'price': price,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  MasterData markAsDeleted() {
    return MasterData(
      id: id,
      userId: userId,
      categoryId: categoryId,
      packagingId: packagingId,
      name: name,
      category: category,
      categoryCode: categoryCode,
      isBundle: isBundle,
      isCountable: isCountable,
      price: price,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      deletedAt: DateTime.now(),
    );
  }

  MasterData restore() {
    return MasterData(
      id: id,
      userId: userId,
      categoryId: categoryId,
      packagingId: packagingId,
      name: name,
      category: category,
      categoryCode: categoryCode,
      isBundle: isBundle,
      isCountable: isCountable,
      price: price,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      deletedAt: null,
    );
  }

  MasterData changePackaging(int newPackagingId) {
    return MasterData(
      id: id,
      userId: userId,
      categoryId: categoryId,
      packagingId: newPackagingId,
      name: name,
      category: category,
      categoryCode: categoryCode,
      isBundle: isBundle,
      isCountable: isCountable,
      price: price,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      deletedAt: deletedAt,
    );
  }

  bool get isDeleted => deletedAt != null;
}
