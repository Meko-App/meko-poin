import 'package:meko_poin/models/keuangan_kategori.dart';
import 'package:meko_poin/services/database_helper.dart';

class KeuanganKategoriRepository {
  final DatabaseHelper dbHelper;

  KeuanganKategoriRepository(this.dbHelper);

  Future<List<KeuanganKategori>> getAllKeuanganKategori() async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Keuangan_Kategori',
      where: 'deleted_at IS NULL',
      orderBy: 'name ASC',
    );
    return result.map((map) => KeuanganKategori.fromMap(map)).toList();
  }

  Future<KeuanganKategori?> getKeuanganKategoriById(int id) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Keuangan_Kategori',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty
        ? KeuanganKategori.fromMap(result.first)
        : null;
  }

  Future<int> insertKeuanganKategori(String name) async {
    final db = await dbHelper.database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('Data_Keuangan_Kategori', {
      'name': name,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<int> updateKeuanganKategori(KeuanganKategori kategori) async {
    final db = await dbHelper.database;
    return await db.update(
      'Data_Keuangan_Kategori',
      {
        'name': kategori.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [kategori.id],
    );
  }

  Future<int> softDeleteKeuanganKategori(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'Data_Keuangan_Kategori',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}