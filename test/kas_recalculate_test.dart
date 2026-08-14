import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('Kas is recalculated when payment method changes', () async {
    final src = File(
        r'C:\Users\USER\AppData\Roaming\com.example\meko_poin\app_database.db');
    expect(src.existsSync(), true, reason: 'production DB must exist');

    final testDir = Directory(
        r'C:\Users\USER\AppData\Local\Temp\opencode\kas_test');
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
    testDir.createSync(recursive: true);
    final copyPath = '${testDir.path}\\app_database_copy.db';
    src.copySync(copyPath);

    // Migrate the copy to v12 using the real chain.
    final db = await DatabaseHelper.instance.openAtPathForTesting(copyPath);
    await db.close();

    // Re-open via TransactionRepository against the migrated copy.
    final helper = _TestDatabaseHelper(copyPath);
    final repo = TransactionRepository(helper);

    // Find a transaction created with payment_method 'cash'.
    final db2 = await databaseFactoryFfi.openDatabase(
        copyPath, options: OpenDatabaseOptions());
    final cashTxn = await db2.rawQuery('''
      SELECT t.id, t.final_price, t.invoice_number, t.customer_id, t.payment_method
      FROM Data_Transaction t
      WHERE t.payment_method = 'cash'
        AND t.id NOT IN (SELECT transaction_id FROM Data_Kas WHERE deleted_at IS NULL)
      LIMIT 1
    ''');

    final nonCashTxn = await db2.rawQuery('''
      SELECT t.id, t.final_price, t.invoice_number, t.customer_id
      FROM Data_Transaction t
      WHERE t.payment_method != 'cash'
      LIMIT 1
    ''');

    // Ensure we have a cash txn without a kas entry (test the create path).
    if (cashTxn.isNotEmpty) {
      final txnId = cashTxn.first['id'] as int;
      final rows = await repo.updatePaymentMethodWithHistory(
        transactionId: txnId,
        newPaymentMethod: 'cash',
        actorUserId: 1,
      );
      expect(rows, 0, reason: 'same method should be a no-op');

      // Change cash -> qris, should NOT create kas (already none, still none).
      await repo.updatePaymentMethodWithHistory(
        transactionId: txnId,
        newPaymentMethod: 'qris',
        actorUserId: 1,
      );
      final kasAfter = await db2.rawQuery(
          'SELECT * FROM Data_Kas WHERE transaction_id = ? AND deleted_at IS NULL',
          [txnId]);
      expect(kasAfter, isEmpty,
          reason: 'non-cash txn must not have an active kas entry');
    }

    if (nonCashTxn.isNotEmpty) {
      final txnId = nonCashTxn.first['id'] as int;
      // Ensure no active kas entry for this txn before test.
      await db2.rawQuery(
          'UPDATE Data_Kas SET deleted_at = datetime("now") WHERE transaction_id = ? AND deleted_at IS NULL',
          [txnId]);

      // non-cash -> cash should CREATE an active kas entry.
      await repo.updatePaymentMethodWithHistory(
        transactionId: txnId,
        newPaymentMethod: 'cash',
        actorUserId: 1,
      );
      final kasCash = await db2.rawQuery(
          'SELECT * FROM Data_Kas WHERE transaction_id = ? AND deleted_at IS NULL',
          [txnId]);
      expect(kasCash, isNotEmpty,
          reason: 'cash txn must have an active kas entry');
      expect(kasCash.first['type'], 'income');
      expect(kasCash.first['amount'], nonCashTxn.first['final_price']);

      // cash -> qris should SOFT DELETE the kas entry.
      await repo.updatePaymentMethodWithHistory(
        transactionId: txnId,
        newPaymentMethod: 'qris',
        actorUserId: 1,
      );
      final kasQris = await db2.rawQuery(
          'SELECT * FROM Data_Kas WHERE transaction_id = ? AND deleted_at IS NULL',
          [txnId]);
      expect(kasQris, isEmpty,
          reason: 'switching away from cash must remove the kas entry');
    }

    // Legacy kas entry (transaction_id NULL) linked only via invoice number
    // in the description must also be removed on cash -> qris.
    final legacyTxn = await db2.rawQuery('''
      SELECT t.id, t.final_price, t.invoice_number, t.customer_id
      FROM Data_Transaction t
      WHERE t.payment_method = 'cash'
      LIMIT 1
    ''');
    if (legacyTxn.isNotEmpty) {
      final txnId = legacyTxn.first['id'] as int;
      final invoice = legacyTxn.first['invoice_number'] as String;
      final amount = legacyTxn.first['final_price'] as int;

      // Simulate a pre-migration kas row without transaction_id.
      await db2.insert('Data_Kas', {
        'amount': amount,
        'description': 'Pemasukan dari transaksi atas nama TEST Invoice $invoice',
        'type': 'income',
        'cash_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // cash -> qris: both the transaction_id-linked row and the legacy
      // invoice-linked row must be removed.
      await repo.updatePaymentMethodWithHistory(
        transactionId: txnId,
        newPaymentMethod: 'qris',
        actorUserId: 1,
      );

      final legacyKas = await db2.rawQuery(
          'SELECT * FROM Data_Kas WHERE deleted_at IS NULL AND description LIKE ?',
          ['%Invoice $invoice%']);
      expect(legacyKas, isEmpty,
          reason: 'legacy kas entry linked via invoice must be removed');
    }

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

  // Unused members of DatabaseHelper; only `database` is used by the repo.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}