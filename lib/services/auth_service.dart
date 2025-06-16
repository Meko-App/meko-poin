// services/auth_service.dart
import '../models/user.dart';
import 'database_helper.dart';
import 'user_repository.dart';

class AuthService {
  final UserRepository _userRepository;

  AuthService() : _userRepository = UserRepository(DatabaseHelper.instance);

  Future<User?> login(String email, String password) async {
    return await _userRepository.authenticateUser(email, password);
  }

  Future<void> logout() async {
    // Additional cleanup if needed
    await DatabaseHelper.instance.close();
  }
}
