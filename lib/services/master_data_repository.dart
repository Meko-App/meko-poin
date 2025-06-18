import 'package:flutter/foundation.dart';
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

  Future<List<MasterData>> getAllMasterData() async {
    final db = await dbHelper.database;
    final result = await db.query('Data_Master');
    return result.map((map) => MasterData.fromMap(map)).toList();
  }

  Future<List<MasterDataWithUser>> getAllMasterDataWithUser() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
    SELECT m.id, m.user_id, m.name, m.category, m.price, m.created_at, m.updated_at,
           u.name AS addedBy
    FROM Data_Master m
    JOIN Data_User u ON m.user_id = u.id
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
}
