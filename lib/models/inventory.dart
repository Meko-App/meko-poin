class Inventory {
  final int? id;
  final int userId;
  final int masterDataId;
  final int stock;
  final int? stockReject;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Inventory({
    this.id,
    required this.userId,
    required this.masterDataId,
    required this.stock,
    this.stockReject,
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
      stockReject: map['stock_reject'] ?? 0,
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
      'stock_reject': stockReject,
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
      stockReject: stockReject,
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
      stockReject: stockReject,
      notes: notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      deletedAt: null,
    );
  }

  Inventory copyWith({
    int? id,
    int? userId,
    int? masterDataId,
    int? stock,
    int? stockReject,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Inventory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      masterDataId: masterDataId ?? this.masterDataId,
      stock: stock ?? this.stock,
      stockReject: stockReject ?? this.stockReject,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  bool get isDeleted => deletedAt != null;
}
