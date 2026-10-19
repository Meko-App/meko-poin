import 'package:meko_poin/models/category.dart';
import 'package:meko_poin/services/database_helper.dart';

class CategoryRepository {
  final DatabaseHelper dbHelper;

  CategoryRepository(this.dbHelper);

  Future<List<Category>> getAllCategories({
    bool includeDeleted = false,
    String? type,
  }) async {
    final db = await dbHelper.database;
    final whereConditions = <String>[];
    final whereArgs = <Object>[];

    if (!includeDeleted) {
      whereConditions.add('deleted_at IS NULL');
    }

    if (type != null) {
      whereConditions.add('type = ?');
      whereArgs.add(type);
    }

    final where = whereConditions.isEmpty ? null : whereConditions.join(' AND ');
    final result = await db.query(
      'Data_Category',
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC',
    );
    return result.map((row) => Category.fromMap(row)).toList();
  }

  Future<Category?> getCategoryByName(String name, {String? type}) async {
    final db = await dbHelper.database;
    final whereBuffer = StringBuffer('LOWER(name) = ? AND deleted_at IS NULL');
    final args = <Object>[name.toLowerCase()];

    if (type != null) {
      whereBuffer.write(' AND type = ?');
      args.add(type);
    }

    final result = await db.query(
      'Data_Category',
      where: whereBuffer.toString(),
      whereArgs: args,
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Category.fromMap(result.first);
  }

  Future<bool> isCategoryNameUsed(
    String name, {
    String type = 'menu',
    int? excludeId,
  }) async {
    final db = await dbHelper.database;
    final whereBuffer = StringBuffer(
      'LOWER(name) = ? AND type = ? AND deleted_at IS NULL',
    );
    final args = <Object>[name.toLowerCase(), type];

    if (excludeId != null) {
      whereBuffer.write(' AND id != ?');
      args.add(excludeId);
    }

    final result = await db.query(
      'Data_Category',
      columns: ['id'],
      where: whereBuffer.toString(),
      whereArgs: args,
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Category',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Category.fromMap(result.first);
  }

  Future<int> insertCategory(Category category) async {
    final db = await dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final data = category.toMap()
      ..remove('id')
      ..remove('deleted_at')
      ..['created_at'] = now
      ..['updated_at'] = now;

    return db.insert('Data_Category', data);
  }

  Future<int> updateCategory(Category category) async {
    final db = await dbHelper.database;
    final data = category.toMap()
      ..remove('id')
      ..remove('created_at')
      ..remove('deleted_at')
      ..['updated_at'] = DateTime.now().toIso8601String();

    return db.update(
      'Data_Category',
      data,
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> getMasterDataCountByCategoryId(int categoryId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM Data_Master WHERE category_id = ? AND deleted_at IS NULL',
      [categoryId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> softDeleteAndReassignMasterData({
    required int categoryId,
    String defaultCategoryName = 'Additional',
  }) async {
    final db = await dbHelper.database;

    return db.transaction((txn) async {
      final target = await txn.query(
        'Data_Category',
        where: 'LOWER(name) = ? AND deleted_at IS NULL',
        whereArgs: [defaultCategoryName.toLowerCase()],
        limit: 1,
      );

      if (target.isEmpty) {
        throw Exception('Kategori default tidak ditemukan');
      }

      final targetId = target.first['id'] as int;

      if (targetId == categoryId) {
        throw Exception('Kategori default tidak boleh dihapus');
      }

      await txn.update(
        'Data_Master',
        {
          'category_id': targetId,
          'category': target.first['name'] as String,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'category_id = ? AND deleted_at IS NULL',
        whereArgs: [categoryId],
      );

      await txn.update(
        'Data_Inventory',
        {
          'category_id': targetId,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'category_id = ? AND deleted_at IS NULL',
        whereArgs: [categoryId],
      );

      return txn.update(
        'Data_Category',
        {'deleted_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [categoryId],
      );
    });
  }
}
