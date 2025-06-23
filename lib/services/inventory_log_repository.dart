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

  Future<void> printAllInventoryLogs() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query('Data_Inventory_Log');

    print('===== INVENTORY LOGS =====');
    print('Total logs: ${maps.length}');
    print('--------------------------');

    for (var log in maps) {
      print('ID: ${log['id']}');
      print('Inventory ID: ${log['inventory_id']}');
      print('User ID: ${log['user_id']}');
      print('Type: ${log['type']}');
      print('Initial Stock: ${log['initial_stock']}');
      print('Current Stock: ${log['current_stock']}');
      print('Difference: ${log['difference']}');
      print('Notes: ${log['notes']}');
      print('Created At: ${log['created_at']}');
      print('Updated At: ${log['updated_at']}');
      print('--------------------------');
    }
  }
}
