import 'package:flutter/material.dart';
import 'package:meko_poin/views/Dashboard/components/table/user_table/user_table.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/pengguna_content_state.dart';
import 'package:meko_poin/views/Dashboard/components/form/user_form.dart';

class PenggunaContent extends StatefulWidget {
  final Function(PenggunaContentState) onStateChanged;

  const PenggunaContent({super.key, required this.onStateChanged});

  @override
  State<PenggunaContent> createState() => _PenggunaContentState();
}

class _PenggunaContentState extends State<PenggunaContent> {
  PenggunaContentState _currentState = PenggunaContentState.table;
  Map<String, dynamic>? _userToEdit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStateChanged(_currentState);
    });
  }

  void _showForm({Map<String, dynamic>? userData}) {
    setState(() {
      _currentState = PenggunaContentState.form;
      _userToEdit = userData;
      widget.onStateChanged(_currentState);
    });
  }

  void _showTable() {
    setState(() {
      _currentState = PenggunaContentState.table;
      _userToEdit = null;
      widget.onStateChanged(_currentState);
    });
  }

  @override
  Widget build(BuildContext context) {
    double currentMaxHeight = _currentState == PenggunaContentState.table
        ? MediaQuery.of(context).size.height * 0.77
        : double.infinity;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Tampilkan tombol kembali hanya jika di mode form
              if (_currentState == PenggunaContentState.form)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _showTable, // Tombol kembali ke tabel
                  color: Colors.grey.shade700,
                ),
              if (_currentState == PenggunaContentState.form)
                const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentState == PenggunaContentState.table
                        ? "Pengguna" // Judul untuk tabel
                        : (_userToEdit != null
                            ? "Edit Pengguna"
                            : "Buat Pengguna Baru"), // Judul untuk form
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Data master untuk pengguna aplikasi MEKO POIN", // Deskripsi statis
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  currentMaxHeight, // Menggunakan nilai kondisional di sini
            ),
            child: _currentState == PenggunaContentState.table
                ? UserTable(onAddNew: _showForm)
                : UserForm(
                    onCancel: _showTable,
                    initialUserData: _userToEdit,
                  ),
          ),
        ],
      ),
    );
  }
}
