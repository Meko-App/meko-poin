import 'package:meko_poin/models/additional/kas_with_balance.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/models/kas.dart';

class KasRepository {
  final DatabaseHelper dbHelper;

  KasRepository(this.dbHelper);

  Future<int> insertKas(Kas kas) async {
    final db = await dbHelper.database;
    final dataToInsert = kas.toMap()
      ..addAll({
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

    return await db.insert('Data_Kas', dataToInsert);
  }

  Future<int> _variableBalance(String variable) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(
          CASE
            WHEN from_variable IS NOT NULL AND to_variable IS NOT NULL THEN
              CASE
                WHEN to_variable = ? THEN amount
                WHEN from_variable = ? THEN -amount
                ELSE 0
              END
            ELSE
              CASE
                WHEN variable = ? AND type = 'income' THEN amount
                WHEN variable = ? AND type = 'outcome' THEN -amount
                ELSE 0
              END
          END
        ) as total
      FROM Data_Kas
      WHERE deleted_at IS NULL
    ''', [variable, variable, variable, variable]);
    final totalValue = result.first['total'];
    return totalValue == null ? 0 : (totalValue as num).toInt();
  }

  Future<int> getTotalCash() => _variableBalance('cash');

  Future<int> getTotalSaldoVariable() => _variableBalance('saldo');

  Future<int> getTotalKeuangan() async {
    final cash = await getTotalCash();
    final saldo = await getTotalSaldoVariable();
    return cash + saldo;
  }

  /// Menjalankan transfer antar variabel keuangan.
  /// Membuat satu baris yang menyimpan metadata dari/ke; perhitungan saldo
  /// memperhitungkan pengurangan variabel asal dan penambahan variabel tujuan
  /// (total keuangan tidak berubah). Memvalidasi saldo variabel asal cukup.
  Future<void> transferKas({
    required int amount,
    required String description,
    required String fromVariable,
    required String toVariable,
    required DateTime cashDate,
    int? categoryId,
    int? userId,
  }) async {
    if (amount <= 0) {
      throw Exception('Nominal transfer harus lebih dari 0');
    }
    if (fromVariable == toVariable) {
      throw Exception('Dari dan Ke tidak boleh sama');
    }

    final available = await _variableBalance(fromVariable);
    if (available < amount) {
      throw Exception(
          'Saldo ${_variableLabel(fromVariable)} tidak mencukupi. Tersedia ${available.toString()}');
    }

    final db = await dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final dateOnly = cashDate.toIso8601String().split('T')[0];

    await db.insert('Data_Kas', {
      'amount': amount,
      'description': description,
      'type': 'outcome',
      'cash_date': dateOnly,
      'variable': fromVariable,
      'category_id': categoryId,
      'from_variable': fromVariable,
      'to_variable': toVariable,
      'created_by': userId,
      'created_at': now,
      'updated_at': now,
    });
  }

  String _variableLabel(String variable) {
    return variable == 'cash' ? 'Cash' : 'Saldo';
  }

  Future<List<String>> getKasDescriptionSuggestions(String query) async {
    final db = await dbHelper.database;
    if (query.trim().isEmpty) {
      return const [];
    }
    final result = await db.rawQuery('''
      SELECT DISTINCT description FROM Data_Kas
      WHERE deleted_at IS NULL AND description LIKE ?
      ORDER BY description ASC
      LIMIT 20
    ''', ['%$query%']);
    return result.map((row) => row['description'] as String).toList();
  }

  Future<List<Kas>> getAllKas() async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Kas',
      where: 'deleted_at IS NULL',
    );
    return result.map((map) => Kas.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getKasSummaryByMonth({
    int? year,
    int? month,
  }) async {
    final db = await dbHelper.database;

    String whereClause = 'deleted_at IS NULL';
    List<dynamic> whereArgs = [];

    if (year != null) {
      whereClause += ' AND strftime("%Y", cash_date) = ?';
      whereArgs.add(year.toString());
    }

    if (month != null) {
      whereClause += ' AND strftime("%m", cash_date) = ?';
      whereArgs.add(month.toString().padLeft(2, '0'));
    } else if (year == null) {
      // Default to current year if no year/month specified
      final currentYear = DateTime.now().year;
      whereClause += ' AND strftime("%Y", cash_date) = ?';
      whereArgs.add(currentYear.toString());
    }

    final result = await db.rawQuery('''
      SELECT 
        strftime('%m', cash_date) as month,
        strftime('%Y', cash_date) as year,
        SUM(CASE WHEN type = 'income' AND from_variable IS NULL THEN amount ELSE 0 END) as total_income,
        SUM(CASE WHEN type = 'outcome' AND from_variable IS NULL THEN amount ELSE 0 END) as total_outcome,
        SUM(CASE WHEN type = 'income' AND from_variable IS NULL THEN amount WHEN type = 'outcome' AND from_variable IS NULL THEN -amount ELSE 0 END) as net_amount
      FROM Data_Kas
      WHERE $whereClause
      GROUP BY strftime('%Y-%m', cash_date)
      ORDER BY year DESC, month DESC
    ''', whereArgs);

    final List<Map<String, dynamic>> summaryList = [];

    for (var row in result) {
      final int month = int.parse(row['month'] as String);
      final int year = int.parse(row['year'] as String);

      // Dapatkan saldo awal bulan
      final int saldoAwal = await _getSaldoAwalBulan(year, month);
      final int netAmount = row['net_amount'] as int? ?? 0;
      final int netAmountWithSaldo = netAmount + saldoAwal;

      summaryList.add({
        'month': month,
        'year': year,
        'total_income': row['total_income'] as int? ?? 0,
        'total_outcome': row['total_outcome'] as int? ?? 0,
        'net_amount': netAmount,
        'saldo_awal': saldoAwal,
        'net_amount_with_saldo': netAmountWithSaldo,
      });
    }

    return summaryList;
  }

  Future<List<KasWithBalance>> getKasByMonth(int year, int month) async {
    final db = await dbHelper.database;

    // Pertama, dapatkan saldo awal bulan (saldo akhir bulan sebelumnya)
    final saldoAwalBulan = await _getSaldoAwalBulan(year, month);

    final result = await db.rawQuery('''
    SELECT * FROM Data_Kas 
    WHERE strftime('%Y', cash_date) = ? 
    AND strftime('%m', cash_date) = ?
    AND deleted_at IS NULL
    ORDER BY date(cash_date) ASC, id ASC
  ''', [year.toString(), month.toString().padLeft(2, '0')]);

    int runningBalance = saldoAwalBulan;
    final List<KasWithBalance> kasList = [];

    for (var map in result) {
      final kas = Kas.fromMap(map);
      final int initialBalance = runningBalance;

      // Baris transfer bersifat netral untuk saldo gabungan
      // (kurang di variabel asal, tambah di variabel tujuan).
      if (kas.fromVariable == null && kas.toVariable == null) {
        if (kas.type == 'income') {
          runningBalance += kas.amount;
        } else {
          runningBalance -= kas.amount;
        }
      }

      kasList.add(KasWithBalance(
        kas: kas,
        initialBalance: initialBalance,
        finalBalance: runningBalance,
      ));
    }

    kasList.sort((a, b) {
      final dateCompare = b.kas.createdAt!.compareTo(a.kas.createdAt!);
      if (dateCompare != 0) return dateCompare;
      return b.kas.id!.compareTo(a.kas.id!);
    });

    return kasList;
  }

  Future<int> _getSaldoAwalBulan(int year, int month) async {
    final db = await dbHelper.database;

    // Hitung saldo sampai akhir bulan sebelumnya (transfer bersifat netral).
    final result = await db.rawQuery('''
    SELECT 
      SUM(CASE WHEN type = 'income' AND from_variable IS NULL THEN amount WHEN type = 'outcome' AND from_variable IS NULL THEN -amount ELSE 0 END) as total_saldo
    FROM Data_Kas 
    WHERE 
      (strftime('%Y', cash_date) < ? OR 
       (strftime('%Y', cash_date) = ? AND strftime('%m', cash_date) < ?))
    AND deleted_at IS NULL
  ''', [year.toString(), year.toString(), month.toString().padLeft(2, '0')]);

    final totalSaldo = result.first['total_saldo'] as int? ?? 0;

    return totalSaldo;
  }

  Future<List<int>> getAvailableYears() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
      SELECT DISTINCT strftime('%Y', cash_date) as year 
      FROM Data_Kas 
      WHERE deleted_at IS NULL 
      ORDER BY year DESC
    ''');

    return result.map((row) => int.parse(row['year'] as String)).toList();
  }

