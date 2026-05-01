class TransactionItem {
  final int? id;
  final int masterDataId;
  final int? bundleId;
  final String? bundleSnapshot;
  final int qty;
  final int totalPrice;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? transactionId;

  TransactionItem({
    this.id,
    required this.masterDataId,
    this.bundleId,
    this.bundleSnapshot,
    required this.qty,
    required this.totalPrice,
    required this.createdAt,
    required this.updatedAt,
    this.transactionId,
  });

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      masterDataId: map['master_data_id'],
      bundleId: map['bundle_id'] as int?,
      bundleSnapshot: map['bundle_snapshot'] as String?,
      qty: map['qty'],
      totalPrice: map['total_price'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      transactionId: map['transaction_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'master_data_id': masterDataId,
      'bundle_id': bundleId,
      'bundle_snapshot': bundleSnapshot,
      'qty': qty,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'transaction_id': transactionId,
    };
  }
}
