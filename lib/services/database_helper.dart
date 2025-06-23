// services/database_helper.dart
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
        deleted_at TEXT
      )
    ''');
  }

  Future<void> _createMasterDataTable(Database db) async {
    await db.execute('''
      CREATE TABLE Data_Master (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT,
        category TEXT CHECK(category IN ('Product', 'Paper', 'Packaging', 'Additional')),
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
        notes TEXT,
        created_at DATETIME,
        updated_at DATETIME,
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
        payment_method TEXT CHECK(payment_method IN ('cash', 'gris')),
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

  Future<void> _insertDefaultAdmin(Database db) async {
    await db.insert('Data_User', {
      'name': 'Admin',
      'email': 'admin@example.com',
      'password': PasswordHasher.hashPassword('admin123'),
      'role_id': 1,
    });
  }

  Future<void> _insertDummyDataMaster(Database db) async {
    await db.insert('Data_Master', {
      'user_id': 1,
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
}
