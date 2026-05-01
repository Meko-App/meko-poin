import '../models/inventory.dart';
import 'database_helper.dart';
import 'package:meko_poin/models/additional/inventory_with_user_master_data.dart';
import 'package:meko_poin/models/inventory_log.dart';
import 'package:meko_poin/services/inventory_log_repository.dart';

class InventoryRepository {
  final DatabaseHelper dbHelper;
  late final InventoryLogRepository _inventoryLogRepository;

  InventoryRepository(this.dbHelper) {
    _inventoryLogRepository = InventoryLogRepository(dbHelper);
  }

  Future<int> insertInventory(Inventory inventory) async {
    final db = await dbHelper.database;

    final dataToInsert = inventory.toMap()
      ..addAll({
        'stock_reject': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

    final id = await db.insert('Data_Inventory', dataToInsert);

    if (id > 0) {
      final log = InventoryLog(
        id: null,
        inventoryId: id,
        userId: inventory.userId,
        type: 'increment',
        initialStock: 0,
        currentStock: inventory.stock,
        notes: 'Penambahan stok baru sebesar ${inventory.stock}',
        difference: inventory.stock,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _inventoryLogRepository.insertInventoryLog(log);

      // await _inventoryLogRepository.printAllInventoryLogs();
    }
    return id;
  }

  Future<List<Inventory>> getAllInventories() async {
    final db = await dbHelper.database;
    final result = await db.query('Data_Inventory');
    return result.map((map) => Inventory.fromMap(map)).toList();
  }

  Future<List<int>> getExistingInventoryIds() async {
    final db = await dbHelper.database;
    final results =
        await db.query('Data_Inventory', columns: ['master_data_id']);
    return results.map((e) => e['master_data_id'] as int).toList();
  }

  Future<List<InventoryWithUserMasterData>>
      getAllInventoryWithUserMasterData() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
    SELECT i.*, u.name AS addedBy, m.name AS name
    FROM Data_Inventory i
    JOIN Data_User u ON i.user_id = u.id
    JOIN Data_Master m ON i.master_data_id = m.id
    WHERE i.deleted_at is NULL
  ''');

    return result
        .map((row) => InventoryWithUserMasterData(
              inventoryData: Inventory(
                id: row['id'] as int,
                userId: row['user_id'] as int,
                masterDataId: row['master_data_id'] as int,
                stock: row['stock'] as int,
                stockReject: row['stock_reject'] as int,
                notes: row['notes'] as String,
                createdAt: DateTime.parse(row['created_at'] as String),
                updatedAt: DateTime.parse(row['updated_at'] as String),
              ),
              addedBy: row['addedBy'] as String,
              name: row['name'] as String,
            ))
        .toList();
  }

  Future<int> softDeleteInventory(int id) async {
    final db = await dbHelper.database;
    final inventoryToDeleteMap = await db.query(
      'Data_Inventory',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    int rowsAffected = 0;
    if (inventoryToDeleteMap.isNotEmpty) {
      final inventoryToDelete = Inventory.fromMap(inventoryToDeleteMap.first);

      rowsAffected = await db.update(
        'Data_Inventory',
        {'deleted_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );

      // After successful soft delete, log the event
      if (rowsAffected > 0) {
        final log = InventoryLog(
          id: null,
          inventoryId: id,
          userId: inventoryToDelete.userId,
          type: 'decrement',
          initialStock: inventoryToDelete.stock,
          currentStock: inventoryToDelete.stock,
          notes: 'Penghapusan data',
          difference: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _inventoryLogRepository.insertInventoryLog(log);

        // await _inventoryLogRepository.printAllInventoryLogs();
      }
    }
    return rowsAffected;
  }

  Future<int> restoreInventory(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'Data_Inventory',
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
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

    final oldInventoryMap = await db.query(
      'Data_Inventory',
      where: 'id = ?',
      whereArgs: [inventory.id],
      limit: 1,
    );

    int oldStock = 0;
    int oldRejectStock = 0;
    var type = '';
    int difference = 0;
    if (oldInventoryMap.isNotEmpty) {
      oldStock = oldInventoryMap.first['stock'] as int;
      oldRejectStock = oldInventoryMap.first['stock_reject'] as int;
    }

    if (inventory.stock > oldStock) {
      type = 'increment';
      difference = inventory.stock - oldStock;
    } else {
      type = 'decrement';
      difference = oldStock - inventory.stock;
    }

    final data = inventory.toMap()
      ..remove('created_at')
      ..['stock_reject'] = oldRejectStock
      ..['updated_at'] = DateTime.now().toIso8601String();

    final rowsAffected = await db.update(
      'Data_Inventory',
      data,
      where: 'id = ?',
      whereArgs: [inventory.id],
    );

    if (rowsAffected > 0) {
      final log = InventoryLog(
        id: null,
        inventoryId: inventory.id!,
        userId: inventory.userId,
        type: type,
        initialStock: oldStock,
        currentStock: inventory.stock,
        notes: type == 'increment'
            ? 'Penambahan stok sebesar $difference'
            : 'Pengurangan stok sebesar $difference',
        difference: difference,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _inventoryLogRepository.insertInventoryLog(log);

      // await _inventoryLogRepository.printAllInventoryLogs();
    }
    return rowsAffected;
  }

  Future<int> addReject(Inventory inventory, int reject) async {
    final db = await dbHelper.database;

    final oldInventoryMap = await db.query(
      'Data_Inventory',
      where: 'id = ?',
      whereArgs: [inventory.id],
      limit: 1,
    );

    int oldStock = 0;
    var type = 'decrement';

    if (oldInventoryMap.isNotEmpty) {
      oldStock = oldInventoryMap.first['stock'] as int;
    }

    final data = inventory.toMap()
      ..remove('created_at')
      ..['updated_at'] = DateTime.now().toIso8601String();

    final rowsAffected = await db.update(
      'Data_Inventory',
      data,
      where: 'id = ?',
      whereArgs: [inventory.id],
    );

    if (rowsAffected > 0) {
      final log = InventoryLog(
        id: null,
        inventoryId: inventory.id!,
        userId: inventory.userId,
        type: type,
        initialStock: oldStock,
        currentStock: inventory.stock,
        notes: 'Pengurangan stok karena reject sebesar $reject',
        difference: reject,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _inventoryLogRepository.insertInventoryLog(log);

      // await _inventoryLogRepository.printAllInventoryLogs();
    }
    return rowsAffected;
  }

  Future<int> addStock(
    Inventory inventory,
    int addAmount, {
    String? note,
  }) async {
    if (addAmount <= 0) {
      throw ArgumentError('Jumlah stok harus lebih dari 0');
    }

    final db = await dbHelper.database;

    final oldInventoryMap = await db.query(
      'Data_Inventory',
      where: 'id = ?',
      whereArgs: [inventory.id],
      limit: 1,
    );

    if (oldInventoryMap.isEmpty) {
      return 0;
    }

    final oldStock = oldInventoryMap.first['stock'] as int;
    final oldRejectStock = oldInventoryMap.first['stock_reject'] as int;

    final updatedInventory = inventory.copyWith(
      stock: oldStock + addAmount,
      stockReject: oldRejectStock,
      updatedAt: DateTime.now(),
    );

    final data = updatedInventory.toMap()
      ..remove('created_at')
      ..['updated_at'] = DateTime.now().toIso8601String();

    final rowsAffected = await db.update(
      'Data_Inventory',
      data,
      where: 'id = ?',
      whereArgs: [inventory.id],
    );

    if (rowsAffected > 0) {
      final log = InventoryLog(
        id: null,
        inventoryId: inventory.id!,
        userId: inventory.userId,
        type: 'increment',
        initialStock: oldStock,
        currentStock: oldStock + addAmount,
        notes: (note != null && note.trim().isNotEmpty)
            ? note.trim()
            : 'Penambahan stok sebesar $addAmount',
        difference: addAmount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _inventoryLogRepository.insertInventoryLog(log);
    }

    return rowsAffected;
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
