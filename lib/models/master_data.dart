class MasterData {
  final int? id;
  final int userId;
  final String name;
  final String category;
  final int? price;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MasterData({
    this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.price,
    this.createdAt,
    this.updatedAt,
  });

  factory MasterData.fromMap(Map<String, dynamic> map) {
    return MasterData(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      category: map['category'],
      price: map['price'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'category': category,
      'price': price,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
