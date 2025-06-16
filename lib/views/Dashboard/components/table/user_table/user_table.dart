// lib/views/Dashboard/components/table/user_table/user_table.dart
import 'package:flutter/material.dart';
import 'user_table_header.dart';
import 'user_table_row.dart';
import 'user_table_pagination.dart';
import 'user_table_search.dart';

class UserTable extends StatefulWidget {
  final VoidCallback onAddNew; // Tambahkan properti ini

  const UserTable(
      {super.key, required this.onAddNew}); // Tambahkan ke constructor

  @override
  State<UserTable> createState() => _UserTableState();
}

class _UserTableState extends State<UserTable> {
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  int itemsPerPage = 10;
  bool isAllSelected = false;
  Set<int> selectedRows = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> data = [
    // ... (data yang sama)
    {
      'name': 'John Doe',
      'email': 'john@doe.com1',
      'role': 'Operator',
    },
    {
      'name': 'John Doe',
      'email': 'john@doe.com2',
      'role': 'Operator',
    },
    {
      'name': 'John Doe',
      'email': 'john@doe.com3',
      'role': 'Operator',
    },
    {
      'name': 'John Doe',
      'email': 'john@doe.com4',
      'role': 'Operator',
    },
    {
      'name': 'John Doe',
      'email': 'john@doe.com5',
      'role': 'Operator',
    },
    {
      'name': 'John Doe',
      'email': 'john@doe.com6',
      'role': 'Operator',
    },
    {
      'name': 'John Doe',
      'email': 'john@doe.com7',
      'role': 'Operator',
    },
    {
      'name': 'John Doe',
      'email': 'john@doe.com8',
      'role': 'Operator',
    },
    {
      'name': 'John Doe',
      'email': 'john@doe.com9',
      'role': 'Operator',
    },
    {
      'name': 'John Doe',
      'email': 'john@doe.com10',
      'role': 'Operator',
    },
    {
      'name': 'John Doe',
      'email': 'john@doe.com11',
      'role': 'Operator',
    },
    {
      'name': 'John Doe',
      'email': 'john@doe.com12',
      'role': 'Operator',
    },
    {
      'name': 'John Doe',
      'email': 'john@doe.com13',
      'role': 'Operator',
    },
    {
      'name': 'John Doe',
      'email': 'john@doe.com14',
      'role': 'Operator',
    },
    {
      'name': 'John Doe',
      'email': 'john@doe.com15',
      'role': 'Operator',
    },
    {
      'name': 'John Doe',
      'email': 'john@doe.com16',
      'role': 'Operator',
    },
    {
      'name': 'John Doe',
      'email': 'john@doe.com17',
      'role': 'Operator',
    },
    {
      'name': 'John Doe',
      'email': 'john@doe.com18',
      'role': 'Operator',
    }
  ];

  String sortBy = 'name';
  bool isAscending = true;

  List<Map<String, dynamic>> get sortedData {
    List<Map<String, dynamic>> sorted = List.from(data);
    sorted.sort((a, b) {
      dynamic valueA = a[sortBy];
      dynamic valueB = b[sortBy];

      int result;
      if (valueA is int) {
        result = valueA.compareTo(valueB);
      } else if (valueA is String &&
          RegExp(r'^\d{2}\.\d{2}$').hasMatch(valueA)) {
        result = int.parse(valueA.replaceAll('.', ''))
            .compareTo(int.parse(valueB.replaceAll('.', '')));
      } else {
        result = valueA.toString().compareTo(valueB.toString());
      }

      return isAscending ? result : -result;
    });
    return sorted;
  }

  List<Map<String, dynamic>> get currentPageData {
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    return sortedData.sublist(
        start, end > sortedData.length ? sortedData.length : end);
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
        color: Color(0xFF4B5675),
      );
    }
    return Icon(
      isAscending ? Icons.arrow_upward : Icons.arrow_downward,
      size: 14,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (data.length / itemsPerPage).ceil();
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage > data.length)
        ? data.length
        : currentPage * itemsPerPage;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 1. Search Bar (Tetap Fixed)
          UserTableSearch(
            currentPageData: currentPageData,
            data: data,
            onAddNew: widget.onAddNew, // Teruskan callback ke UserTableSearch
          ),

          // 2. Header (Tetap Fixed)
          UserTableHeader(
            sortBy: sortBy,
            isAscending: isAscending,
            onSort: onSort,
            sortIcon: _sortIcon,
          ),

          // 3. Body (Scrollable)
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: currentPageData
                      .map((row) => UserTableRow(
                            row: row,
                            key: ValueKey(row['email']),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),

          // 4. Pagination (Tetap Fixed)
          UserTablePagination(
            currentPage: currentPage,
            totalPages: totalPages,
            startItem: startItem,
            endItem: endItem,
            data: data,
            itemsPerPage: itemsPerPage,
            onItemsPerPageChanged: (value) {
              setState(() {
                itemsPerPage = value;
                currentPage = 1;
              });
            },
            onPageChanged: (page) {
              setState(() {
                currentPage = page;
              });
            },
          ),
        ],
      ),
    );
  }
}
