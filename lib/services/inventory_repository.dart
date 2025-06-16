import '../models/inventory.dart';
import 'database_helper.dart';

class InventoryRepository {
  final DatabaseHelper dbHelper;

  InventoryRepository(this.dbHelper);

  Future<int> insertInventory(Inventory inventory) async {
    final db = await dbHelper.database;
    return await db.insert('Data_Inventory', inventory.toMap());
  }

  Future<List<Inventory>> getAllInventories() async {
    final db = await dbHelper.database;
    final result = await db.query('Data_Inventory');
    return result.map((map) => Inventory.fromMap(map)).toList();
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
    return await db.update(
      'Data_Inventory',
      inventory.toMap(),
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
