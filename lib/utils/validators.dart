import 'package:meko_poin/services/user_repository.dart';

class Validators {
  static late UserRepository _userRepository;

  static void initialize(UserRepository repository) {
    _userRepository = repository;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama wajib diisi';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    final cleaned = (value ?? '').replaceAll('.', '');

    if (cleaned.isEmpty) return null;

    if (int.tryParse(cleaned) == null) {
      return 'Harga harus berupa angka';
    }

    return null;
  }

  static Future<String?> validateEmailInputUser({
    String? value,
    int? currentUserId,
  }) async {
    if (value == null || value.isEmpty) {
      return 'Email wajib diisi';
    }

    final emailRegex = RegExp(
        r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$');
    if (!emailRegex.hasMatch(value)) {
      return 'Masukkan format email yang valid';
    }

    final isUnique = await _userRepository.isEmailUnique(value,
        currentUserId: currentUserId);
    if (!isUnique) {
      return 'Email ini sudah terdaftar';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }
}
