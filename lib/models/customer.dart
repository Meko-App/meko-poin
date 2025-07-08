class Customer {
  final int? id;
  final int userId;
  final String name;
  final String phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      phone: map['phone'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
