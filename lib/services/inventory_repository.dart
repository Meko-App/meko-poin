import '../models/inventory.dart';
import 'database_helper.dart';
import 'package:meko_poin/models/additional/inventory_with_user_master_data.dart';

class InventoryRepository {
  final DatabaseHelper dbHelper;

  InventoryRepository(this.dbHelper);

  Future<int> insertInventory(Inventory inventory) async {
    final db = await dbHelper.database;

    final dataToInsert = inventory.toMap()
      ..addAll({
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

    return await db.insert('Data_Inventory', dataToInsert);
  }

  Future<List<Inventory>> getAllInventories() async {
    final db = await dbHelper.database;
    final result = await db.query('Data_Inventory');
    return result.map((map) => Inventory.fromMap(map)).toList();
  }

  Future<List<InventoryWithUserMasterData>>
      getAllInventoryWithUserMasterData() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
    SELECT i.*, u.name AS addedBy, m.name AS name
    FROM Data_Inventory i
    JOIN Data_User u ON i.user_id = u.id
    JOIN Data_Master m ON i.master_data_id = m.id
  ''');

    return result
        .map((row) => InventoryWithUserMasterData(
              inventoryData: Inventory(
                id: row['id'] as int,
                userId: row['user_id'] as int,
                masterDataId: row['master_data_id'] as int,
                stock: row['stock'] as int,
                notes: row['notes'] as String,
                createdAt: DateTime.parse(row['created_at'] as String),
                updatedAt: DateTime.parse(row['updated_at'] as String),
              ),
              addedBy: row['addedBy'] as String,
              name: row['name'] as String,
            ))
        .toList();
  }

  Future<Inventory?> getInventoryById(int id) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Inventory',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? Inventory.fromMap(result.first) : null;
  }

  Future<int> updateInventory(Inventory inventory) async {
    final db = await dbHelper.database;

    final data = inventory.toMap()
      ..remove('created_at')
      ..['updated_at'] = DateTime.now().toIso8601String();

    return await db.update(
      'Data_Inventory',
      data,
      where: 'id = ?',
      whereArgs: [inventory.id],
    );
  }

  Future<int> deleteInventory(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'Data_Inventory',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Inventory>> getInventoriesByMasterData(int masterDataId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Inventory',
      where: 'master_data_id = ?',
      whereArgs: [masterDataId],
    );
    return result.map((map) => Inventory.fromMap(map)).toList();
  }
}
