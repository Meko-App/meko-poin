import 'package:meko_poin/models/category.dart';
import 'package:meko_poin/services/database_helper.dart';

class CategoryRepository {
  final DatabaseHelper dbHelper;

  CategoryRepository(this.dbHelper);

  Future<List<Category>> getAllCategories({bool includeDeleted = false}) async {
    final db = await dbHelper.database;
    final where = includeDeleted ? null : 'deleted_at IS NULL';
    final result = await db.query(
      'Data_Category',
      where: where,
      orderBy: 'name ASC',
    );
    return result.map((row) => Category.fromMap(row)).toList();
  }

  Future<List<Category>> getCountableCategories() async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Category',
      where: 'deleted_at IS NULL AND is_countable = 1',
      orderBy: 'name ASC',
    );
    return result.map((row) => Category.fromMap(row)).toList();
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

  Future<Category?> getCategoryByCode(String code) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Category',
      where: 'LOWER(code) = ?',
      whereArgs: [code.toLowerCase()],
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
    String defaultCategoryCode = 'additional',
  }) async {
    final db = await dbHelper.database;

    return db.transaction((txn) async {
      final target = await txn.query(
        'Data_Category',
        where: 'LOWER(code) = ? AND deleted_at IS NULL',
        whereArgs: [defaultCategoryCode.toLowerCase()],
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

      return txn.update(
        'Data_Category',
        {'deleted_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [categoryId],
      );
    });
  }
}
