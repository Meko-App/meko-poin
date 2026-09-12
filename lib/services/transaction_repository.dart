import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:meko_poin/models/additional/daily_report.dart';
import 'package:meko_poin/models/additional/payment_method_change_history.dart';
import 'package:meko_poin/models/additional/transaction_with_customer_user.dart';
import 'package:meko_poin/models/transaction_item.dart';

import '../models/transaction.dart';
import 'database_helper.dart';

class TransactionRepository {
  final DatabaseHelper dbHelper;

  TransactionRepository(this.dbHelper);

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await dbHelper.database;
    return await db.insert('Data_Transaction', transaction.toMap());
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await dbHelper.database;
    final result = await db.query('Data_Transaction');
    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Transaction>> getAllTransactionsThisMonth() async {
    final db = await dbHelper.database;

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    final startDate = firstDayOfMonth.toIso8601String();
    final endDate = lastDayOfMonth.toIso8601String();

    final result = await db.query(
      'Data_Transaction',
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
    );

    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<TransactionWithCustomerUser>>
      getAllTransactionsWithCustomerUser() async {
    final db = await dbHelper.database;

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstDayString = firstDayOfMonth.toIso8601String();

    final result = await db.rawQuery('''
    SELECT 
      t.*,
      c.name AS customer_name,
      c.phone AS customer_phone,
      u.name AS user_name
    FROM Data_Transaction t
    LEFT JOIN Data_Customer c ON t.customer_id = c.id
    LEFT JOIN Data_User u ON t.user_id = u.id
    WHERE t.created_at >= ?
    ORDER BY t.created_at DESC
  ''', [firstDayString]);

    return result
        .map((row) => TransactionWithCustomerUser.fromMap(row))
        .toList();
  }

  Future<List<TransactionWithCustomerUser>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await dbHelper.database;

    final result = await db.rawQuery('''
    SELECT 
      t.*,
      c.name AS customer_name,
      c.phone AS customer_phone,
      u.name AS user_name
    FROM Data_Transaction t
    LEFT JOIN Data_Customer c ON t.customer_id = c.id
    LEFT JOIN Data_User u ON t.user_id = u.id
    WHERE t.created_at BETWEEN ? AND ?
    ORDER BY t.created_at DESC
  ''', [
      startDate.toIso8601String(),
      endDate.add(const Duration(days: 1)).toIso8601String(),
    ]);

    return result
        .map((row) => TransactionWithCustomerUser.fromMap(row))
        .toList();
  }

