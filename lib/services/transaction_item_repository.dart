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
}
