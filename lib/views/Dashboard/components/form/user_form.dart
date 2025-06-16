// lib/views/Dashboard/components/form/user_form.dart
import 'package:flutter/material.dart';

class UserForm extends StatefulWidget {
  final VoidCallback onCancel;
  // Tambahkan properti opsional untuk mode edit dan data user
  final Map<String, dynamic>? initialUserData;

  const UserForm({
    super.key,
    required this.onCancel,
    this.initialUserData,
  });

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String?
      _selectedRole; // Menggunakan String? untuk menyimpan nilai yang dipilih

  @override
  void initState() {
    super.initState();
    if (widget.initialUserData != null) {
      // Mode edit: Isi form dengan data yang ada
      _nameController.text = widget.initialUserData!['name'] ?? '';
      _emailController.text = widget.initialUserData!['email'] ?? '';
      _selectedRole = widget.initialUserData!['role'] ??
          'Operator'; // Default ke Operator jika tidak ada
    } else {
      // Mode tambah baru: Otomatis pilih 'Operator'
      _selectedRole = 'Operator';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveUser() {
    // Implementasi logika penyimpanan data di sini
    // Anda bisa mendapatkan nilai dari:
    final String name = _nameController.text;
    final String email = _emailController.text;
    final String role =
        _selectedRole ?? 'Operator'; // Pastikan ada nilai default

    print('Nama: $name');
    print('Email: $email');
    print('Role: $role');

    // Setelah menyimpan, kembali ke halaman sebelumnya (tabel)
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
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
                  _buildTextField(_nameController, 'Masukkan Nama'),
                  const SizedBox(height: 16),

                  // Input Email
                  _buildFormLabel('Email'),
                  const SizedBox(height: 8),
                  _buildTextField(_emailController, 'Masukkan email'),
                  const SizedBox(height: 16),

                  // Dropdown Role
                  _buildFormLabel('Role'),
                  const SizedBox(height: 8),
                  _buildDropdownRole(),
                ],
              ),
            ),
          ),
          // --- Bagian Footer (Tombol Aksi) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // ElevatedButton(
                //   onPressed: widget.onCancel,
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.grey.shade200,
                //     padding: const EdgeInsets.symmetric(
                //         horizontal: 20, vertical: 12),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //   ),
                //   child: Text('Batal',
                //       style: TextStyle(color: Colors.grey.shade700)),
                // ),
                InkWell(
                  onTap: widget.onCancel,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: Color(0xFF4B5675),
                        fontWeight: FontWeight.w500, // Pertahankan FontWeight
                        fontSize: 12, // Sesuaikan font size jika perlu
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
        color: Color(0xFF111B37),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText) {
    return SizedBox(
      height: 34,
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontSize: 13,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          color: Color(0xFF111B37),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            color: Color(0xFF78829D),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1379F0), width: 1.0),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
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
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1379F0), width: 1.0),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        dropdownColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
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
                color: Color(0xFF111B37),
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
          color: Color(0xFF111B37),
        ),
      ),
    );
  }
}
