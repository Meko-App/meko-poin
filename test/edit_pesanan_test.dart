import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('Edit pesanan updates items, inventory, transaction, and kas', () async {
    final testDir = Directory(
        r'C:\Users\USER\AppData\Local\Temp\opencode\edit_pesanan_test');
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
    testDir.createSync(recursive: true);
    final dbPath = '${testDir.path}\\app_database.db';

    // Fresh DB created via the real create chain at v14.
    final db = await DatabaseHelper.instance.openAtPathForTesting(dbPath);

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

    final invoice = 'INV-EDIT-001';
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
      'transaction_id': transactionId,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Kas entry linked to the transaction.
    await db.insert('Data_Kas', {
      'amount': 30000,
      'description': 'Pemasukan dari transaksi atas nama Budi Invoice $invoice',
      'type': 'income',
      'cash_date': DateTime.now().toIso8601String(),
      'transaction_id': transactionId,
      'variable': 'cash',
      'created_by': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Decrement log recorded with transaction_id.
    await db.insert('Data_Inventory_Log', {
      'inventory_id': inventoryId,
      'user_id': 1,
      'type': 'decrement',
      'initial_stock': 100,
      'current_stock': 98,
      'difference': 2,
      'transaction_id': transactionId,
      'notes': 'Transaksi awal',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    final helper = _TestDatabaseHelper(dbPath);
    final repo = TransactionRepository(helper);

    // Edit: item qty 2 -> 3, total 30000 -> 45000.
    await repo.updateTransactionPesanan(
      transactionId: transactionId,
      discountPrice: 0,
      finalPrice: 45000,
      items: [
        {
          'master_data_id': masterId,
          'qty': 3,
          'total_price': 45000,
          'bundle_snapshot': null,
        },
      ],
      actorUserId: 1,
    );

    // Transaction final price updated.
    final txAfter = await db.rawQuery(
        'SELECT final_price, discount_price FROM Data_Transaction WHERE id = ?',
        [transactionId]);
    expect(txAfter.first['final_price'], 45000);
    expect(txAfter.first['discount_price'], 0);

    // Items replaced: exactly one item with qty 3.
    final itemsAfter = await db.rawQuery(
        'SELECT qty, total_price FROM Data_Transaction_Item WHERE transaction_id = ?',
        [transactionId]);
    expect(itemsAfter.length, 1);
    expect(itemsAfter.first['qty'], 3);
    expect(itemsAfter.first['total_price'], 45000);

    // Inventory: rollback +2 then re-decrement -3 => net 100 -> 97.
    final invAfter = await db.rawQuery(
        'SELECT stock FROM Data_Inventory WHERE id = ?', [inventoryId]);
    expect(invAfter.first['stock'], 97,
        reason: 'inventory must reflect edited quantity');

    // Kas amount synced to new final price.
    final kasAfter = await db.rawQuery(
        'SELECT amount FROM Data_Kas WHERE transaction_id = ? AND deleted_at IS NULL',
        [transactionId]);
    expect(kasAfter.first['amount'], 45000,
        reason: 'kas entry must follow new final price');

    await db.close();
    testDir.deleteSync(recursive: true);
  });

  test(
      'Delete after edit rolls back all items including newly added ones',
      () async {
    final testDir = Directory(
        r'C:\Users\USER\AppData\Local\Temp\opencode\edit_delete_rollback_test');
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
    testDir.createSync(recursive: true);
    final dbPath = '${testDir.path}\\app_database.db';

    final db = await DatabaseHelper.instance.openAtPathForTesting(dbPath);

    final masterRows = await db.rawQuery(
        'SELECT id FROM Data_Master WHERE name = ? LIMIT 1', ['Produk Dummy']);
    expect(masterRows, isNotEmpty);
    final masterId = masterRows.first['id'] as int;

    // Seed two inventory items (simulating print 4R and print 5R).
    // Stock is 99 because the initial sale already decremented from 100.
    final inv4rId = await db.insert('Data_Inventory', {
      'user_id': 1,
      'master_data_id': masterId,
      'name': 'Print 4R',
      'stock': 99,
      'stock_reject': 0,
      'notes': '',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    final master5rRows = await db.rawQuery(
        'SELECT id FROM Data_Master WHERE id != ? LIMIT 1', [masterId]);
    final master5rId = master5rRows.isNotEmpty
        ? master5rRows.first['id'] as int
        : masterId + 999;
    final inv5rId = await db.insert('Data_Inventory', {
      'user_id': 1,
      'master_data_id': master5rId,
      'name': 'Print 5R',
      'stock': 100, // untouched by initial sale
      'stock_reject': 0,
      'notes': '',
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

    final invoice = 'INV-EDITDEL-001';
    final transactionId = await db.insert('Data_Transaction', {
      'user_id': 1,
      'customer_id': customerId,
      'discount_price': 0,
      'final_price': 10000,
      'invoice_number': invoice,
      'payment_method': 'cash',
      'notes': '',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Initial item: 1x print 4R.
    await db.insert('Data_Transaction_Item', {
      'master_data_id': masterId,
      'qty': 1,
      'total_price': 10000,
      'transaction_id': transactionId,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Kas entry.
    await db.insert('Data_Kas', {
      'amount': 10000,
      'description': 'Income Invoice $invoice',
      'type': 'income',
      'cash_date': DateTime.now().toIso8601String(),
      'transaction_id': transactionId,
      'variable': 'cash',
      'created_by': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Decrement log for the initial item.
    await db.insert('Data_Inventory_Log', {
      'inventory_id': inv4rId,
      'user_id': 1,
      'type': 'decrement',
      'initial_stock': 100,
      'current_stock': 99,
      'difference': 1,
      'transaction_id': transactionId,
      'notes': 'Initial sale',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    final helper = _TestDatabaseHelper(dbPath);
    final repo = TransactionRepository(helper);

    // Edit: add print 5R alongside the existing print 4R.
    await repo.updateTransactionPesanan(
      transactionId: transactionId,
      discountPrice: 0,
      finalPrice: 25000,
      items: [
        {
          'master_data_id': masterId,
          'qty': 1,
          'total_price': 10000,
          'bundle_snapshot': null,
        },
        {
          'master_data_id': master5rId,
          'qty': 1,
          'total_price': 15000,
          'bundle_snapshot': null,
        },
      ],
      actorUserId: 1,
    );

    // After edit: print 4R stock 99 (rollback 1 + decrement 1 = net 0 change from 99),
    // print 5R stock 99 (decrement 1).
    final inv4rAfter = await db.rawQuery(
        'SELECT stock FROM Data_Inventory WHERE id = ?', [inv4rId]);
    expect(inv4rAfter.first['stock'], 99,
        reason: 'print 4R stock unchanged after edit (rollback+decrement)');

    final inv5rAfter = await db.rawQuery(
        'SELECT stock FROM Data_Inventory WHERE id = ?', [inv5rId]);
    expect(inv5rAfter.first['stock'], 99,
        reason: 'print 5R stock decremented by 1');

    // Verify logs have correct transaction_id.
    final logs = await db.rawQuery(
        'SELECT transaction_id, difference FROM Data_Inventory_Log WHERE transaction_id = ? ORDER BY difference ASC',
        [transactionId]);
    expect(logs.length, greaterThanOrEqualTo(2),
        reason: 'at least 2 decrement logs linked to transaction');
    for (final log in logs) {
      expect(log['transaction_id'], transactionId,
          reason: 'log must have correct transaction_id for rollback');
    }

    // Delete transaction: should rollback both print 4R and print 5R.
    final deleted =
        await repo.deleteTransaction(transactionId, actorUserId: 1);
    expect(deleted, 1);

    // Inventory restored.
    final inv4rFinal = await db.rawQuery(
        'SELECT stock FROM Data_Inventory WHERE id = ?', [inv4rId]);
    expect(inv4rFinal.first['stock'], 100,
        reason: 'print 4R stock restored after delete');

    final inv5rFinal = await db.rawQuery(
        'SELECT stock FROM Data_Inventory WHERE id = ?', [inv5rId]);
    expect(inv5rFinal.first['stock'], 100,
        reason: 'print 5R stock also restored after delete');

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