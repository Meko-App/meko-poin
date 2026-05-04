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
        version: 6,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      ),
    );

    // final tables =
    //     await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    // print("Tabel yang tersedia: $tables");

    return db;
  }

  Future<void> _createDB(Database db, int version) async {
    await _createUserTable(db);
    await _createCategoryTable(db);
    await _createMasterDataTable(db);
    await _createInventoryTable(db);
    await _createInventoryLogTable(db);
    await _createCustomerTable(db);
    await _createTransactionTable(db);
    await _createTransactionPaymentMethodHistoryTable(db);
    await _createTransactionItemTable(db);
    await _createKasTable(db);
    await _createBundleItemTable(db);
    await _seedDefaultCategories(db);
    await _insertDefaultAdmin(db);
    await _insertDummyDataMaster(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createCategoryTable(db);
      await _seedDefaultCategories(db);
      await _migrateMasterDataCategoryRelation(db);
    }

    if (oldVersion < 3) {
      await _createBundleItemTable(db);
      await _seedDefaultCategories(db);
    }

    if (oldVersion < 4) {
      await _addColumnIfNotExists(
        db,
        'Data_Transaction_Item',
        'bundle_id',
        'INTEGER',
      );
      await _addColumnIfNotExists(
        db,
        'Data_Transaction_Item',
        'bundle_snapshot',
        'TEXT',
      );
    }

    if (oldVersion < 5) {
      await _migrateBundleItemComponentTypeToFlexible(db);
    }

    if (oldVersion < 6) {
      await _createTransactionPaymentMethodHistoryTable(db);
    }
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

  Future<void> _createCategoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Data_Category (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        code TEXT NOT NULL UNIQUE,
        is_bundle INTEGER DEFAULT 0,
        is_countable INTEGER DEFAULT 0,
        created_at DATETIME,
        updated_at DATETIME,
        deleted_at TEXT
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_data_category_code ON Data_Category(code)');
  }

  Future<void> _createMasterDataTable(Database db) async {
    await db.execute('''
      CREATE TABLE Data_Master (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        category_id INTEGER,
        packaging_id INTEGER,
        name TEXT,
        category TEXT,
        price INTEGER,
        created_at DATETIME,
        updated_at DATETIME,
        deleted_at TEXT,
        FOREIGN KEY (user_id) REFERENCES Data_User(id),
        FOREIGN KEY (category_id) REFERENCES Data_Category(id)
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_data_master_category_id ON Data_Master(category_id)');
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

  Future<void> _createTransactionPaymentMethodHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Data_Transaction_Payment_Method_History (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        actor_user_id INTEGER,
        previous_payment_method TEXT CHECK(previous_payment_method IN ('cash', 'qris')),
        updated_payment_method TEXT CHECK(updated_payment_method IN ('cash', 'qris')),
        changed_at DATETIME,
        created_at DATETIME,
        FOREIGN KEY (transaction_id) REFERENCES Data_Transaction(id),
        FOREIGN KEY (actor_user_id) REFERENCES Data_User(id)
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_payment_history_transaction_changed_at
      ON Data_Transaction_Payment_Method_History(transaction_id, changed_at DESC)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_payment_history_actor_user
      ON Data_Transaction_Payment_Method_History(actor_user_id)
    ''');
  }

  Future<void> _createTransactionItemTable(Database db) async {
    await db.execute('''
      CREATE TABLE Data_Transaction_Item (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        master_data_id INTEGER,
        bundle_id INTEGER,
        bundle_snapshot TEXT,
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

  Future<void> _createBundleItemTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Data_Bundle_Item (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bundle_id INTEGER NOT NULL,
        component_master_data_id INTEGER NOT NULL,
        component_type TEXT NOT NULL,
        qty INTEGER NOT NULL DEFAULT 1,
        created_at DATETIME,
        updated_at DATETIME,
        FOREIGN KEY (bundle_id) REFERENCES Data_Master(id),
        FOREIGN KEY (component_master_data_id) REFERENCES Data_Master(id),
        UNIQUE(bundle_id, component_type)
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_bundle_item_bundle_id ON Data_Bundle_Item(bundle_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_bundle_item_component_id ON Data_Bundle_Item(component_master_data_id)');
  }

  Future<void> _migrateBundleItemComponentTypeToFlexible(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS Data_Bundle_Item_v2 (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          bundle_id INTEGER NOT NULL,
          component_master_data_id INTEGER NOT NULL,
          component_type TEXT NOT NULL,
          qty INTEGER NOT NULL DEFAULT 1,
          created_at DATETIME,
          updated_at DATETIME,
          FOREIGN KEY (bundle_id) REFERENCES Data_Master(id),
          FOREIGN KEY (component_master_data_id) REFERENCES Data_Master(id),
          UNIQUE(bundle_id, component_type)
        )
      ''');

      await txn.execute('''
        INSERT INTO Data_Bundle_Item_v2 (
          id,
          bundle_id,
          component_master_data_id,
          component_type,
          qty,
          created_at,
          updated_at
        )
        SELECT
          id,
          bundle_id,
          component_master_data_id,
          component_type,
          qty,
          created_at,
          updated_at
        FROM Data_Bundle_Item
      ''');

      await txn.execute('DROP TABLE Data_Bundle_Item');
      await txn.execute(
        'ALTER TABLE Data_Bundle_Item_v2 RENAME TO Data_Bundle_Item',
      );
      await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_bundle_item_bundle_id ON Data_Bundle_Item(bundle_id)');
      await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_bundle_item_component_id ON Data_Bundle_Item(component_master_data_id)');
    });
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final categories = [
      {
        'name': 'Product',
        'code': 'product',
        'is_bundle': 0,
        'is_countable': 0,
      },
      {
        'name': 'Paper',
        'code': 'paper',
        'is_bundle': 0,
        'is_countable': 1,
      },
      {
        'name': 'Packaging',
        'code': 'packaging',
        'is_bundle': 0,
        'is_countable': 1,
      },
      {
        'name': 'Additional',
        'code': 'additional',
        'is_bundle': 0,
        'is_countable': 0,
      },
      {
        'name': 'Background',
        'code': 'background',
        'is_bundle': 0,
        'is_countable': 0,
      },
      {
        'name': 'Bundling',
        'code': 'bundling',
        'is_bundle': 1,
        'is_countable': 0,
      },
      {
        'name': 'Frame',
        'code': 'frame',
        'is_bundle': 0,
        'is_countable': 0,
      },
      {
        'name': 'Service',
        'code': 'service',
        'is_bundle': 0,
        'is_countable': 0,
      },
      {
        'name': 'Property',
        'code': 'property',
        'is_bundle': 0,
        'is_countable': 1,
      },
    ];

    for (final category in categories) {
      await db.insert(
        'Data_Category',
        {
          ...category,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<bool> _columnExists(Database db, String table, String column) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    return info.any((row) => row['name'] == column);
  }

  Future<void> _addColumnIfNotExists(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final exists = await _columnExists(db, table, column);
    if (!exists) {
      await db.execute(
        'ALTER TABLE $table ADD COLUMN $column $definition',
      );
    }
  }

  Future<void> _migrateMasterDataCategoryRelation(Database db) async {
    final hasCategoryId = await _columnExists(db, 'Data_Master', 'category_id');
    if (!hasCategoryId) {
      await db
          .execute('ALTER TABLE Data_Master ADD COLUMN category_id INTEGER');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_data_master_category_id ON Data_Master(category_id)');
    }

    final categories = await db.query('Data_Category');
    for (final category in categories) {
      final categoryName = category['name'] as String;
      final categoryId = category['id'] as int;
      await db.update(
        'Data_Master',
        {'category_id': categoryId},
        where: 'category_id IS NULL AND LOWER(category) = ?',
        whereArgs: [categoryName.toLowerCase()],
      );
    }

    final additionalCategory = await db.query(
      'Data_Category',
      where: 'code = ?',
      whereArgs: ['additional'],
      limit: 1,
    );

    if (additionalCategory.isNotEmpty) {
      final additionalId = additionalCategory.first['id'] as int;
      await db.update(
        'Data_Master',
        {
          'category_id': additionalId,
          'category': 'Additional',
        },
        where: 'category_id IS NULL',
      );
    }
  }

  Future<int?> _getCategoryIdByCode(Database db, String code) async {
    final result = await db.query(
      'Data_Category',
      columns: ['id'],
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first['id'] as int;
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
    final productCategoryId = await _getCategoryIdByCode(db, 'product') ?? 1;

    await db.insert('Data_Master', {
      'user_id': 1,
      'category_id': productCategoryId,
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
