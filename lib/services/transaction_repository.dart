import 'package:intl/intl.dart';
import 'package:meko_poin/models/additional/transaction_with_customer_user.dart';
import 'package:meko_poin/models/transaction_item.dart';

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

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    final result = await db.rawQuery('''
    SELECT 
      t.*,
      c.name AS customer_name,
      c.phone AS customer_phone,
      u.name AS user_name
    FROM Data_Transaction t
    LEFT JOIN Data_Customer c ON t.customer_id = c.id
    LEFT JOIN Data_User u ON t.user_id = u.id
    WHERE t.created_at >= ?
    ORDER BY t.created_at DESC
  ''', [firstDayOfMonth.millisecondsSinceEpoch]);

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

  Future<TransactionWithCustomerUser> getTransactionWithCustomerUser(
      int transactionId) async {
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
    WHERE t.id = ?
    LIMIT 1
  ''', [transactionId]);

    if (result.isEmpty) {
      throw Exception('Transaction not found');
    }

    return TransactionWithCustomerUser.fromMap(result.first);
  }

  Future<List<TransactionWithCustomerUser>>
      getTodayTransactionsWithCustomer() async {
    final db = await dbHelper.database;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final result = await db.rawQuery('''
    SELECT 
      t.*,
      c.name AS customer_name,
      c.phone AS customer_phone,
      u.name AS user_name
    FROM Data_Transaction t
    LEFT JOIN Data_Customer c ON t.customer_id = c.id
    LEFT JOIN Data_User u ON t.user_id = u.id
    WHERE date(t.created_at) = ?
    ORDER BY t.created_at DESC
  ''', [today]);

    return result
        .map((map) => TransactionWithCustomerUser.fromMap(map))
        .toList();
  }

  Future<List<Transaction>> getGraphTodayTransaction() async {
    final db = await dbHelper.database;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final result = await db.rawQuery('''
    SELECT * FROM Data_Transaction
    WHERE date(created_at) = ?
    ORDER BY created_at DESC
  ''', [today]);

    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getFavoriteProducts() async {
    final db = await dbHelper.database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final result = await db.rawQuery('''
      SELECT 
        m.id,
        m.name,
        m.category,
        SUM(ti.qty) as total_qty,
        SUM(ti.total_price) as total_sales
      FROM Data_Transaction_Item ti
      JOIN Data_Master m ON ti.master_data_id = m.id
      JOIN Data_Transaction t ON ti.transaction_id = t.id
      WHERE m.deleted_at IS NULL
      AND date(t.created_at) = ?
      GROUP BY m.id, m.name, m.category
      ORDER BY total_qty DESC
      LIMIT 5
    ''', [today]);

    return result;
  }

  Future<List<TransactionItem>> getTransactionItems(int transactionId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Transaction_Item',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    return result.map((map) => TransactionItem.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getItemDetails(int masterDataId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Master',
      where: 'id = ?',
      whereArgs: [masterDataId],
    );

    if (result.isNotEmpty) {
      return {
        'category': result.first['category'] ?? 'Produk',
        'name': result.first['name'] ?? 'Unknown Item',
        'price': result.first['price'] ?? 0
      };
    }

    return {'category': 'Produk', 'name': 'Item #$masterDataId', 'price': 0};
  }
}
