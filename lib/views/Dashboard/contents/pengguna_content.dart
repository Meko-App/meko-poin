import 'package:flutter/material.dart';
import 'package:meko_poin/services/user_repository.dart';
import 'package:meko_poin/views/Dashboard/components/table/user_table/user_table.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/content_state.dart';
import 'package:meko_poin/views/Dashboard/components/form/user_form.dart';
import 'package:meko_poin/models/user.dart';
import 'package:meko_poin/utils/password_hasher.dart';

class PenggunaContent extends StatefulWidget {
  final Function(ContentState) onStateChanged;
  final UserRepository userRepository;

  const PenggunaContent(
      {super.key, required this.onStateChanged, required this.userRepository});

  @override
  State<PenggunaContent> createState() => _PenggunaContentState();
}

class _PenggunaContentState extends State<PenggunaContent> {
  ContentState _currentState = ContentState.table;
  Map<String, dynamic>? _userToEdit;
  late final UserRepository userRepository;

  @override
  void initState() {
    super.initState();
    userRepository = widget.userRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStateChanged(_currentState);
    });
  }

  void _showForm({User? user}) {
    setState(() {
      _currentState = ContentState.form;
      _userToEdit = user != null
          ? {
              'id': user.id,
              'name': user.name,
              'email': user.email,
              'roleId': user.roleId,
              'password': user.password,
            }
          : null;
      widget.onStateChanged(_currentState);
    });
  }

  void _showTable() {
    setState(() {
      _currentState = ContentState.table;
      _userToEdit = null;
      widget.onStateChanged(_currentState);
    });
  }

  Future<void> _handleUserFormSubmit(Map<String, dynamic> userData) async {
    try {
      if (_userToEdit == null) {
        // Add new user
        final hashedPassword =
            PasswordHasher.hashPassword(userData['password']);
        final newUser = User(
          id: null,
          name: userData['name'],
          email: userData['email'],
          password: hashedPassword,
          roleId: userData['roleId'],
        );
        await userRepository.insertUser(newUser);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User baru berhasil ditambahkan')),
          );
        }
      } else {
        // Edit existing user
        String passwordToUse;
        if (userData['password'] != null && userData['password'].isNotEmpty) {
          passwordToUse = PasswordHasher.hashPassword(userData['password']);
        } else {
          passwordToUse = _userToEdit!['password'];
        }

        final updatedUser = User(
          id: _userToEdit!['id'],
          name: userData['name'],
          email: userData['email'],
          password: passwordToUse,
          roleId: userData['roleId'],
        );
        await userRepository.updateUser(updatedUser);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User berhasil diperbarui')),
          );
        }
      }
      _showTable();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double currentMaxHeight = _currentState == ContentState.table
        ? MediaQuery.of(context).size.height * 0.77
        : double.infinity;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_currentState == ContentState.form)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _showTable,
                  color: Colors.grey.shade700,
                ),
              if (_currentState == ContentState.form) const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentState == ContentState.table
                        ? "Pengguna"
                        : (_userToEdit != null
                            ? "Edit Pengguna"
                            : "Buat Pengguna Baru"),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Data master untuk pengguna aplikasi MEKO POIN",
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
              maxHeight: currentMaxHeight,
            ),
            child: _currentState == ContentState.table
                ? UserTable(
                    onAddNew: _showForm,
                    userRepository: userRepository,
                    onEditUser: (user) => _showForm(user: user),
                    onDeleteUser: (user) async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Konfirmasi'),
                          content: Text('Hapus user ${user.name}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        try {
                          await userRepository.deleteUser(user.id!);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('User berhasil dihapus')),
                            );
                          }
                          _showTable();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Gagal menghapus user: $e')),
                            );
                          }
                        }
                      }
                    },
                  )
                : UserForm(
                    onCancel: _showTable,
                    initialUserData: _userToEdit,
                    onSubmit: _handleUserFormSubmit,
                  ),
          ),
        ],
      ),
    );
  }
}
