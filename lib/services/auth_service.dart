import '../models/user.dart';
import 'database_helper.dart';

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<User?> login(String email, String password) async {
    return await _dbHelper.authenticateUser(email, password);
  }

  Future<void> logout() async {
    // Additional cleanup if needed
    await _dbHelper.close();
  }
}
