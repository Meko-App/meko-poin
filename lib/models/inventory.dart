class Inventory {
  final int? id;
  final int userId;
  final int masterDataId;
  final int stock;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Inventory({
    this.id,
    required this.userId,
    required this.masterDataId,
    required this.stock,
    required this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Inventory.fromMap(Map<String, dynamic> map) {
    return Inventory(
      id: map['id'],
      userId: map['user_id'],
      masterDataId: map['master_data_id'],
      stock: map['stock'],
      notes: map['notes'],
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
      'master_data_id': masterDataId,
      'stock': stock,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  // Method untuk soft delete
  Inventory markAsDeleted() {
    return Inventory(
      id: id,
      userId: userId,
      masterDataId: masterDataId,
      stock: stock,
      notes: notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      deletedAt: DateTime.now(),
    );
  }

  // Method untuk restore
  Inventory restore() {
    return Inventory(
      id: id,
      userId: userId,
      masterDataId: masterDataId,
      stock: stock,
      notes: notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      deletedAt: null,
    );
  }

  bool get isDeleted => deletedAt != null;
}
