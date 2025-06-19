import 'package:flutter/material.dart';
import 'package:meko_poin/models/additional/inventory_with_user_master_data.dart';
import 'package:meko_poin/models/inventory.dart';
import 'package:meko_poin/services/inventory_repository.dart';
import 'package:meko_poin/views/Dashboard/components/table/inventory_table/inventory_table_header.dart';
import 'package:meko_poin/views/Dashboard/components/table/inventory_table/inventory_table_pagination.dart';
import 'package:meko_poin/views/Dashboard/components/table/inventory_table/inventory_table_row.dart';
import 'package:meko_poin/views/Dashboard/components/table/inventory_table/inventory_table_search.dart';

class InventoryTable extends StatefulWidget {
  final VoidCallback onAddNew;
  final InventoryRepository inventoryRepository;
  final Function(Inventory) onEditUser;
  final Function(Inventory) onDeleteUser;

  const InventoryTable({
    super.key,
    required this.onAddNew,
    required this.inventoryRepository,
    required this.onEditUser,
    required this.onDeleteUser,
  });

  @override
  State<InventoryTable> createState() => _InventoryTableState();
}

class _InventoryTableState extends State<InventoryTable> {
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  int itemsPerPage = 10;
  bool isAllSelected = false;
  Set<int> selectedRows = {};
  List<InventoryWithUserMasterData> _inventoryList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String sortBy = 'name';
  bool isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadMasterData();
  }

  Future<void> _loadMasterData() async {
    setState(() => _isLoading = true);
    try {
      final allData =
          await widget.inventoryRepository.getAllInventoryWithUserMasterData();
      setState(() => _inventoryList = allData);
    } catch (e) {
      debugPrint('Error loading master data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void didUpdateWidget(covariant InventoryTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadMasterData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<InventoryWithUserMasterData> get filteredInventoryData {
    if (_searchQuery.isEmpty) return _inventoryList;
    return _inventoryList
        .where((inventoryData) => inventoryData.name
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<InventoryWithUserMasterData> get sortedInventoryData {
    List<InventoryWithUserMasterData> sorted = List.from(filteredInventoryData);
    sorted.sort((a, b) {
      dynamic valueA;
      dynamic valueB;

      switch (sortBy) {
        case 'name':
          valueA = a.name;
          valueB = b.name;
          break;
        case 'stock':
          valueA = a.inventoryData.stock;
          valueB = b.inventoryData.stock;
          break;
        case 'catatan':
          valueA = a.inventoryData.notes;
          valueB = b.inventoryData.notes;
          break;
        case 'addedBy':
          valueA = a.addedBy;
          valueB = b.addedBy;
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

  List<InventoryWithUserMasterData> get currentPageData {
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    return sortedInventoryData.sublist(start,
        end > sortedInventoryData.length ? sortedInventoryData.length : end);
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
    final totalPages = (sortedInventoryData.length / itemsPerPage).ceil();
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage > sortedInventoryData.length)
        ? sortedInventoryData.length
        : currentPage * itemsPerPage;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Search Bar
          InventoryTableSearch(
            currentPageData: currentPageData,
            data: sortedInventoryData,
            onAddNew: widget.onAddNew,
            onSearch: (query) {
              setState(() {
                _searchQuery = query;
                currentPage = 1;
              });
            },
          ),

          // Header
          InventoryTableHeader(
            sortBy: sortBy,
            isAscending: isAscending,
            onSort: onSort,
            sortIcon: _sortIcon,
          ),

          // Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : sortedInventoryData.isEmpty
                    ? const Center(child: Text('Tidak ada data inventory'))
                    : Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: currentPageData
                                .map((data) => InventoryTableRow(
                                      name: data.name,
                                      stock: data.inventoryData.stock,
                                      notes: data.inventoryData.notes,
                                      addedBy: data.addedBy,
                                      key: ValueKey(data.inventoryData.id),
                                      onEdit: () =>
                                          widget.onEditUser(data.inventoryData),
                                      onDelete: () => widget
                                          .onDeleteUser(data.inventoryData),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
          ),

          // Pagination
          if (!_isLoading && sortedInventoryData.isNotEmpty)
            InventoryTablePagination(
              currentPage: currentPage,
              totalPages: totalPages,
              startItem: startItem,
              endItem: endItem,
              data: sortedInventoryData,
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
