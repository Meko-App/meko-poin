import '../models/master_data.dart';
import 'database_helper.dart';

class MasterDataRepository {
  final DatabaseHelper dbHelper;

  MasterDataRepository(this.dbHelper);

  Future<int> insertMasterData(MasterData masterData) async {
    final db = await dbHelper.database;
    return await db.insert('Data_Master', masterData.toMap());
  }

  Future<List<MasterData>> getAllMasterData() async {
    final db = await dbHelper.database;
    final result = await db.query('Data_Master');
    return result.map((map) => MasterData.fromMap(map)).toList();
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
    return await db.update(
      'Data_Master',
      masterData.toMap(),
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
