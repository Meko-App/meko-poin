import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Add this import
import '../models/user.dart';
import '../utils/password_hasher.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Initialize FFI if needed
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      singleInstance: true,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Data_User (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT,
        role_id INTEGER
      )
    ''');

    // Insert initial admin user with hashed password
    await db.insert('Data_User', {
      'name': 'Admin',
      'email': 'admin@example.com',
      'password': PasswordHasher.hashPassword('admin123'),
      'role_id': 1
    });
  }

  Future<User?> authenticateUser(String email, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'Data_User',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isNotEmpty) {
      final storedHashedPassword = result.first['password'] as String;
      if (PasswordHasher.verifyPassword(password, storedHashedPassword)) {
        return User.fromMap(result.first);
      }
    }
    return null;
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
