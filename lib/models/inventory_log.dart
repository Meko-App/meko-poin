class InventoryLog {
  final int id;
  final int inventoryId;
  final int userId;
  final String type;
  final int currentStock;
  final String notes;
  final int difference;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryLog({
    required this.id,
    required this.inventoryId,
    required this.userId,
    required this.type,
    required this.currentStock,
    required this.notes,
    required this.difference,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryLog.fromMap(Map<String, dynamic> map) {
    return InventoryLog(
      id: map['id'],
      inventoryId: map['inventory_id'],
      userId: map['user_id'],
      type: map['type'],
      currentStock: map['current_stock'],
      notes: map['notes'],
      difference: map['difference'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inventory_id': inventoryId,
      'user_id': userId,
      'type': type,
      'current_stock': currentStock,
      'notes': notes,
      'difference': difference,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
