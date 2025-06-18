import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'database_helper.dart';
import 'user_repository.dart';

class AuthService {
  final UserRepository _userRepository;

  AuthService() : _userRepository = UserRepository(DatabaseHelper.instance);

  Future<User?> login(String email, String password) async {
    User? user = await _userRepository.authenticateUser(email, password);
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', user.id!);
    }
    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await DatabaseHelper.instance.close();
  }
}
