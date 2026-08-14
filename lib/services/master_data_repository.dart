import 'package:meko_poin/models/additional/master_data_with_user.dart';
import '../models/master_data.dart';
import 'database_helper.dart';

class MasterDataRepository {
  final DatabaseHelper dbHelper;

  MasterDataRepository(this.dbHelper);

  static const String _masterDataJoinQuery = '''
    SELECT
      m.id,
      m.user_id,
      m.category_id,
      m.name,
      COALESCE(c.name, m.category) AS category_name,
      m.price,
      m.created_at,
      m.updated_at,
      m.deleted_at
    FROM Data_Master m
    LEFT JOIN Data_Category c ON m.category_id = c.id
  ''';

  Future<Map<String, dynamic>?> _getCategoryById(int categoryId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Category',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [categoryId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<Map<String, dynamic>?> _getCategoryByName(String categoryName) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Category',
      where: 'LOWER(name) = ? AND deleted_at IS NULL',
      whereArgs: [categoryName.toLowerCase()],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<Map<String, dynamic>> _resolveCategoryForWrite(
      MasterData masterData) async {
    Map<String, dynamic>? category;

    if (masterData.categoryId != null) {
      category = await _getCategoryById(masterData.categoryId!);
    }

    if (category == null && masterData.category.isNotEmpty) {
      category = await _getCategoryByName(masterData.category);
    }

    if (category == null) {
      throw Exception('Kategori tidak valid atau tidak ditemukan');
    }

    return category;
  }

  Future<int> insertMasterData(MasterData masterData) async {
    final db = await dbHelper.database;
    final category = await _resolveCategoryForWrite(masterData);

    final dataToInsert = masterData.toMap()
      ..addAll({
        'category_id': category['id'],
        'category': category['name'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

    return db.insert('Data_Master', dataToInsert);
  }

  Future<List<MasterData>> getAllMasterData(
      {bool includeDeleted = false}) async {
    final db = await dbHelper.database;
    final deletedClause = includeDeleted ? '' : 'WHERE m.deleted_at IS NULL';
    final result = await db.rawQuery('''
      $_masterDataJoinQuery
      $deletedClause
      ORDER BY m.name ASC
    ''');

    return result.map((map) => MasterData.fromMap(map)).toList();
  }

  Future<List<MasterData>> getAllMasterDataForSelectCategory(
      {bool includeDeleted = false}) async {
    final db = await dbHelper.database;
    final deletedClause = includeDeleted ? '' : 'AND m.deleted_at IS NULL';

    final result = await db.rawQuery('''
      $_masterDataJoinQuery
      WHERE LOWER(COALESCE(c.name, m.category)) IN ('paper', 'product', 'additional', 'bundling', 'service', 'frame', 'property')
      $deletedClause
      ORDER BY m.name ASC
    ''');

    return result.map((map) => MasterData.fromMap(map)).toList();
  }

  Future<List<MasterData>> getAllMasterDataForSelect(
      {bool includeDeleted = false}) async {
    final db = await dbHelper.database;
    final deletedClause = includeDeleted ? '' : 'WHERE m.deleted_at IS NULL';

    final result = await db.rawQuery('''
      $_masterDataJoinQuery
      $deletedClause
      ORDER BY m.name ASC
    ''');

    return result.map((map) => MasterData.fromMap(map)).toList();
  }

  Future<List<MasterDataWithUser>> getAllMasterDataWithUser() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
      SELECT
        m.id,
        m.user_id,
        m.category_id,
        m.name,
        COALESCE(c.name, m.category) AS category_name,
        m.price,
        m.created_at,
        m.updated_at,
        m.deleted_at,
        u.name AS addedBy
      FROM Data_Master m
      JOIN Data_User u ON m.user_id = u.id
      LEFT JOIN Data_Category c ON m.category_id = c.id
      WHERE m.deleted_at IS NULL
      ORDER BY m.name ASC
    ''');

    return result
        .map((row) => MasterDataWithUser(
              masterData: MasterData.fromMap(row),
              addedBy: row['addedBy'] as String,
            ))
        .toList();
  }

  Future<int> softDeleteMasterData(int id) async {
    final db = await dbHelper.database;

    final canDelete = await canDeleteMasterData(id);
    if (!canDelete) {
      throw Exception(
          'Data tidak dapat dihapus karena sudah digunakan pada transaksi atau bundle aktif');
    }

    return db.update(
      'Data_Master',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> restoreMasterData(int id) async {
    final db = await dbHelper.database;
    return db.update(
      'Data_Master',
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<MasterData?> getMasterDataById(int id) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
      $_masterDataJoinQuery
      WHERE m.id = ?
      LIMIT 1
    ''', [id]);

    return result.isNotEmpty ? MasterData.fromMap(result.first) : null;
  }

  Future<int> updateMasterData(MasterData masterData) async {
    final db = await dbHelper.database;
    final category = await _resolveCategoryForWrite(masterData);

    final data = masterData.toMap()
      ..remove('created_at')
      ..['category_id'] = category['id']
      ..['category'] = category['name']
      ..['updated_at'] = DateTime.now().toIso8601String();

    return db.update(
      'Data_Master',
      data,
      where: 'id = ?',
      whereArgs: [masterData.id],
    );
  }

  Future<int> deleteMasterData(int id) async {
    final db = await dbHelper.database;

    final canDelete = await canDeleteMasterData(id);
    if (!canDelete) {
      throw Exception(
          'Data tidak dapat dihapus karena sudah digunakan pada transaksi atau bundle aktif');
    }

    return db.delete(
      'Data_Master',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<MasterData>> getMasterDataByCategory(String category) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
      $_masterDataJoinQuery
      WHERE LOWER(COALESCE(c.name, m.category)) = ?
      ORDER BY m.name ASC
    ''', [category.toLowerCase()]);

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
      print('Error checking inventory: $e');
      return 0;
    }
  }

  Future<bool> isNameAlreadyUsed(
    String name, {
    int? categoryId,
    int? excludeId,
  }) async {
    final db = await dbHelper.database;

    final whereBuffer =
        StringBuffer('LOWER(name) = ? AND deleted_at IS NULL');
    final args = <Object>[name.toLowerCase()];

    if (categoryId != null) {
      whereBuffer.write(' AND category_id = ?');
      args.add(categoryId);
    }

    if (excludeId != null) {
      whereBuffer.write(' AND id != ?');
      args.add(excludeId);
    }

    final result = await db.query(
      'Data_Master',
      columns: ['id'],
      where: whereBuffer.toString(),
      whereArgs: args,
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<bool> isMasterDataUsedInTransactions(int id) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM Data_Transaction_Item
      WHERE master_data_id = ?
        AND transaction_id IS NOT NULL
    ''', [id]);

    final total = result.first['total'] as int? ?? 0;
    return total > 0;
  }

  Future<bool> isMasterDataUsedAsBundleComponent(int id) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM Data_Bundle_Item bi
      INNER JOIN Data_Inventory inv ON inv.id = bi.component_inventory_id
      INNER JOIN Data_Master b ON b.id = bi.bundle_id
      WHERE inv.master_data_id = ?
        AND b.deleted_at IS NULL
    ''', [id]);

    final total = result.first['total'] as int? ?? 0;
    return total > 0;
  }

  Future<bool> canDeleteMasterData(int id) async {
    final masterData = await getMasterDataById(id);
    if (masterData == null) {
      return false;
    }

    final hasBundleItems = await isMasterDataBundle(id);
    if (hasBundleItems) {
      final usedInTransactions = await isMasterDataUsedInTransactions(id);
      if (usedInTransactions) {
        return false;
      }
    }

    final usedAsComponent = await isMasterDataUsedAsBundleComponent(id);
    if (usedAsComponent) {
      return false;
    }

    return true;
  }

  Future<bool> isMasterDataBundle(int id) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM Data_Bundle_Item
      WHERE bundle_id = ?
    ''', [id]);

    final total = result.first['total'] as int? ?? 0;
    return total > 0;
  }

  Future<List<MasterData>> getMasterDataByCategoryId(int categoryId,
      {bool includeDeleted = false}) async {
    final db = await dbHelper.database;
    final deletedClause = includeDeleted ? '' : 'AND m.deleted_at IS NULL';

    final result = await db.rawQuery('''
      $_masterDataJoinQuery
      WHERE m.category_id = ?
      $deletedClause
      ORDER BY m.name ASC
    ''', [categoryId]);

    return result.map((map) => MasterData.fromMap(map)).toList();
  }
}
