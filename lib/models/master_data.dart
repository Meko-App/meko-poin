class MasterData {
  final int? id;
  final int userId;
  final int packagingId;
  final String name;
  final String category;
  final int? price;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  MasterData({
    this.id,
    required this.userId,
    required this.packagingId,
    required this.name,
    required this.category,
    this.price,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory MasterData.fromMap(Map<String, dynamic> map) {
    return MasterData(
      id: map['id'],
      userId: map['user_id'],
      packagingId: map['packaging_id'] ?? 0,
      name: map['name'],
      category: map['category'],
      price: map['price'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt:
          map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
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
      packagingId: packagingId,
      name: name,
      category: category,
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
      packagingId: packagingId,
      name: name,
      category: category,
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
      packagingId: newPackagingId,
      name: name,
      category: category,
      price: price,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      deletedAt: deletedAt,
    );
  }

  bool get isDeleted => deletedAt != null;
}
