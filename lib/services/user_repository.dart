import '../models/user.dart';
import 'database_helper.dart';
import '../utils/password_hasher.dart';

class UserRepository {
  final DatabaseHelper dbHelper;

  UserRepository(this.dbHelper);

  Future<User?> authenticateUser(String email, String password) async {
    final db = await dbHelper.database;
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

  Future<int> insertUser(User user) async {
    final db = await dbHelper.database;
    return await db.insert('Data_User', user.toMap());
  }

  Future<List<User>> getAllUsers() async {
    final db = await dbHelper.database;
    final result = await db.query('Data_User');
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<User?> getUserById(int id) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_User',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? User.fromMap(result.first) : null;
  }

  Future<int> updateUser(User user) async {
    final db = await dbHelper.database;
    return await db.update(
      'Data_User',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'Data_User',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
