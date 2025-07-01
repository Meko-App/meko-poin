import 'package:intl/intl.dart';
import 'package:meko_poin/models/transaction.dart';

class TransactionWithCustomerUser {
  final Transaction transaction;
  final String customerName;
  final String customerPhone;
  final String addedBy;

  TransactionWithCustomerUser({
    required this.transaction,
    required this.customerName,
    required this.customerPhone,
    required this.addedBy,
  });

  factory TransactionWithCustomerUser.fromMap(Map<String, dynamic> map) {
    return TransactionWithCustomerUser(
      transaction: Transaction.fromMap(map),
      customerName: map['customer_name'] as String? ?? 'Unknown Customer',
      customerPhone: map['customer_phone'] as String? ?? '-',
      addedBy: map['user_name'] as String? ?? 'Unknown User',
    );
  }

  String get discountDisplay {
    if (transaction.discountPrice != null) {
      return 'Rp ${NumberFormat('#,###').format(transaction.discountPrice)}';
    } else if (transaction.discountPercentage != null) {
      return '${transaction.discountPercentage}%';
    }
    return '-';
  }
}
