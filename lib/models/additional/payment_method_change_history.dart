class PaymentMethodChangeHistory {
  final int id;
  final int transactionId;
  final String previousPaymentMethod;
  final String updatedPaymentMethod;
  final DateTime changedAt;
  final int? actorUserId;
  final String actorName;

  PaymentMethodChangeHistory({
    required this.id,
    required this.transactionId,
    required this.previousPaymentMethod,
    required this.updatedPaymentMethod,
    required this.changedAt,
    required this.actorUserId,
    required this.actorName,
  });

  factory PaymentMethodChangeHistory.fromMap(Map<String, dynamic> map) {
    return PaymentMethodChangeHistory(
      id: map['id'] as int,
      transactionId: map['transaction_id'] as int,
      previousPaymentMethod: map['previous_payment_method'] as String,
      updatedPaymentMethod: map['updated_payment_method'] as String,
      changedAt: DateTime.parse(map['changed_at'] as String),
      actorUserId: map['actor_user_id'] as int?,
      actorName: map['actor_name'] as String? ?? 'Unknown User',
    );
  }
}
