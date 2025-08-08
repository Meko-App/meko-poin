import 'package:flutter/material.dart';
import 'package:meko_poin/models/customer.dart';
import 'package:meko_poin/services/customer_repository.dart';
import 'customer_table_header.dart';
import 'customer_table_row.dart';
import 'customer_table_pagination.dart';
import 'customer_table_search.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class CustomerTable extends StatefulWidget {
  final CustomerRepository customerRepository;

  const CustomerTable({
    super.key,
    required this.customerRepository,
  });

  @override
  State<CustomerTable> createState() => _CustomerTableState();
}

class _CustomerTableState extends State<CustomerTable> {
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  int itemsPerPage = 10;
  bool isAllSelected = false;
  Set<int> selectedRows = {};
  List<Customer> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String sortBy = 'name';
  bool isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final allCustomers = await widget.customerRepository.getAllCustomers();
      final operatorCustomers = allCustomers.toList();
      setState(() => _customers = operatorCustomers);
    } catch (e) {
      debugPrint('Error loading customers: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void didUpdateWidget(covariant CustomerTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadCustomers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Customer> get filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    return _customers
        .where((customer) =>
            customer.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<Customer> get sortedCustomers {
    List<Customer> sorted = List.from(filteredCustomers);
    sorted.sort((a, b) {
      dynamic valueA;
      dynamic valueB;

      switch (sortBy) {
        case 'name':
          valueA = a.name;
          valueB = b.name;
          break;
        case 'phone':
          valueA = a.phone;
          valueB = b.phone;
          break;
        case 'added':
          valueA = a.createdAt;
          valueB = b.createdAt;
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

  List<Customer> get currentPageData {
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    return sortedCustomers.sublist(
        start, end > sortedCustomers.length ? sortedCustomers.length : end);
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

  @override
  Widget build(BuildContext context) {
    final totalPages = (sortedCustomers.length / itemsPerPage).ceil();
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage > sortedCustomers.length)
        ? sortedCustomers.length
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
          CustomerTableSearch(
            currentPageData: currentPageData,
            data: sortedCustomers,
            onSearch: (query) {
              setState(() {
                _searchQuery = query;
                currentPage = 1;
              });
            },
          ),

          // Header
          CustomerTableHeader(
            sortBy: sortBy,
            isAscending: isAscending,
            onSort: onSort,
            sortIcon: _sortIcon,
          ),

          // Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : sortedCustomers.isEmpty
                    ? const Center(child: Text('Tidak ada data customer'))
                    : Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: currentPageData
                                .map((user) => CustomerTableRow(
                                      name: user.name,
                                      phone: user.phone,
                                      createdAt: user.createdAt,
                                      key: ValueKey(user.id),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
          ),

          // Pagination
          if (!_isLoading && sortedCustomers.isNotEmpty)
            CustomerTablePagination(
              currentPage: currentPage,
              totalPages: totalPages,
              startItem: startItem,
              endItem: endItem,
              data: sortedCustomers,
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
