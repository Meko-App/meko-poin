// import 'package:flutter/foundation.dart';
import 'package:meko_poin/models/additional/master_data_with_user.dart';
import '../models/master_data.dart';
import 'database_helper.dart';

class MasterDataRepository {
  final DatabaseHelper dbHelper;

  MasterDataRepository(this.dbHelper);

  Future<int> insertMasterData(MasterData masterData) async {
    final db = await dbHelper.database;

    final dataToInsert = masterData.toMap()
      ..addAll({
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

    return await db.insert('Data_Master', dataToInsert);
  }

  // Future<int> insertMasterData(MasterData masterData) async {
  //   final db = await dbHelper.database;

  //   // Insert data baru
  //   final id = await db.insert('Data_Master', masterData.toMap());

  //   // Tampilkan semua data setelah insert (versi simple)
  //   if (kDebugMode) {
  //     print('\n=== DATA MASTER TERKINI ===');
  //     final allData = await db.query('Data_Master');
  //     for (var data in allData) {
  //       print(data);
  //     }
  //     print('==========================\n');
  //   }

  //   return id;
  // }

  Future<List<MasterData>> getAllMasterData(
      {bool includeDeleted = false}) async {
    final db = await dbHelper.database;
    final where = includeDeleted ? null : 'deleted_at IS NULL';
    final result = await db.query('Data_Master', where: where);
    return result.map((map) => MasterData.fromMap(map)).toList();
  }

  Future<List<MasterData>> getAllMasterDataForSelectCategory(
      {bool includeDeleted = false}) async {
    final db = await dbHelper.database;
    final where = includeDeleted
        ? null
        : 'deleted_at IS NULL AND category IN ("Paper", "Product", "Additional")';
    final result = await db.query('Data_Master', where: where);
    return result.map((map) => MasterData.fromMap(map)).toList();
  }

  Future<List<MasterData>> getAllMasterDataForSelect(
      {bool includeDeleted = false}) async {
    final db = await dbHelper.database;
    String where = includeDeleted
        ? 'category IN ("Paper", "Packaging")'
        : 'deleted_at IS NULL AND category IN ("Paper", "Packaging")';
    final result = await db.query('Data_Master', where: where);
    return result.map((map) => MasterData.fromMap(map)).toList();
  }

  Future<List<MasterDataWithUser>> getAllMasterDataWithUser() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
    SELECT m.id, m.user_id, m.name, m.category, m.price, m.created_at, m.updated_at,
           u.name AS addedBy
    FROM Data_Master m
    JOIN Data_User u ON m.user_id = u.id
    WHERE m.deleted_at IS NULL
  ''');

    return result
        .map((row) => MasterDataWithUser(
              masterData: MasterData(
                id: row['id'] as int,
                userId: row['user_id'] as int,
                name: row['name'] as String,
                category: row['category'] as String,
                price: row['price'] as int?,
                createdAt: DateTime.parse(row['created_at'] as String),
                updatedAt: DateTime.parse(row['updated_at'] as String),
              ),
              addedBy: row['addedBy'] as String,
            ))
        .toList();
  }

  Future<int> softDeleteMasterData(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'Data_Master',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> restoreMasterData(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'Data_Master',
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<MasterData?> getMasterDataById(int id) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Master',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? MasterData.fromMap(result.first) : null;
  }

  Future<int> updateMasterData(MasterData masterData) async {
    final db = await dbHelper.database;

    final data = masterData.toMap()
      ..remove('created_at')
      ..['updated_at'] = DateTime.now().toIso8601String();

    return await db.update(
      'Data_Master',
      data,
      where: 'id = ?',
      whereArgs: [masterData.id],
    );
  }

  Future<int> deleteMasterData(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'Data_Master',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<MasterData>> getMasterDataByCategory(String category) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Master',
      where: 'category = ?',
      whereArgs: [category],
    );
    return result.map((map) => MasterData.fromMap(map)).toList();
  }

  Future<int?> getStockByMasterDataId(int masterDataId) async {
    final db = await DatabaseHelper.instance.database;
    try {
      final result = await db.query(
        'Data_Inventory',
        columns: ['stock'],
        where: 'master_data_id = ? AND deleted_at IS NULL',
        whereArgs: [masterDataId],
      );

      if (result.isEmpty) {
        return null;
      }
      return result.first['stock'] as int;
    } catch (e) {
      // Jika tabel tidak ada sama sekali (harusnya tidak terjadi jika migrasi database sudah benar)
      print('Error checking inventory: $e');
      return 0;
    }
  }
}
