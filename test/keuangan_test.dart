import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meko_poin/models/keuangan_kategori.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/kas_repository.dart';
import 'package:meko_poin/services/keuangan_kategori_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('Keuangan: two-variable totals, transfer, and category CRUD', () async {
    final src = File(
        r'C:\Users\USER\AppData\Roaming\com.example\meko_poin\app_database.db');
    expect(src.existsSync(), true, reason: 'production DB must exist');

    final testDir = Directory(
        r'C:\Users\USER\AppData\Local\Temp\opencode\keuangan_test');
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
    testDir.createSync(recursive: true);
    final copyPath = '${testDir.path}\\app_database_copy.db';
    src.copySync(copyPath);

    // Migrate the copy to v14 using the real chain.
    final db = await DatabaseHelper.instance.openAtPathForTesting(copyPath);
    await db.close();

    final helper = _TestDatabaseHelper(copyPath);
    final kasRepo = KasRepository(helper);
    final kategoriRepo = KeuanganKategoriRepository(helper);

    // Baseline totals.
    final cashBefore = await kasRepo.getTotalCash();
    final saldoBefore = await kasRepo.getTotalSaldoVariable();
    final totalBefore = await kasRepo.getTotalKeuangan();
    expect(totalBefore, cashBefore + saldoBefore,
        reason: 'total keuangan must equal cash + saldo');

    // --- Category CRUD ---
    final catId = await kategoriRepo.insertKeuanganKategori('Kategori Uji');
    final categories = await kategoriRepo.getAllKeuanganKategori();
    expect(categories.any((c) => c.id == catId), true);

    await kategoriRepo.updateKeuanganKategori(
        KeuanganKategori(id: catId, name: 'Kategori Uji Update'));
    final updated =
        await kategoriRepo.getKeuanganKategoriById(catId);
    expect(updated!.name, 'Kategori Uji Update');

    // --- Transfer Cash -> Saldo ---
    await kasRepo.transferKas(
      amount: 5000,
      description: 'Transfer uji Cash ke Saldo',
      fromVariable: 'cash',
      toVariable: 'saldo',
      cashDate: DateTime.now(),
      categoryId: catId,
      userId: 1,
    );

    final cashAfter = await kasRepo.getTotalCash();
    final saldoAfter = await kasRepo.getTotalSaldoVariable();
    final totalAfter = await kasRepo.getTotalKeuangan();

    // Cash berkurang 5000, Saldo bertambah 5000, total tidak berubah.
    expect(cashAfter, cashBefore - 5000,
        reason: 'transfer must decrease source variable');
    expect(saldoAfter, saldoBefore + 5000,
        reason: 'transfer must increase target variable');
    expect(totalAfter, totalBefore,
        reason: 'transfer must not change total keuangan');

    // Exactly one row is created for the transfer.
    final db2 = await databaseFactoryFfi.openDatabase(
        copyPath, options: OpenDatabaseOptions());
    final transferRows = await db2.rawQuery('''
      SELECT * FROM Data_Kas
      WHERE description = 'Transfer uji Cash ke Saldo' AND deleted_at IS NULL
    ''');
    expect(transferRows.length, 1,
        reason: 'transfer must create exactly one journal row');
    final row = transferRows.first;
    expect(row['variable'], 'cash');
    expect(row['type'], 'outcome');
    expect(row['amount'], 5000);
    expect(row['from_variable'], 'cash');
    expect(row['to_variable'], 'saldo');
    expect(row['category_id'], catId);

    // --- Transfer validation ---
    // Transfer melebihi saldo harus ditolak.
    await expectLater(
      kasRepo.transferKas(
        amount: 999999999,
        description: 'Transfer melebihi saldo',
        fromVariable: 'cash',
        toVariable: 'saldo',
        cashDate: DateTime.now(),
        userId: 1,
      ),
      throwsA(isA<Exception>()),
    );

    // Dari == Ke harus ditolak.
    await expectLater(
      kasRepo.transferKas(
        amount: 1000,
        description: 'Transfer salah',
        fromVariable: 'cash',
        toVariable: 'cash',
        cashDate: DateTime.now(),
        userId: 1,
      ),
      throwsA(isA<Exception>()),
    );

    // --- Autocomplete keterangan ---
    final suggestions = await kasRepo.getKasDescriptionSuggestions('Transfer uji');
    expect(suggestions.any((s) => s.contains('Transfer uji')), true);

    // --- Category soft delete ---
    await kategoriRepo.softDeleteKeuanganKategori(catId);
    final afterDelete = await kategoriRepo.getAllKeuanganKategori();
    expect(afterDelete.any((c) => c.id == catId), false);

    await db2.close();
    testDir.deleteSync(recursive: true);
  });
}

// Minimal DatabaseHelper stand-in that points at an explicit path.
class _TestDatabaseHelper implements DatabaseHelper {
  final String path;
  _TestDatabaseHelper(this.path);

  @override
  Future<Database> get database async {
    sqfliteFfiInit();
    return databaseFactoryFfi.openDatabase(
        path, options: OpenDatabaseOptions());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}