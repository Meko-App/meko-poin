import 'package:intl/intl.dart';
import 'package:meko_poin/models/additional/log_inventory_with_master_data.dart';
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

  Future<List<LogInventoryWithMasterData>> getTodayInventoryLogs() async {
    final db = await dbHelper.database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final result = await db.rawQuery('''
    SELECT 
      l.*,
      m.name AS product_name
    FROM Data_Inventory_Log l
    LEFT JOIN Data_Inventory i ON l.inventory_id = i.id
    LEFT JOIN Data_Master m ON i.master_data_id = m.id
    WHERE date(l.created_at) = ?
    ORDER BY l.created_at DESC
  ''', [today]);

    return result
        .map((row) => LogInventoryWithMasterData(
              inventoryLog: InventoryLog(
                id: row['id'] as int,
                userId: row['user_id'] as int,
                inventoryId: row['inventory_id'] as int,
                type: row['type'] as String,
                initialStock: row['initial_stock'] as int,
                currentStock: row['current_stock'] as int,
                difference: row['difference'] as int,
                notes: row['notes'] as String,
                createdAt: DateTime.parse(row['created_at'] as String),
                updatedAt: DateTime.parse(row['updated_at'] as String),
              ),
              productName: row['product_name'] as String,
            ))
        .toList();
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
