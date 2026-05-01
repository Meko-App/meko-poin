import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/bundle_item.dart';
import 'database_helper.dart';

class BundleRepository {
  final DatabaseHelper dbHelper;

  BundleRepository(this.dbHelper);

  Future<List<BundleItem>> getBundleItems(int bundleId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Bundle_Item',
      where: 'bundle_id = ?',
      whereArgs: [bundleId],
      orderBy: 'component_type ASC',
    );

    return result.map((map) => BundleItem.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getBundleItemsWithMasterData(
      int bundleId) async {
    final db = await dbHelper.database;
    return db.rawQuery('''
      SELECT
        bi.id,
        bi.bundle_id,
        bi.component_master_data_id,
        bi.component_type,
        bi.qty,
        bi.created_at,
        bi.updated_at,
        m.name AS component_name,
        m.price AS component_price,
        m.category_id AS component_category_id,
        COALESCE(c.name, m.category) AS component_category_name,
        c.code AS component_category_code
      FROM Data_Bundle_Item bi
      INNER JOIN Data_Master m ON bi.component_master_data_id = m.id
      LEFT JOIN Data_Category c ON m.category_id = c.id
      WHERE bi.bundle_id = ? AND m.deleted_at IS NULL
      ORDER BY bi.component_type ASC
    ''', [bundleId]);
  }

  Future<void> replaceBundleItems(int bundleId, List<BundleItem> items) async {
    final db = await dbHelper.database;

    await db.transaction((txn) async {
      await txn.delete(
        'Data_Bundle_Item',
        where: 'bundle_id = ?',
        whereArgs: [bundleId],
      );

      final now = DateTime.now().toIso8601String();
      for (final item in items) {
        await txn.insert(
          'Data_Bundle_Item',
          {
            'bundle_id': bundleId,
            'component_master_data_id': item.componentMasterDataId,
            'component_type': item.componentType,
            'qty': item.qty,
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> deleteBundleItems(int bundleId) async {
    final db = await dbHelper.database;
    await db.delete(
      'Data_Bundle_Item',
      where: 'bundle_id = ?',
      whereArgs: [bundleId],
    );
  }

  Future<bool> isItemUsedAsComponent(int masterDataId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM Data_Bundle_Item bi
      INNER JOIN Data_Master b ON b.id = bi.bundle_id
      WHERE bi.component_master_data_id = ?
        AND b.deleted_at IS NULL
    ''', [masterDataId]);

    final total = result.first['total'] as int? ?? 0;
    return total > 0;
  }
}
