import 'package:flutter/material.dart';
import 'package:meko_poin/services/user_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:meko_poin/views/Dashboard/components/table/user_table/user_table.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/content_state.dart';
import 'package:meko_poin/views/Dashboard/components/form/user_form.dart';
import 'package:meko_poin/models/user.dart';
import 'package:meko_poin/utils/password_hasher.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:meko_poin/views/Dashboard/components/table/attendance_table/attendance_table.dart';

class PenggunaContent extends StatefulWidget {
  final Function(ContentState) onStateChanged;
  final UserRepository userRepository;
  final TransactionRepository transactionRepository;

  const PenggunaContent({
    super.key,
    required this.onStateChanged,
    required this.userRepository,
    required this.transactionRepository,
  });

  @override
  State<PenggunaContent> createState() => _PenggunaContentState();
}

class _PenggunaContentState extends State<PenggunaContent> {
  ContentState _currentState = ContentState.table;
  Map<String, dynamic>? _userToEdit;
  late final UserRepository userRepository;
  late final TransactionRepository transactionRepository;

  // State untuk attendance history
  int? _selectedUserId;
  String? _selectedUserName;

  @override
  void initState() {
    super.initState();
    userRepository = widget.userRepository;
    transactionRepository = widget.transactionRepository;
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
      _selectedUserId = null;
      _selectedUserName = null;
      widget.onStateChanged(_currentState);
    });
  }

  void _showAttendanceHistory(int userId, String userName) {
    setState(() {
      _currentState = ContentState.attendance;
      _selectedUserId = userId;
      _selectedUserName = userName;
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
              if (_currentState != ContentState.table)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _showTable,
                  color: Colors.grey.shade700,
                ),
              if (_currentState != ContentState.table) const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTitle(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getSubtitle(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: CustomColors.fontSubColor,
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
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_currentState) {
      case ContentState.table:
        return "Pengguna";
      case ContentState.form:
        return _userToEdit != null ? "Edit Pengguna" : "Buat Pengguna Baru";
      case ContentState.attendance:
        return "Riwayat Kehadiran - $_selectedUserName";
      default:
        return "Pengguna";
    }
  }

  String _getSubtitle() {
    switch (_currentState) {
      case ContentState.table:
        return "Data master untuk pengguna aplikasi MEKO POIN";
      case ContentState.form:
        return _userToEdit != null
            ? "Edit data pengguna"
            : "Buat pengguna baru";
      case ContentState.attendance:
        return "Data kehadiran pengguna berdasarkan transaksi";
      default:
        return "Data master untuk pengguna aplikasi MEKO POIN";
    }
  }

  Widget _buildContent() {
    switch (_currentState) {
      case ContentState.table:
        return UserTable(
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
                await userRepository.softDeleteUser(user.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User berhasil dihapus')),
                  );
                }
                _showTable();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus user: $e')),
                  );
                }
              }
            }
          },
          onAttendance: (userId, userName) =>
              _showAttendanceHistory(userId, userName),
        );
      case ContentState.form:
        return UserForm(
          onCancel: _showTable,
          initialUserData: _userToEdit,
          onSubmit: _handleUserFormSubmit,
        );
      case ContentState.attendance:
        return _selectedUserId != null
            ? AttendanceTable(
                transactionRepository: transactionRepository,
                userId: _selectedUserId!,
              )
            : const Center(child: Text('User tidak ditemukan'));
      default:
        return UserTable(
          onAddNew: _showForm,
          userRepository: userRepository,
          onEditUser: (user) => _showForm(user: user),
          onDeleteUser: (user) {},
          onAttendance: (userId, userName) =>
              _showAttendanceHistory(userId, userName),
        );
    }
  }
}
