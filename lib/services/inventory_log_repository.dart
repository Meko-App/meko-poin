import '../models/inventory_log.dart';
import 'database_helper.dart';

class InventoryLogRepository {
  final DatabaseHelper dbHelper;

  InventoryLogRepository(this.dbHelper);

  Future<int> insertInventoryLog(InventoryLog inventoryLog) async {
    final db = await dbHelper.database;
    return await db.insert('Data_Inventory_Log', inventoryLog.toMap());
  }

  Future<List<InventoryLog>> getLogsByInventoryId(int inventoryId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Inventory_Log',
      where: 'inventory_id = ?',
      whereArgs: [inventoryId],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => InventoryLog.fromMap(map)).toList();
  }

  Future<List<InventoryLog>> getLogsByUserId(int userId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Inventory_Log',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => InventoryLog.fromMap(map)).toList();
  }

  Future<int> deleteLog(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'Data_Inventory_Log',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
