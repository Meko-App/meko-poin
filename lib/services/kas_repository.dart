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

  Future<List<Kas>> getAllKas() async {
    final db = await dbHelper.database;
    final result = await db.query('Data_Kas');
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
        SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as total_income,
        SUM(CASE WHEN type = 'outcome' THEN amount ELSE 0 END) as total_outcome,
        SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END) as net_amount
      FROM Data_Kas
      WHERE $whereClause
      GROUP BY strftime('%Y-%m', cash_date)
      ORDER BY year DESC, month DESC
    ''', whereArgs);

    return result.map((row) {
      return {
        'month': int.parse(row['month'] as String),
        'year': int.parse(row['year'] as String),
        'total_income': row['total_income'] as int? ?? 0,
        'total_outcome': row['total_outcome'] as int? ?? 0,
        'net_amount': row['net_amount'] as int? ?? 0,
      };
    }).toList();
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
    ORDER BY cash_date ASC, created_at ASC
  ''', [year.toString(), month.toString().padLeft(2, '0')]);

    int runningBalance = saldoAwalBulan;
    final List<KasWithBalance> kasList = [];

    for (var map in result) {
      final kas = Kas.fromMap(map);
      final int initialBalance = runningBalance;

      if (kas.type == 'income') {
        runningBalance += kas.amount;
      } else {
        runningBalance -= kas.amount;
      }

      kasList.add(KasWithBalance(
        kas: kas,
        initialBalance: initialBalance,
        finalBalance: runningBalance,
      ));
    }

    return kasList;
  }

  Future<int> _getSaldoAwalBulan(int year, int month) async {
    final db = await dbHelper.database;

    // Hitung saldo sampai akhir bulan sebelumnya
    final result = await db.rawQuery('''
    SELECT 
      SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END) as total_saldo
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
          SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END) as total
        FROM Data_Kas
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
          SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END) as total
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

  Future<int> softDeleteKas(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'Data_Kas',
      {'deleted_at': DateTime.now().toIso8601String()},
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
