class BundleItem {
  final int? id;
  final int bundleId;
  final int componentMasterDataId;
  final String componentType;
  final int qty;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BundleItem({
    this.id,
    required this.bundleId,
    required this.componentMasterDataId,
    required this.componentType,
    this.qty = 1,
    this.createdAt,
    this.updatedAt,
  });

  factory BundleItem.fromMap(Map<String, dynamic> map) {
    return BundleItem(
      id: map['id'] as int?,
      bundleId: map['bundle_id'] as int,
      componentMasterDataId: map['component_master_data_id'] as int,
      componentType: (map['component_type'] ?? '') as String,
      qty: (map['qty'] ?? 1) as int,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bundle_id': bundleId,
      'component_master_data_id': componentMasterDataId,
      'component_type': componentType,
      'qty': qty,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
