class Transaction {
  final int id;
  final int userId;
  final int? customerId;
  final int? discountPrice;
  final int? discountPercentage;
  final int finalPrice;
  final String paymentMethod;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    required this.userId,
    this.customerId,
    this.discountPrice,
    this.discountPercentage,
    required this.finalPrice,
    required this.paymentMethod,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      userId: map['user_id'],
      customerId: map['customer_id'],
      discountPrice: map['discount_price'],
      discountPercentage: map['discount_percentage'],
      finalPrice: map['final_price'],
      paymentMethod: map['payment_method'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'customer_id': customerId,
      'discount_price': discountPrice,
      'discount_percentage': discountPercentage,
      'final_price': finalPrice,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
