import 'package:flutter/material.dart';
import 'package:meko_poin/models/user.dart';
import 'package:meko_poin/services/user_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'user_table_header.dart';
import 'user_table_row.dart';
import 'user_table_pagination.dart';
import 'user_table_search.dart';

class UserTable extends StatefulWidget {
  final VoidCallback onAddNew;
  final UserRepository userRepository;
  final Function(User) onEditUser;
  final Function(User) onDeleteUser;

  const UserTable({
    super.key,
    required this.onAddNew,
    required this.userRepository,
    required this.onEditUser,
    required this.onDeleteUser,
  });

  @override
  State<UserTable> createState() => _UserTableState();
}

class _UserTableState extends State<UserTable> {
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  int itemsPerPage = 10;
  bool isAllSelected = false;
  Set<int> selectedRows = {};
  List<User> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String sortBy = 'name';
  bool isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final allUsers = await widget.userRepository.getAllUsers();
      final operatorUsers = allUsers.where((user) => user.roleId == 2).toList();
      setState(() => _users = operatorUsers);
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void didUpdateWidget(covariant UserTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadUsers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<User> get filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users
        .where((user) =>
            user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<User> get sortedUsers {
    List<User> sorted = List.from(filteredUsers);
    sorted.sort((a, b) {
      dynamic valueA;
      dynamic valueB;

      switch (sortBy) {
        case 'name':
          valueA = a.name;
          valueB = b.name;
          break;
        case 'email':
          valueA = a.email;
          valueB = b.email;
          break;
        case 'role':
          valueA = a.roleId;
          valueB = b.roleId;
          break;
        default:
          valueA = a.name;
          valueB = b.name;
      }

      int result = valueA.toString().compareTo(valueB.toString());
      return isAscending ? result : -result;
    });
    return sorted;
  }

  List<User> get currentPageData {
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    return sortedUsers.sublist(
        start, end > sortedUsers.length ? sortedUsers.length : end);
  }

  void onSort(String column) {
    setState(() {
      if (sortBy == column) {
        isAscending = !isAscending;
      } else {
        sortBy = column;
        isAscending = true;
      }
    });
  }

  Icon _sortIcon(String column) {
    if (sortBy != column) {
      return const Icon(
        Icons.unfold_more,
        size: 14,
        color: CustomColors.fontSubColor,
      );
    }
    return Icon(
      isAscending ? Icons.arrow_upward : Icons.arrow_downward,
      size: 14,
      color: CustomColors.fontSubColor,
    );
  }

  String _getRoleName(int roleId) {
    switch (roleId) {
      case 1:
        return 'Admin';
      case 2:
        return 'Operator';
      default:
        return 'Operator';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (sortedUsers.length / itemsPerPage).ceil();
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage > sortedUsers.length)
        ? sortedUsers.length
        : currentPage * itemsPerPage;

    return Container(
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        border: Border.all(color: CustomColors.borderCardColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Search Bar
          UserTableSearch(
            currentPageData: currentPageData,
            data: sortedUsers,
            onAddNew: widget.onAddNew,
            onSearch: (query) {
              setState(() {
                _searchQuery = query;
                currentPage = 1;
              });
            },
          ),

          // Header
          UserTableHeader(
            sortBy: sortBy,
            isAscending: isAscending,
            onSort: onSort,
            sortIcon: _sortIcon,
          ),

          // Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : sortedUsers.isEmpty
                    ? const Center(child: Text('Tidak ada data user'))
                    : Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: currentPageData
                                .map((user) => UserTableRow(
                                      name: user.name,
                                      email: user.email,
                                      role: _getRoleName(user.roleId),
                                      key: ValueKey(user.id),
                                      onEdit: () => widget.onEditUser(user),
                                      onDelete: () => widget.onDeleteUser(user),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
          ),

          // Pagination
          if (!_isLoading && sortedUsers.isNotEmpty)
            UserTablePagination(
              currentPage: currentPage,
              totalPages: totalPages,
              startItem: startItem,
              endItem: endItem,
              data: sortedUsers,
              itemsPerPage: itemsPerPage,
              onItemsPerPageChanged: (value) {
                setState(() {
                  itemsPerPage = value;
                  currentPage = 1;
                });
              },
              onPageChanged: (page) {
                setState(() => currentPage = page);
              },
            ),
        ],
      ),
    );
  }
}
