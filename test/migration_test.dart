import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('Migrate real production v1 database to v12', () async {
    final src = File(
        r'C:\Users\USER\AppData\Roaming\com.example\meko_poin\app_database.db');
    expect(src.existsSync(), true, reason: 'production DB must exist');

    final testDir = Directory(
        r'C:\Users\USER\AppData\Local\Temp\opencode\migration_test');
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
    testDir.createSync(recursive: true);
    final copyPath = '${testDir.path}\\app_database_copy.db';
    src.copySync(copyPath);

    // Confirm it starts at v1 with old schema (only when the production DB
// hasn't been migrated yet).
    final before = await databaseFactoryFfi.openDatabase(
        copyPath, options: OpenDatabaseOptions());
    final beforeVersion = await before.getVersion();
    final beforeTables = (await before
            .rawQuery("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"))
        .map((r) => r['name'] as String)
        .toList();
    if (beforeVersion < 2) {
      expect(beforeTables.contains('Data_Category'), false);
    }
    await before.close();

    // Run the real migration chain via the app's helper.
    final db = await DatabaseHelper.instance.openAtPathForTesting(copyPath);

    final version = await db.getVersion();
    expect(version, 12, reason: 'should be upgraded to v12');

    final tables = (await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"))
        .map((r) => r['name'] as String)
        .toList();
    for (final t in [
      'Data_Category',
      'Data_Bundle_Item',
      'Data_Transaction_Payment_Method_History',
    ]) {
      expect(tables.contains(t), true, reason: 'missing table $t after migration');
    }

    // Verify new columns exist.
    Future<List<String>> cols(String table) async {
      final rows = await db.rawQuery('PRAGMA table_info($table)');
      return rows.map((r) => r['name'] as String).toList();
    }

    final masterCols = await cols('Data_Master');
    expect(masterCols.contains('category_id'), true);
    expect(masterCols.contains('packaging_id'), false);

    final invCols = await cols('Data_Inventory');
    expect(invCols.contains('name'), true);
    expect(invCols.contains('category_id'), true);

    final kasCols = await cols('Data_Kas');
    expect(kasCols.contains('transaction_id'), true);

    // Ensure existing data survived (counts vary as the app is used).
    final masterCount = (await db
        .rawQuery('SELECT COUNT(*) AS c FROM Data_Master'))
        .first['c'];
    final inventoryCount =
        (await db.rawQuery('SELECT COUNT(*) AS c FROM Data_Inventory')).first['c'];
    final transactionCount =
        (await db.rawQuery('SELECT COUNT(*) AS c FROM Data_Transaction')).first['c'];
    expect(masterCount, greaterThan(0));
    expect(inventoryCount, greaterThan(0));
    expect(transactionCount, greaterThan(0));

    // Inventory names must be backfilled from master data.
    final unnamed = await db
        .rawQuery("SELECT COUNT(*) AS c FROM Data_Inventory WHERE name IS NULL OR name = ''");
    expect(unnamed.first['c'], 0);

    await db.close();
    testDir.deleteSync(recursive: true);
  });
}