import 'package:flutter/material.dart';
import 'package:meko_poin/services/customer_repository.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/inventory_log_repository.dart';
import 'package:meko_poin/services/inventory_repository.dart';
import 'package:meko_poin/services/master_data_repository.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:meko_poin/services/user_repository.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../utils/custom_colors.dart';
import '../Dashboard/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null && mounted) {
        final initialMenu = user.roleId == 1 ? 'Ringkasan' : 'Transaksi';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => DashboardPage(
                  user: user,
                  initialMenu: initialMenu,
                  userRepository: UserRepository(DatabaseHelper.instance),
                  transactionRepository:
                      TransactionRepository(DatabaseHelper.instance),
                  masterDataRepository:
                      MasterDataRepository(DatabaseHelper.instance),
                  inventoryRepository:
                      InventoryRepository(DatabaseHelper.instance),
                  inventoryLogRepository:
                      InventoryLogRepository(DatabaseHelper.instance),
                  customerRepository:
                      CustomerRepository(DatabaseHelper.instance))),
        );
      } else if (mounted) {
        _showError('Invalid email or password');
      }
    } catch (e) {
      if (mounted) {
        _showError('Login failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: CustomColors.cardColor,
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  "assets/background.png"), // ganti dengan path gambar kamu
              fit: BoxFit.cover, // atau BoxFit.fill sesuai kebutuhan
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(58.0),
                decoration: BoxDecoration(
                  color: CustomColors.cardColor,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: CustomColors.borderCardColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Sign in',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32.0),
                      Text(
                        'Email',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'email@email.com',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                          filled: true,
                          fillColor: CustomColors.inputColor,
                          border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0)),
                            borderSide: BorderSide(
                                color: CustomColors.borderInputColor),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0)),
                            borderSide: BorderSide(
                                color: CustomColors.borderInputColor),
                          ),
                          focusedBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8.0)),
                              borderSide: BorderSide(color: Colors.grey)),
                          errorBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0)),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        validator: Validators.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20.0),
                      Text(
                        'Password',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter Password',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                          filled: true,
                          fillColor: CustomColors.inputColor,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0)),
                            borderSide: BorderSide(
                                color: CustomColors.borderInputColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0)),
                            borderSide: BorderSide(
                                color: CustomColors.borderInputColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8.0)),
                              borderSide: BorderSide(color: Colors.grey)),
                          errorBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0)),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                        validator: Validators.validatePassword,
                      ),
                      const SizedBox(height: 30.0),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 60, 122, 255),
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
