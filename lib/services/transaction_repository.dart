import 'package:meko_poin/models/additional/transaction_with_customer_user.dart';

import '../models/transaction.dart';
import 'database_helper.dart';

class TransactionRepository {
  final DatabaseHelper dbHelper;

  TransactionRepository(this.dbHelper);

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await dbHelper.database;
    return await db.insert('Data_Transaction', transaction.toMap());
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await dbHelper.database;
    final result = await db.query('Data_Transaction');
    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<TransactionWithCustomerUser>>
      getAllTransactionsWithCustomerUser() async {
    final db = await dbHelper.database;

    final result = await db.rawQuery('''
      SELECT 
        t.*,
        c.name AS customer_name,
        c.phone AS customer_phone,
        u.name AS user_name
      FROM Data_Transaction t
      LEFT JOIN Data_Customer c ON t.customer_id = c.id
      LEFT JOIN Data_User u ON t.user_id = u.id
      ORDER BY t.created_at DESC
    ''');

    return result
        .map((row) => TransactionWithCustomerUser.fromMap(row))
        .toList();
  }

  Future<List<TransactionWithCustomerUser>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await dbHelper.database;

    final result = await db.rawQuery('''
    SELECT 
      t.*,
      c.name AS customer_name,
      c.phone AS customer_phone,
      u.name AS user_name
    FROM Data_Transaction t
    LEFT JOIN Data_Customer c ON t.customer_id = c.id
    LEFT JOIN Data_User u ON t.user_id = u.id
    WHERE t.created_at BETWEEN ? AND ?
    ORDER BY t.created_at DESC
  ''', [
      startDate.toIso8601String(),
      endDate.add(const Duration(days: 1)).toIso8601String(),
    ]);

    return result
        .map((row) => TransactionWithCustomerUser.fromMap(row))
        .toList();
  }

  Future<Transaction?> getTransactionById(int id) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Transaction',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? Transaction.fromMap(result.first) : null;
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await dbHelper.database;
    return await db.update(
      'Data_Transaction',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<List<Transaction>> getTransactionsByCustomer(int customerId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Transaction',
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );
    return result.map((map) => Transaction.fromMap(map)).toList();
  }
}
