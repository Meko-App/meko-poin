import '../models/transaction_item.dart';
import 'database_helper.dart';

class TransactionItemRepository {
  final DatabaseHelper dbHelper;

  TransactionItemRepository(this.dbHelper);

  Future<int> insertTransactionItem(TransactionItem item) async {
    final db = await dbHelper.database;
    return await db.insert('Data_Transaction_Item', item.toMap());
  }

  Future<List<TransactionItem>> getItemsByTransaction(int transactionId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Transaction_Item',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    return result.map((map) => TransactionItem.fromMap(map)).toList();
  }

  Future<int> deleteTransactionItem(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'Data_Transaction_Item',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateTransactionItem(TransactionItem item) async {
    final db = await dbHelper.database;
    return await db.update(
      'Data_Transaction_Item',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<List<TransactionItem>> getAllCartItems() async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Transaction_Item',
      where: 'transaction_id IS NULL',
    );
    return result.map((map) => TransactionItem.fromMap(map)).toList();
  }

  Future<void> clearCart() async {
    final db = await dbHelper.database;
    await db.delete(
      'Data_Transaction_Item',
      where: 'transaction_id IS NULL',
    );
  }

  Future<TransactionItem?> findExistingCartItem(int masterDataId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Transaction_Item',
      where: 'master_data_id = ? AND transaction_id IS NULL',
      whereArgs: [masterDataId],
    );
    return result.isNotEmpty ? TransactionItem.fromMap(result.first) : null;
  }

  Future<List<TransactionItem>> getTransactionItemsByDateRange(
      DateTime startDate, DateTime endDate) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
      SELECT ti.*
      FROM Data_Transaction_Item ti
      JOIN Data_Transaction t ON ti.transaction_id = t.id
      WHERE t.created_at BETWEEN ? AND ?
      ORDER BY t.created_at DESC
    ''', [
      startDate.toIso8601String(),
      endDate.add(const Duration(days: 1)).toIso8601String(),
    ]);
    return result.map((map) => TransactionItem.fromMap(map)).toList();
  }
}
