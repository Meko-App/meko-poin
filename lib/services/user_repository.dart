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

  Future<bool> isEmailUnique(String email, {int? currentUserId}) async {
    final db = await dbHelper.database;
    List<Map<String, dynamic>> result;
    if (currentUserId != null) {
      result = await db.query(
        'Data_User',
        where: 'email = ? AND id != ?',
        whereArgs: [email, currentUserId],
      );
    } else {
      result = await db.query(
        'Data_User',
        where: 'email = ?',
        whereArgs: [email],
      );
    }
    return result.isEmpty; // Jika kosong, berarti unik
  }

  Future<List<User>> getAllUsers({bool includeDeleted = false}) async {
    final db = await dbHelper.database;
    final where = includeDeleted ? null : 'deleted_at IS NULL';
    final result = await db.query('Data_User', where: where);
    return result.map((map) => User.fromMap(map)).toList();
  }

  // Soft delete a user
  Future<int> softDeleteUser(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'Data_User',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Restore a soft-deleted user
  Future<int> restoreUser(int id) async {
    final db = await dbHelper.database;
    return await db.update(
      'Data_User',
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
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

  Future<int> updateUserAvatar(int userId, String avatarPath) async {
    final db = await dbHelper.database;
    return await db.update(
      'Data_User',
      {'avatar_path': avatarPath},
      where: 'id = ?',
      whereArgs: [userId],
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

  Future<bool> verifyPassword(int userId, String password) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_User',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      final storedHashedPassword = result.first['password'] as String;
      return PasswordHasher.verifyPassword(password, storedHashedPassword);
    }
    return false;
  }
}
