class Kas {
  final int? id;
  final int amount;
  final String description;
  final String type;
  final DateTime cashDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final int? createdBy;
  final int? updatedBy;
  final int? deletedBy;

  Kas({
    this.id,
    required this.amount,
    required this.description,
    required this.type,
    required this.cashDate,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
  });

  factory Kas.fromMap(Map<String, dynamic> map) {
    return Kas(
      id: map['id'],
      amount: map['amount'],
      description: map['description'],
      type: map['type'],
      cashDate: DateTime.parse(map['cash_date']),
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      deletedAt:
          map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
      createdBy: map['created_by'],
      updatedBy: map['updated_by'],
      deletedBy: map['deleted_by'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'type': type,
      'cash_date': cashDate.toIso8601String().split('T')[0],
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
      'deleted_by': deletedBy,
    };
  }

  Kas copyWith({
    int? id,
    int? amount,
    String? description,
    String? type,
    DateTime? cashDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? createdBy,
    int? updatedBy,
    int? deletedBy,
  }) {
    return Kas(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      type: type ?? this.type,
      cashDate: cashDate ?? this.cashDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  bool get isDeleted => deletedAt != null;
}