  Future<Transaction?> getTransactionById(int id) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Transaction',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? Transaction.fromMap(result.first) : null;
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await dbHelper.database;
    return await db.update(
      'Data_Transaction',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> updatePaymentMethodWithHistory({
    required int transactionId,
    required String newPaymentMethod,
    required int actorUserId,
  }) async {
    final db = await dbHelper.database;

    return db.transaction((txn) async {
      final transactionResult = await txn.query(
        'Data_Transaction',
        columns: [
          'payment_method',
          'final_price',
          'invoice_number',
          'customer_id',
        ],
        where: 'id = ?',
        whereArgs: [transactionId],
        limit: 1,
      );

      if (transactionResult.isEmpty) {
        throw Exception('Transaction not found');
      }

      final previousPaymentMethod =
          (transactionResult.first['payment_method'] as String?)
                  ?.toLowerCase() ??
              '';
      final normalizedNewPaymentMethod = newPaymentMethod.toLowerCase();

      if (previousPaymentMethod == normalizedNewPaymentMethod) {
        return 0;
      }

      final now = DateTime.now().toIso8601String();

      final updatedRows = await txn.update(
        'Data_Transaction',
        {
          'payment_method': normalizedNewPaymentMethod,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      if (updatedRows > 0) {
        await txn.insert(
          'Data_Transaction_Payment_Method_History',
          {
            'transaction_id': transactionId,
            'actor_user_id': actorUserId,
            'previous_payment_method': previousPaymentMethod,
            'updated_payment_method': normalizedNewPaymentMethod,
            'changed_at': now,
            'created_at': now,
          },
        );
      }

      // Jaga konsistensi keuangan: entri keuangan mengikuti metode pembayaran.
      // Tunai -> variable='cash', QRIS/e-wallet -> variable='saldo'.
      final invoiceNumber =
          transactionResult.first['invoice_number'] as String? ?? '';
      final previousVariable = _variableForPaymentMethod(previousPaymentMethod);
      final newVariable = _variableForPaymentMethod(normalizedNewPaymentMethod);

      if (previousVariable != newVariable) {
        // Hapus semua entri keuangan aktif yang terkait transaksi ini
        // (baik yang tercatat dengan transaction_id maupun legacy lewat invoice),
        // lalu buat entri baru sesuai variabel metode baru.
        await txn.update(
          'Data_Kas',
          {
            'deleted_at': now,
            'updated_at': now,
            'deleted_by': actorUserId,
          },
          where: 'deleted_at IS NULL AND (transaction_id = ? OR description LIKE ?)',
          whereArgs: [transactionId, '%Invoice $invoiceNumber%'],
        );

        final finalPrice = transactionResult.first['final_price'] as int? ?? 0;
        final customerId = transactionResult.first['customer_id'] as int?;
        final customerName = customerId != null
            ? _getCustomerNameById(txn, customerId)
            : null;

        await txn.insert('Data_Kas', {
          'amount': finalPrice,
          'description':
              'Pemasukan dari transaksi atas nama ${customerName ?? '-'} Invoice $invoiceNumber',
          'type': 'income',
          'cash_date': now,
          'transaction_id': transactionId,
          'variable': newVariable,
          'created_by': actorUserId,
          'created_at': now,
          'updated_at': now,
        });
      }

      return updatedRows;
    });
  }

  String _variableForPaymentMethod(String paymentMethod) {
    return paymentMethod.toLowerCase() == 'cash' ? 'cash' : 'saldo';
  }

  Future<String?> _getCustomerNameById(dynamic txn, int customerId) async {
    final result = await txn.query(
      'Data_Customer',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first['name'] as String? : null;
  }

  Future<List<PaymentMethodChangeHistory>> getPaymentMethodHistory(
    int transactionId, {
    int limit = 10,
    int offset = 0,
  }) async {
    final db = await dbHelper.database;

    final result = await db.rawQuery('''
      SELECT
        h.*,
        u.name AS actor_name
      FROM Data_Transaction_Payment_Method_History h
      LEFT JOIN Data_User u ON h.actor_user_id = u.id
      WHERE h.transaction_id = ?
      ORDER BY h.changed_at DESC, h.id DESC
      LIMIT ? OFFSET ?
    ''', [transactionId, limit, offset]);

    return result
        .map((row) => PaymentMethodChangeHistory.fromMap(row))
        .toList();
  }

  Future<int> getPaymentMethodHistoryCount(int transactionId) async {
    final db = await dbHelper.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM Data_Transaction_Payment_Method_History
      WHERE transaction_id = ?
    ''', [transactionId]);

    return result.first['total'] as int? ?? 0;
  }

  Future<List<Transaction>> getTransactionsByCustomer(int customerId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Transaction',
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );
    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<TransactionWithCustomerUser> getTransactionWithCustomerUser(
      int transactionId) async {
    final db = await dbHelper.database;

    final result = await db.rawQuery('''
    SELECT 
      t.*,
      c.name AS customer_name,
      c.phone AS customer_phone,
      u.name AS user_name
    FROM Data_Transaction t
    LEFT JOIN Data_Customer c ON t.customer_id = c.id
    LEFT JOIN Data_User u ON t.user_id = u.id
    WHERE t.id = ?
    LIMIT 1
  ''', [transactionId]);

    if (result.isEmpty) {
      throw Exception('Transaction not found');
    }

    return TransactionWithCustomerUser.fromMap(result.first);
  }

  Future<List<TransactionWithCustomerUser>>
      getTodayTransactionsWithCustomer() async {
    final db = await dbHelper.database;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final result = await db.rawQuery('''
    SELECT 
      t.*,
      c.name AS customer_name,
      c.phone AS customer_phone,
      u.name AS user_name
    FROM Data_Transaction t
    LEFT JOIN Data_Customer c ON t.customer_id = c.id
    LEFT JOIN Data_User u ON t.user_id = u.id
    WHERE date(t.created_at) = ?
    ORDER BY t.created_at DESC
  ''', [today]);

    return result
        .map((map) => TransactionWithCustomerUser.fromMap(map))
        .toList();
  }

  Future<List<Transaction>> getGraphTodayTransaction() async {
    final db = await dbHelper.database;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final result = await db.rawQuery('''
    SELECT * FROM Data_Transaction
    WHERE date(created_at) = ?
    ORDER BY created_at DESC
  ''', [today]);

    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Transaction>> getGraphTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await dbHelper.database;

    final result = await db.rawQuery('''
    SELECT * FROM Data_Transaction
    WHERE created_at BETWEEN ? AND ?
    ORDER BY created_at DESC
  ''', [
      startDate.toIso8601String(),
      endDate.add(const Duration(days: 1)).toIso8601String(),
    ]);

    return result.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getFavoriteProducts() async {
    final db = await dbHelper.database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final result = await db.rawQuery('''
    SELECT 
      m.id,
      m.name,
      COALESCE(c.name, m.category) as category,
      SUM(ti.qty) as total_qty,
      SUM(ti.total_price) as total_sales
    FROM Data_Transaction_Item ti
    JOIN Data_Master m ON ti.master_data_id = m.id
    LEFT JOIN Data_Category c ON m.category_id = c.id
    JOIN Data_Transaction t ON ti.transaction_id = t.id
    WHERE m.deleted_at IS NULL
    AND date(t.created_at) = ?
    AND LOWER(COALESCE(c.name, m.category)) IN ('product', 'background')
    GROUP BY m.id, m.name, category
    ORDER BY total_qty DESC
    LIMIT 18
  ''', [today]);

    return result;
  }

  Future<List<Map<String, dynamic>>> getFavoriteProductsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await dbHelper.database;

    final result = await db.rawQuery('''
    SELECT 
      m.id,
      m.name,
      COALESCE(c.name, m.category) as category,
      SUM(ti.qty) as total_qty,
      SUM(ti.total_price) as total_sales
    FROM Data_Transaction_Item ti
    JOIN Data_Master m ON ti.master_data_id = m.id
    LEFT JOIN Data_Category c ON m.category_id = c.id
    JOIN Data_Transaction t ON ti.transaction_id = t.id
    WHERE m.deleted_at IS NULL
    AND t.created_at BETWEEN ? AND ?
    GROUP BY m.id, m.name, category
    ORDER BY total_qty DESC
    LIMIT 18
  ''', [
      startDate.toIso8601String(),
      endDate.add(const Duration(days: 1)).toIso8601String(),
    ]);

    return result;
  }

  Future<List<TransactionItem>> getTransactionItems(int transactionId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Transaction_Item',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    return result.map((map) => TransactionItem.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getItemDetails(int masterDataId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Master',
      where: 'id = ?',
      whereArgs: [masterDataId],
    );

    if (result.isNotEmpty) {
      return {
        'id': result.first['id'] ?? 0,
        'category': result.first['category'] ?? 'Produk',
        'name': result.first['name'] ?? 'Unknown Item',
        'price': result.first['price'] ?? 0
      };
    }

    return {'category': 'Produk', 'name': 'Item #$masterDataId', 'price': 0};
  }

  Future<List<DailyReport>> getDailyReportsByMonth(int year, int month) async {
    final db = await dbHelper.database;

    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final totalDays = lastDay.day;

    // Generate semua tanggal dalam bulan
    final allDates =
        List.generate(totalDays, (index) => DateTime(year, month, index + 1));

    // Query data transaksi yang ada
    final result = await db.rawQuery('''
    SELECT 
      date(t.created_at) as report_date,
      COUNT(DISTINCT t.customer_id) as customer_count,
      SUM(t.final_price) as total_revenue,
      SUM(CASE WHEN t.payment_method = 'cash' THEN t.final_price ELSE 0 END) as total_cash,
      SUM(CASE WHEN t.payment_method = 'qris' THEN t.final_price ELSE 0 END) as total_qris,
      COUNT(t.id) as total_sales
    FROM Data_Transaction t
    WHERE t.created_at BETWEEN ? AND ?
    GROUP BY date(t.created_at)
    ORDER BY report_date DESC
  ''', [
      firstDay.toIso8601String(),
      lastDay.add(const Duration(days: 1)).toIso8601String(),
    ]);

    // Buat map dari hasil query untuk akses cepat
    final resultMap = {
      for (var row in result) row['report_date'] as String: row
    };

    // Gabungkan semua tanggal dengan data yang ada
    return allDates.map((date) {
      final dateString =
          date.toIso8601String().split('T')[0]; // Format YYYY-MM-DD
      final rowData = resultMap[dateString];

      if (rowData != null) {
        // Jika ada data transaksi untuk tanggal ini
        return DailyReport(
          date: date,
          customerCount: rowData['customer_count'] as int? ?? 0,
          totalRevenue: (rowData['total_revenue'] as num?)?.toDouble() ?? 0,
          totalCash: (rowData['total_cash'] as num?)?.toDouble() ?? 0,
          totalQris: (rowData['total_qris'] as num?)?.toDouble() ?? 0,
          totalSales: (rowData['total_sales'] as num?)?.toDouble() ?? 0,
        );
      } else {
        // Jika tidak ada transaksi, return data default 0
        return DailyReport(
          date: date,
          customerCount: 0,
          totalRevenue: 0,
          totalCash: 0,
          totalQris: 0,
          totalSales: 0,
        );
      }
    }).toList();
  }

  Future<List<DailyReport>> getDailyReportsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await dbHelper.database;
    final firstDay = DateTime(startDate.year, startDate.month, startDate.day);
    final lastDay = DateTime(endDate.year, endDate.month, endDate.day);

    final totalDays = lastDay.difference(firstDay).inDays + 1;
    final allDates = List.generate(
        totalDays, (index) => firstDay.add(Duration(days: index)));

    final result = await db.rawQuery('''
    SELECT 
      date(t.created_at) as report_date,
      COUNT(DISTINCT t.customer_id) as customer_count,
      SUM(t.final_price) as total_revenue,
      SUM(CASE WHEN t.payment_method = 'cash' THEN t.final_price ELSE 0 END) as total_cash,
      SUM(CASE WHEN t.payment_method = 'qris' THEN t.final_price ELSE 0 END) as total_qris,
      COUNT(t.id) as total_sales
    FROM Data_Transaction t
    WHERE t.created_at BETWEEN ? AND ?
    GROUP BY date(t.created_at)
    ORDER BY report_date DESC
  ''', [
      firstDay.toIso8601String(),
      lastDay.add(const Duration(days: 1)).toIso8601String(),
    ]);

    final resultMap = {
      for (var row in result) row['report_date'] as String: row,
    };

    return allDates.map((date) {
      final dateString = date.toIso8601String().split('T')[0];
      final rowData = resultMap[dateString];

      if (rowData != null) {
        return DailyReport(
          date: date,
          customerCount: rowData['customer_count'] as int? ?? 0,
          totalRevenue: (rowData['total_revenue'] as num?)?.toDouble() ?? 0,
          totalCash: (rowData['total_cash'] as num?)?.toDouble() ?? 0,
          totalQris: (rowData['total_qris'] as num?)?.toDouble() ?? 0,
          totalSales: (rowData['total_sales'] as num?)?.toDouble() ?? 0,
        );
      }

      return DailyReport(
        date: date,
        customerCount: 0,
        totalRevenue: 0,
        totalCash: 0,
        totalQris: 0,
        totalSales: 0,
      );
    }).toList();
  }

  // Di TransactionRepository
  Future<List<Map<String, dynamic>>> getAvailableMonths() async {
    final db = await dbHelper.database;

    final result = await db.rawQuery('''
    SELECT 
      strftime('%Y', created_at) as year,
      strftime('%m', created_at) as month
    FROM Data_Transaction
    GROUP BY year, month
    ORDER BY year DESC, month DESC
  ''');

    // Convert ke format yang konsisten
    return result.map((row) {
      return {
        'year': row['year']?.toString() ?? '',
        'month': row['month']?.toString() ?? ''
      };
    }).toList();
  }

  // Di TransactionRepository class
  Future<int> getDailyTransactionCount(DateTime date) async {
    final db = await DatabaseHelper.instance.database;

    final formattedDate = date.toIso8601String().substring(0, 10);

    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM Data_Transaction WHERE DATE(created_at) = ?',
        [formattedDate]);

    return result.first['count'] as int? ?? 0;
  }

  Future<int> deleteTransaction(int transactionId, {int? actorUserId}) async {
    final db = await dbHelper.database;

    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      // Ambil nomor invoice untuk mencocokkan kas legacy (tanpa transaction_id).
      final txResult = await txn.query(
        'Data_Transaction',
        columns: ['invoice_number'],
        where: 'id = ?',
        whereArgs: [transactionId],
        limit: 1,
      );
      final invoiceNumber = txResult.isNotEmpty
          ? (txResult.first['invoice_number'] as String? ?? '')
          : '';

      // 1) Rollback kas tunai: hapus (soft delete) kas terkait transaksi ini,
      //    baik yang tercatat dengan transaction_id maupun legacy (hanya
      //    terhubung lewat nomor invoice di dalam deskripsi).
      await txn.update(
        'Data_Kas',
        {
          'deleted_at': now,
          'updated_at': now,
          'deleted_by': actorUserId,
        },
        where:
            'deleted_at IS NULL AND (transaction_id = ? OR description LIKE ?)',
        whereArgs: [transactionId, '%Invoice $invoiceNumber%'],
      );

      // 2) Rollback inventory: kembalikan stok yang dikurangi oleh transaksi.
      //    Prioritas dari Data_Inventory_Log (transaction_id tercatat sejak
      //    v13). Jika tidak ada log (transaksi lama), rekonstruksi dari item.
      final decrementLogs = await txn.query(
        'Data_Inventory_Log',
        where: 'transaction_id = ? AND type = ?',
        whereArgs: [transactionId, 'decrement'],
      );

      if (decrementLogs.isNotEmpty) {
        for (final log in decrementLogs) {
          final inventoryId = log['inventory_id'] as int?;
          final difference = log['difference'] as int? ?? 0;
          if (inventoryId == null || difference <= 0) continue;

          await _incrementInventoryAndLog(
            txn: txn,
            userId: actorUserId,
            inventoryId: inventoryId,
            qty: difference,
            now: now,
            transactionId: transactionId,
          );
        }
      } else {
        await _rollbackInventoryFromItems(
          txn: txn,
          transactionId: transactionId,
          userId: actorUserId,
          now: now,
        );
      }

      // Hapus transaction items terlebih dahulu (foreign key constraint)
      await txn.delete(
        'Data_Transaction_Item',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );

      // Hapus transaction
      return await txn.delete(
        'Data_Transaction',
        where: 'id = ?',
        whereArgs: [transactionId],
      );
    });
  }

  /// Memperbarui pesanan transaksi yang sudah ada.
  /// Strategi konsisten: (1) kembalikan stok untuk item lama (rollback),
  /// (2) hapus item lama, (3) simpan item baru, (4) kurangi stok untuk item
  /// baru, (5) perbarui transaksi (diskon/total/catatan), (6) selaraskan
  /// entri keuangan agar amount = total baru.
  Future<void> updateTransactionPesanan({
    required int transactionId,
    required int discountPrice,
    required int finalPrice,
    required List<Map<String, dynamic>> items,
    String? notes,
    int? actorUserId,
  }) async {
    final db = await dbHelper.database;

    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      // 1) Rollback inventory untuk item lama.
      await _rollbackInventoryFromItems(
        txn: txn,
        transactionId: transactionId,
        userId: actorUserId,
        now: now,
      );

      // 1b) Hapus log decrement lama agar deleteTransaction nanti tidak
      //     double-rollback (log lama sudah di-roll-back di atas, log baru
      //     akan dibuat saat re-decrement di bawah).
      await txn.delete(
        'Data_Inventory_Log',
        where: 'transaction_id = ? AND type = ?',
        whereArgs: [transactionId, 'decrement'],
      );

      // 2) Hapus item lama.
      await txn.delete(
        'Data_Transaction_Item',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );

      // 3) Simpan item baru.
      for (final item in items) {
        await txn.insert('Data_Transaction_Item', {
          'master_data_id': item['master_data_id'],
          'qty': item['qty'],
          'total_price': item['total_price'],
          'bundle_snapshot': item['bundle_snapshot'],
          'transaction_id': transactionId,
          'created_at': now,
          'updated_at': now,
        });
      }

      // 4) Kurangi stok untuk item baru.
      await _decrementInventoryFromItems(
        txn: txn,
        items: items,
        userId: actorUserId,
        transactionId: transactionId,
        now: now,
      );

      // 5) Perbarui transaksi.
      await txn.update(
        'Data_Transaction',
        {
          'discount_price': discountPrice,
          'final_price': finalPrice,
          if (notes != null) 'notes': notes,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      // 6) Selaraskan entri keuangan aktif terkait transaksi.
      await txn.update(
        'Data_Kas',
        {
          'amount': finalPrice,
          'updated_at': now,
        },
        where: 'deleted_at IS NULL AND transaction_id = ?',
        whereArgs: [transactionId],
      );
    });
  }

  Future<void> _decrementInventoryFromItems({
    required dynamic txn,
    required List<Map<String, dynamic>> items,
    required int? userId,
    required int? transactionId,
    required String now,
  }) async {
    for (final item in items) {
      final masterDataId = item['master_data_id'] as int?;
      final qty = item['qty'] as int? ?? 0;
      final bundleSnapshot = item['bundle_snapshot'] as String?;

      if (masterDataId == null || qty <= 0) {
        continue;
      }

      var bundleComponents = _parseBundleSnapshot(bundleSnapshot);
      if (bundleComponents.isEmpty) {
        bundleComponents = await _getBundleComponents(txn, masterDataId);
      }

      if (bundleComponents.isNotEmpty) {
        for (final component in bundleComponents) {
          final componentInventoryId =
              component['component_inventory_id'] as int?;
          if (componentInventoryId == null) continue;

          final componentQty = (component['qty'] as int? ?? 1) * qty;
          if (componentQty <= 0) continue;

          await _decrementInventoryByIdAndLog(
            txn: txn,
            userId: userId,
            inventoryId: componentInventoryId,
            qty: componentQty,
            transactionId: transactionId,
            now: now,
            notes: 'Pengurangan dari edit pesanan transaksi',
          );
        }
        continue;
      }

      final inventory = await txn.query(
        'Data_Inventory',
        where: 'master_data_id = ?',
        whereArgs: [masterDataId],
        limit: 1,
      );
      if (inventory.isEmpty) continue;

      await _decrementInventoryByIdAndLog(
        txn: txn,
        userId: userId,
        inventoryId: inventory.first['id'] as int,
        qty: qty,
        transactionId: transactionId,
        now: now,
        notes: 'Pengurangan dari edit pesanan transaksi',
      );
    }
  }

  Future<void> _decrementInventoryByIdAndLog({
    required dynamic txn,
    required int? userId,
    required int inventoryId,
    required int qty,
    int? transactionId,
    required String now,
    String? notes,
  }) async {
    final inventory = await txn.query(
      'Data_Inventory',
      where: 'id = ?',
      whereArgs: [inventoryId],
      limit: 1,
    );

    if (inventory.isEmpty) {
      return;
    }

    final initialStock = inventory.first['stock'] as int;
    final currentStock = initialStock - qty;

    await txn.update(
      'Data_Inventory',
      {
        'stock': currentStock,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [inventoryId],
    );

    await txn.insert('Data_Inventory_Log', {
      'inventory_id': inventoryId,
      'user_id': userId,
      'type': 'decrement',
      'initial_stock': initialStock,
      'current_stock': currentStock,
      'difference': qty,
      'transaction_id': transactionId,
      'notes': notes ?? 'Pengurangan dari edit pesanan transaksi',
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> _incrementInventoryAndLog({
    required dynamic txn,
    required int? userId,
    required int inventoryId,
    required int qty,
    required String now,
    int? transactionId,
  }) async {
    final inventory = await txn.query(
      'Data_Inventory',
      where: 'id = ?',
      whereArgs: [inventoryId],
      limit: 1,
    );

    if (inventory.isEmpty) {
      return;
    }

    final initialStock = inventory.first['stock'] as int;
    final currentStock = initialStock + qty;

    await txn.update(
      'Data_Inventory',
      {
        'stock': currentStock,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [inventoryId],
    );

    await txn.insert('Data_Inventory_Log', {
      'inventory_id': inventoryId,
      'user_id': userId,
      'type': 'increment',
      'initial_stock': initialStock,
      'current_stock': currentStock,
      'difference': qty,
      'transaction_id': transactionId,
      'notes': 'Rollback dari penghapusan transaksi',
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> _rollbackInventoryFromItems({
    required dynamic txn,
    required int transactionId,
    required int? userId,
    required String now,
  }) async {
    final items = await txn.query(
      'Data_Transaction_Item',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );

    for (final item in items) {
      final masterDataId = item['master_data_id'] as int?;
      final qty = item['qty'] as int? ?? 0;
      final bundleSnapshot = item['bundle_snapshot'] as String?;

      if (masterDataId == null || qty <= 0) {
        continue;
      }

      // Untuk bundle, stok dikembalikan per komponen bundle.
      var bundleComponents = _parseBundleSnapshot(bundleSnapshot);
      if (bundleComponents.isEmpty) {
        bundleComponents = await _getBundleComponents(txn, masterDataId);
      }

      if (bundleComponents.isNotEmpty) {
        for (final component in bundleComponents) {
          final componentInventoryId =
              component['component_inventory_id'] as int?;
          if (componentInventoryId == null) continue;

          final componentQty = (component['qty'] as int? ?? 1) * qty;
          if (componentQty <= 0) continue;

          await _incrementInventoryAndLog(
            txn: txn,
            userId: userId,
            inventoryId: componentInventoryId,
            qty: componentQty,
            now: now,
            transactionId: transactionId,
          );
        }
        continue;
      }

      // Bukan bundle: kembalikan stok inventory milik master data ini.
      final inventory = await txn.query(
        'Data_Inventory',
        where: 'master_data_id = ?',
        whereArgs: [masterDataId],
        limit: 1,
      );
      if (inventory.isEmpty) continue;

      await _incrementInventoryAndLog(
        txn: txn,
        userId: userId,
        inventoryId: inventory.first['id'] as int,
        qty: qty,
        now: now,
        transactionId: transactionId,
      );
    }
  }

  List<Map<String, dynamic>> _parseBundleSnapshot(String? snapshot) {
    if (snapshot == null || snapshot.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(snapshot);
      if (decoded is! List) {
        return [];
      }
      return decoded
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getBundleComponents(
      dynamic txn, int bundleId) async {
    return txn.rawQuery('''
      SELECT
        bi.component_inventory_id,
        bi.component_type,
        bi.qty
      FROM Data_Bundle_Item bi
      INNER JOIN Data_Inventory inv ON bi.component_inventory_id = inv.id
      WHERE bi.bundle_id = ?
        AND inv.deleted_at IS NULL
    ''', [bundleId]);
  }
}