  Future<List<int>> getAvailableMonths(int year) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('''
    SELECT DISTINCT strftime('%m', cash_date) as month 
    FROM Data_Kas 
    WHERE strftime('%Y', cash_date) = ?
    AND deleted_at IS NULL 
    ORDER BY month DESC
  ''', [year.toString()]);

    return result.map((row) => int.parse(row['month'] as String)).toList();
  }

  Future<double> getTotalSaldo() async {
    try {
      final db = await dbHelper.database;
      final result = await db.rawQuery('''
        SELECT 
          SUM(CASE WHEN type = 'income' AND from_variable IS NULL THEN amount WHEN type = 'outcome' AND from_variable IS NULL THEN -amount ELSE 0 END) as total
        FROM Data_Kas
        WHERE deleted_at IS NULL
      ''');

      final totalValue = result.first['total'];

      if (totalValue == null) {
        return 0.0;
      }
      return (totalValue as num).toDouble();
    } catch (e) {
      print('Error getting total saldo: $e');
      return 0.0;
    }
  }

  Future<double> getTotalSaldoBulanan(int year, int month) async {
    try {
      final db = await dbHelper.database;
      final result = await db.rawQuery('''
        SELECT 
          SUM(CASE WHEN type = 'income' AND from_variable IS NULL THEN amount WHEN type = 'outcome' AND from_variable IS NULL THEN -amount ELSE 0 END) as total
        FROM Data_Kas
        WHERE 
          (strftime('%Y', cash_date) < ? OR 
          (strftime('%Y', cash_date) = ? AND strftime('%m', cash_date) <= ?))
        AND deleted_at IS NULL
      ''',
          [year.toString(), year.toString(), month.toString().padLeft(2, '0')]);

      final totalValue = result.first['total'];

      if (totalValue == null) {
        return 0.0;
      }

      return (totalValue as num).toDouble();
    } catch (e) {
      print('Error getting total saldo: $e');
      return 0.0;
    }
  }

  Future<int> updateKas(Kas kas) async {
    final db = await dbHelper.database;
    final data = kas.toMap()
      ..remove('created_at')
      ..['updated_at'] = DateTime.now().toIso8601String();

    return await db.update(
      'Data_Kas',
      data,
      where: 'id = ?',
      whereArgs: [kas.id],
    );
  }

  Future<int> softDeleteKas(int id, {int? deletedBy}) async {
    final db = await dbHelper.database;
    return await db.update(
      'Data_Kas',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'deleted_by': deletedBy,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> restoreKas(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'Data_Kas',
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Kas?> getKasById(int id) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Kas',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? Kas.fromMap(result.first) : null;
  }

  Future<int> deleteKas(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'Data_Kas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
