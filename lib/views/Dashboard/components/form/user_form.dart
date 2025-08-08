import 'package:flutter/material.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:meko_poin/utils/validators.dart';

class UserForm extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(Map<String, dynamic>) onSubmit;
  final Map<String, dynamic>? initialUserData;

  const UserForm({
    super.key,
    required this.onCancel,
    required this.onSubmit,
    this.initialUserData,
  });

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedRole;

  String? _nameError;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    if (widget.initialUserData != null) {
      _nameController.text = widget.initialUserData!['name'] ?? '';
      _emailController.text = widget.initialUserData!['email'] ?? '';
      _selectedRole = widget.initialUserData!['role'] ?? 'Operator';
    } else {
      _selectedRole = 'Operator';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _saveUser() async {
    // Validasi name
    final nameError = Validators.validateName(_nameController.text);
    setState(() {
      _nameError = nameError;
    });

    // Validasi email
    final emailError = await Validators.validateEmailInputUser(
      value: _emailController.text,
      currentUserId: widget.initialUserData?['id'],
    );

    setState(() {
      _emailError = emailError;
    });

    // Validasi password (hanya untuk user baru)
    if (widget.initialUserData == null) {
      final passwordError =
          Validators.validatePassword(_passwordController.text);
      setState(() {
        _passwordError = passwordError;
      });

      if (passwordError != null) {
        return;
      }
    } else {
      if (_passwordController.text.isNotEmpty) {
        final passwordError =
            Validators.validatePassword(_passwordController.text);
        setState(() {
          _passwordError = passwordError;
        });

        if (passwordError != null) {
          return;
        }
      }
    }

    if (emailError != null) {
      return;
    }

    final String name = _nameController.text;
    final String email = _emailController.text;
    final String password = _passwordController.text;
    final String role = _selectedRole ?? 'Operator';
    final int roleId = role == 'Admin' ? 1 : 2;

    final Map<String, dynamic> userData = {
      'name': name,
      'email': email,
      'password': password,
      'roleId': roleId,
    };

    widget.onSubmit(userData);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        border: Border.all(color: CustomColors.borderCardColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Input Nama
                  _buildFormLabel('Nama'),
                  const SizedBox(height: 8),
                  _buildTextField(_nameController, 'Masukkan Nama',
                      errorText: _nameError), // Tambahkan errorText
                  const SizedBox(height: 16),

                  // Input Email
                  _buildFormLabel('Email'),
                  const SizedBox(height: 8),
                  _buildTextField(_emailController, 'Masukkan email',
                      errorText: _emailError),
                  const SizedBox(height: 16),

                  _buildFormLabel('Password'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    _passwordController,
                    widget.initialUserData == null
                        ? 'Masukkan Password'
                        : 'Biarkan kosong jika tidak ingin mengubah',
                    obscureText: true,
                    errorText: _passwordError,
                  ),
                  const SizedBox(height: 16),

                  // Dropdown Role
                  _buildFormLabel('Role'),
                  const SizedBox(height: 8),
                  _buildDropdownRole(),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: CustomColors.cardColor,
              border: Border(
                top: BorderSide(
                  color: CustomColors.borderCardColor,
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: widget.onCancel,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: CustomColors.fontSubColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _saveUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1379F0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    widget.initialUserData != null ? 'Simpan' : 'Buat Baru',
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText,
      {bool obscureText = false, bool enabled = true, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            enabled: enabled,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                color: CustomColors.fontSubColor,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: errorText != null
                        ? Colors.red
                        : CustomColors.borderInputColor,
                    width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: errorText != null ? Colors.red : Color(0xFF1379F0),
                    width: 1.0),
              ),
              filled: true,
              fillColor: enabled
                  ? CustomColors.inputColor
                  : CustomColors.borderInputColor,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              errorText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownRole() {
    return SizedBox(
      height: 34,
      child: DropdownButtonFormField<String>(
        value: _selectedRole,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: CustomColors.borderInputColor, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1379F0), width: 1.0),
          ),
          filled: true,
          fillColor: CustomColors.inputColor,
        ),
        dropdownColor: CustomColors.inputColor,
        elevation: 2,
        icon: const Icon(Icons.keyboard_arrow_down,
            color: CustomColors.fontSubColor),
        iconSize: 20,
        isExpanded: true,
        items: <String>['Operator', 'Admin']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedRole = newValue;
          });
        },
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
      ),
    );
  }
}
