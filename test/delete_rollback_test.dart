import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('Delete transaction rolls back inventory and kas', () async {
    final testDir = Directory(
        r'C:\Users\USER\AppData\Local\Temp\opencode\delete_rollback_test');
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
    testDir.createSync(recursive: true);
    final dbPath = '${testDir.path}\\app_database.db';

    // Fresh DB created via the real create chain at v13.
    final db = await DatabaseHelper.instance.openAtPathForTesting(dbPath);

    // Seed: an inventory item linked to the dummy master data.
    final masterRows = await db.rawQuery(
        'SELECT id FROM Data_Master WHERE name = ? LIMIT 1', ['Produk Dummy']);
    expect(masterRows, isNotEmpty, reason: 'dummy master must be seeded');
    final masterId = masterRows.first['id'] as int;

    final inventoryId = await db.insert('Data_Inventory', {
      'user_id': 1,
      'master_data_id': masterId,
      'name': 'Produk Dummy',
      'stock': 98,
      'stock_reject': 0,
      'notes': 'test',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    final customerId = await db.insert('Data_Customer', {
      'user_id': 1,
      'name': 'Budi',
      'phone': '08123456',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    final invoice = 'INV-ROLLBACK-001';
    final transactionId = await db.insert('Data_Transaction', {
      'user_id': 1,
      'customer_id': customerId,
      'discount_price': 0,
      'final_price': 30000,
      'invoice_number': invoice,
      'payment_method': 'cash',
      'notes': '',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('Data_Transaction_Item', {
      'master_data_id': masterId,
      'qty': 2,
      'total_price': 30000,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'transaction_id': transactionId,
    });

    // Kas entry with transaction_id + a legacy one linked only via invoice.
    await db.insert('Data_Kas', {
      'amount': 30000,
      'description': 'Pemasukan dari transaksi atas nama Budi Invoice $invoice',
      'type': 'income',
      'cash_date': DateTime.now().toIso8601String(),
      'transaction_id': transactionId,
      'created_by': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    await db.insert('Data_Kas', {
      'amount': 30000,
      'description': 'Pemasukan dari transaksi atas nama LEGACY Invoice $invoice',
      'type': 'income',
      'cash_date': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Decrement log recorded with transaction_id (as the app now does).
    await db.insert('Data_Inventory_Log', {
      'inventory_id': inventoryId,
      'user_id': 1,
      'type': 'decrement',
      'initial_stock': 100,
      'current_stock': 98,
      'difference': 2,
      'transaction_id': transactionId,
      'notes': 'Transaksi pada 16 Aug 2026, 09:00:00 dengan pengurangan sebesar 2',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    final helper = _TestDatabaseHelper(dbPath);
    final repo = TransactionRepository(helper);

    final deleted = await repo.deleteTransaction(transactionId, actorUserId: 1);
    expect(deleted, 1, reason: 'transaction should be deleted');

    // Inventory stock restored.
    final invAfter = await db.rawQuery(
        'SELECT stock FROM Data_Inventory WHERE id = ?', [inventoryId]);
    expect(invAfter.first['stock'], 100,
        reason: 'inventory stock must be restored after delete');

    // A rollback increment log must exist.
    final incLogs = await db.rawQuery('''
      SELECT * FROM Data_Inventory_Log
      WHERE transaction_id = ? AND type = 'increment' AND difference = 2
    ''', [transactionId]);
    expect(incLogs, isNotEmpty, reason: 'an increment rollback log must exist');

    // Kas entries (transaction_id-linked AND legacy invoice-linked) soft-deleted.
    final kasActive = await db.rawQuery('''
      SELECT * FROM Data_Kas WHERE deleted_at IS NULL AND description LIKE ?
    ''', ['%Invoice $invoice%']);
    expect(kasActive, isEmpty,
        reason: 'all kas entries for the invoice must be soft-deleted');

    final kasDeleted = await db.rawQuery('''
      SELECT * FROM Data_Kas WHERE deleted_at IS NOT NULL AND description LIKE ?
    ''', ['%Invoice $invoice%']);
    expect(kasDeleted.length, 2,
        reason: 'both kas rows (txn-linked + legacy) must be soft-deleted');

    // Transaction + items gone.
    final txnAfter = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM Data_Transaction WHERE id = ?', [transactionId]);
    expect(txnAfter.first['c'], 0);
    final itemsAfter = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM Data_Transaction_Item WHERE transaction_id = ?',
        [transactionId]);
    expect(itemsAfter.first['c'], 0);

    await db.close();
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