class KeuanganKategori {
  final int? id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  KeuanganKategori({
    this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory KeuanganKategori.fromMap(Map<String, dynamic> map) {
    return KeuanganKategori(
      id: map['id'],
      name: map['name'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      deletedAt:
          map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
