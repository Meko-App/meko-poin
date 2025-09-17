import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../utils/password_hasher.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    sqfliteFfiInit();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createDB,
      ),
    );

    // final tables =
    //     await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    // print("Tabel yang tersedia: $tables");

    return db;
  }

  Future<void> _createDB(Database db, int version) async {
    await _createUserTable(db);
    await _createMasterDataTable(db);
    await _createInventoryTable(db);
    await _createInventoryLogTable(db);
    await _createCustomerTable(db);
    await _createTransactionTable(db);
    await _createTransactionItemTable(db);
    await _createKasTable(db);
    await _insertDefaultAdmin(db);
    await _insertDummyDataMaster(db);
  }

  Future<void> _createUserTable(Database db) async {
    await db.execute('''
      CREATE TABLE Data_User (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT,
        role_id INTEGER,
        avatar_path TEXT,
        deleted_at TEXT
      )
    ''');
  }

  Future<void> _createMasterDataTable(Database db) async {
    await db.execute('''
      CREATE TABLE Data_Master (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        packaging_id INTEGER,
        name TEXT,
        category TEXT CHECK(category IN ('Product', 'Paper', 'Packaging', 'Additional', 'Background')),
        price INTEGER,
        created_at DATETIME,
        updated_at DATETIME,
        deleted_at TEXT,
        FOREIGN KEY (user_id) REFERENCES Data_User(id)
      )
    ''');
  }

  Future<void> _createInventoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE Data_Inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        master_data_id INTEGER,
        stock INTEGER,
        stock_reject INTEGER,
        notes TEXT,
        created_at DATETIME,
        updated_at DATETIME,
        deleted_at TEXT,
        FOREIGN KEY (user_id) REFERENCES Data_User(id),
        FOREIGN KEY (master_data_id) REFERENCES Data_Master(id)
      )
    ''');
  }

  Future<void> _createInventoryLogTable(Database db) async {
    await db.execute('''
      CREATE TABLE Data_Inventory_Log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inventory_id INTEGER,
        user_id INTEGER,
        type TEXT CHECK(type IN ('increment', 'decrement')),
        initial_stock INTEGER,
        current_stock INTEGER,
        notes TEXT,
        difference INTEGER,
        created_at DATETIME,
        updated_at DATETIME,
        FOREIGN KEY (inventory_id) REFERENCES Data_Inventory(id),
        FOREIGN KEY (user_id) REFERENCES Data_User(id)
      )
    ''');
  }

  Future<void> _createCustomerTable(Database db) async {
    await db.execute('''
      CREATE TABLE Data_Customer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT,
        phone TEXT,
        created_at DATETIME,
        updated_at DATETIME,
        FOREIGN KEY (user_id) REFERENCES Data_User(id)
      )
    ''');
  }

  Future<void> _createTransactionTable(Database db) async {
    await db.execute('''
      CREATE TABLE Data_Transaction (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        customer_id INTEGER,
        discount_price INTEGER,
        discount_percentage INTEGER,
        final_price INTEGER,
        invoice_number TEXT,
        payment_method TEXT CHECK(payment_method IN ('cash', 'qris')),
        notes TEXT,
        created_at DATETIME,
        updated_at DATETIME,
        FOREIGN KEY (user_id) REFERENCES Data_User(id),
        FOREIGN KEY (customer_id) REFERENCES Data_Customer(id)
      )
    ''');
  }

  Future<void> _createTransactionItemTable(Database db) async {
    await db.execute('''
      CREATE TABLE Data_Transaction_Item (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        master_data_id INTEGER,
        qty INTEGER,
        total_price INTEGER,
        created_at DATETIME,
        updated_at DATETIME,
        transaction_id INTEGER,
        FOREIGN KEY (master_data_id) REFERENCES Data_Master(id),
        FOREIGN KEY (transaction_id) REFERENCES Data_Transaction(id)
      )
    ''');
  }

  Future<void> _createKasTable(Database db) async {
    await db.execute('''
      CREATE TABLE Data_Kas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount INTEGER,
        description TEXT,
        type TEXT CHECK(type IN ('income', 'outcome')),
        cash_date DATE,
        created_at DATETIME,
        updated_at DATETIME,
        deleted_at TEXT,
        created_by INTEGER,
        updated_by INTEGER,
        deleted_by INTEGER
      )
    ''');
  }

  Future<void> _insertDefaultAdmin(Database db) async {
    await db.insert('Data_User', {
      'name': 'Admin',
      'email': 'admin@example.com',
      'password': PasswordHasher.hashPassword('admin123'),
      'avatar_path': 'assets/user.png',
      'role_id': 1,
    });
  }

  Future<void> _insertDummyDataMaster(Database db) async {
    await db.insert('Data_Master', {
      'user_id': 1,
      'packaging_id': 0,
      'name': 'Produk Dummy',
      'category': 'Product',
      'price': 15000,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }

  authenticateUser(String email, String password) {}

  Future<void> backupDatabase(BuildContext context) async {
    try {
      final dbPath = await getDatabasesPath();
      final srcFile = File('$dbPath/app_database.db');

      if (!await srcFile.exists()) {
        throw Exception('File database tidak ditemukan');
      }

      // Gunakan waktu sekarang
      final now = DateTime.now();

      // Buka file manager
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Backup Database',
        fileName:
            'backup_database_meko_poin_${DateFormat('yyyyMMdd').format(now)}.db',
        allowedExtensions: ['db'],
        type: FileType.custom,
      );

      if (outputFile == null) return;

      if (!outputFile.endsWith('.db')) {
        outputFile += '.db';
      }

      // Salin file
      final destFile = File(outputFile);
      await srcFile.copy(destFile.path);

      // Set timestamp ke waktu sekarang
      await destFile.setLastModified(now);
      await destFile.setLastAccessed(now);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Backup berhasil dibuat (${DateFormat('dd/MM/yyyy HH:mm').format(now)})'),
            action: SnackBarAction(
              label: 'Buka',
              onPressed: () => OpenFile.open(destFile.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat backup: $e')),
        );
      }
    }
  }

  Future<void> restoreDatabase(BuildContext context) async {
    try {
      // Buka file manager untuk memilih file backup
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        dialogTitle: 'Pilih File Backup Database',
      );

      if (result == null) return; // User membatalkan

      final db = await instance.database;
      final dbPath = await getDatabasesPath();
      final destFile = File('$dbPath/app_database.db');

      // Tutup database sebelum restore
      await db.close();
      _database = null;

      // Salin file backup
      final backupFile = File(result.files.single.path!);
      await backupFile.copy(destFile.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database berhasil dipulihkan')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memulihkan database: $e')),
        );
      }
    }
  }
}
