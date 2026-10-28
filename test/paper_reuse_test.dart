import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meko_poin/services/bundle_repository.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

bool _isPaperComponent(Map<String, dynamic> component) {
  final categoryName =
      (component['component_category_name'] as String?)?.toLowerCase().trim();
  if (categoryName == 'paper') {
    return true;
  }
  final type =
      (component['component_type'] as String?)?.toLowerCase().trim();
  return type == 'paper';
}

void main() {
  sqfliteFfiInit();

  group('Paper component detection tests', () {
    test('Detects paper component with lowercase full match', () {
      expect(_isPaperComponent({'component_category_name': 'paper'}), isTrue);
      expect(_isPaperComponent({'component_category_name': 'Paper'}), isTrue);
      expect(_isPaperComponent({'component_category_name': ' PAPER '}), isTrue);
      expect(_isPaperComponent({'component_type': 'paper'}), isTrue);
      expect(_isPaperComponent({'component_type': 'Paper'}), isTrue);
      expect(_isPaperComponent({'component_type': ' PAPER '}), isTrue);

      // Non-paper should be false
      expect(_isPaperComponent({'component_category_name': 'Packaging'}), isFalse);
      expect(_isPaperComponent({'component_category_name': 'Frame'}), isFalse);
      expect(_isPaperComponent({'component_category_name': 'print'}), isFalse);
      expect(_isPaperComponent({'component_type': 'frame'}), isFalse);
      expect(_isPaperComponent({}), isFalse);
    });

    test('Transaction repository respects isReusedPaper for paper bundle components', () async {
      final testDir = Directory(
          r'C:\Users\USER\AppData\Local\Temp\opencode\paper_reuse_test');
      if (testDir.existsSync()) testDir.deleteSync(recursive: true);
      testDir.createSync(recursive: true);
      final dbPath = '${testDir.path}\\app_database.db';

      final db = await DatabaseHelper.instance.openAtPathForTesting(dbPath);
      final helper = _TestDatabaseHelper(dbPath);
      final txRepo = TransactionRepository(helper);
      final bundleRepo = BundleRepository(helper);

      // 1. Get paper category id
      final paperCatRows = await db.rawQuery(
          "SELECT id FROM Data_Category WHERE LOWER(TRIM(name)) = 'paper' LIMIT 1");
      expect(paperCatRows, isNotEmpty);
      final paperCatId = paperCatRows.first['id'] as int;

      // 2. Get packaging category id
      final packCatRows = await db.rawQuery(
          "SELECT id FROM Data_Category WHERE LOWER(TRIM(name)) = 'packaging' LIMIT 1");
      expect(packCatRows, isNotEmpty);
      final packCatId = packCatRows.first['id'] as int;

      // 3. Create bundle master data
      final bundleMasterId = await db.insert('Data_Master', {
        'name': 'Paket Foto Lengkap',
        'category': 'Product',
        'price': 100000,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 4. Create master data & inventory for paper component
      final paperMasterId = await db.insert('Data_Master', {
        'name': 'Kertas Glossy 4R',
        'category': 'Paper',
        'price': 5000,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      final paperInvId = await db.insert('Data_Inventory', {
        'user_id': 1,
        'master_data_id': paperMasterId,
        'category_id': paperCatId,
        'name': 'Kertas Glossy 4R',
        'stock': 50,
        'stock_reject': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 5. Create master data & inventory for packaging component
      final packMasterId = await db.insert('Data_Master', {
        'name': 'Amplop Foto',
        'category': 'Packaging',
        'price': 2000,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      final packInvId = await db.insert('Data_Inventory', {
        'user_id': 1,
        'master_data_id': packMasterId,
        'category_id': packCatId,
        'name': 'Amplop Foto',
        'stock': 50,
        'stock_reject': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 6. Link components to bundle
      await db.insert('Data_Bundle_Item', {
        'bundle_id': bundleMasterId,
        'component_inventory_id': paperInvId,
        'component_type': 'Paper',
        'qty': 2,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('Data_Bundle_Item', {
        'bundle_id': bundleMasterId,
        'component_inventory_id': packInvId,
        'component_type': 'Packaging',
        'qty': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Verify bundle repo returns the components and paper is detected
      final bundleItems = await bundleRepo.getBundleItemsWithMasterData(bundleMasterId);
      expect(bundleItems.length, 2);
      expect(bundleItems.any(_isPaperComponent), isTrue);

      // 7. Create customer and transaction
      final customerId = await db.insert('Data_Customer', {
        'user_id': 1,
        'name': 'Siti',
        'phone': '08987654',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      final invoice = 'INV-REUSE-001';
      final transactionId = await db.insert('Data_Transaction', {
        'user_id': 1,
        'customer_id': customerId,
        'discount_price': 0,
        'final_price': 100000,
        'invoice_number': invoice,
        'payment_method': 'cash',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Initial item without reuse paper:
      await db.insert('Data_Transaction_Item', {
        'master_data_id': bundleMasterId,
        'qty': 1,
        'total_price': 100000,
        'transaction_id': transactionId,
        'is_reused_paper': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      // Initial stock reduction
      await db.update('Data_Inventory', {'stock': 48}, where: 'id = ?', whereArgs: [paperInvId]);
      await db.update('Data_Inventory', {'stock': 49}, where: 'id = ?', whereArgs: [packInvId]);

      // Edit order: enable is_reused_paper = 1
      await txRepo.updateTransactionPesanan(
        transactionId: transactionId,
        discountPrice: 0,
        finalPrice: 100000,
        items: [
          {
            'master_data_id': bundleMasterId,
            'qty': 1,
            'total_price': 100000,
            'is_reused_paper': 1,
          },
        ],
        actorUserId: 1,
      );

      // Paper stock should be restored to 50 because isReusedPaper = 1 (not decremented)
      final paperInv = await db.query('Data_Inventory', where: 'id = ?', whereArgs: [paperInvId]);
      expect(paperInv.first['stock'], 50);

      // Packaging stock should still be 49 (decremented normally)
      final packInv = await db.query('Data_Inventory', where: 'id = ?', whereArgs: [packInvId]);
      expect(packInv.first['stock'], 49);

      await db.close();
      testDir.deleteSync(recursive: true);
    });
  });
}
