import 'package:flutter/material.dart';
import 'package:meko_poin/models/additional/inventory_with_user_master_data.dart';
import 'package:meko_poin/models/inventory.dart';
import 'package:meko_poin/services/inventory_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:meko_poin/views/Dashboard/components/table/inventory_table/inventory_table_header.dart';
import 'package:meko_poin/views/Dashboard/components/table/inventory_table/inventory_table_pagination.dart';
import 'package:meko_poin/views/Dashboard/components/table/inventory_table/inventory_table_row.dart';
import 'package:meko_poin/views/Dashboard/components/table/inventory_table/inventory_table_search.dart';

class InventoryTable extends StatefulWidget {
  final VoidCallback onAddNew;
  final InventoryRepository inventoryRepository;
  final Function(Inventory) onEditInventory;
  final Function(Inventory) onDeleteInventory;
  final Function(int inventoryId) onViewLog;

  const InventoryTable({
    super.key,
    required this.onAddNew,
    required this.inventoryRepository,
    required this.onEditInventory,
    required this.onDeleteInventory,
    required this.onViewLog,
  });

  @override
  State<InventoryTable> createState() => _InventoryTableState();
}

class _InventoryTableState extends State<InventoryTable> {
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  int itemsPerPage = 10;
  List<InventoryWithUserMasterData> _inventoryList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String sortBy = 'name';
  bool isAscending = true;

  Set<int> selectedTransactionIds = {};
  bool get isAllSelected =>
      selectedTransactionIds.length == currentPageData.length &&
      currentPageData.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadInventoryData();
  }

  void toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        selectedTransactionIds
            .addAll(currentPageData.map((data) => data.inventoryData.id!));
      } else {
        selectedTransactionIds
            .removeAll(currentPageData.map((data) => data.inventoryData.id));
      }
    });
  }

  void toggleSelectOne(int inventoryId, bool? value) {
    setState(() {
      if (value == true) {
        selectedTransactionIds.add(inventoryId);
      } else {
        selectedTransactionIds.remove(inventoryId);
      }
    });
  }

  Future<void> _loadInventoryData() async {
    setState(() => _isLoading = true);
    try {
      final allData =
          await widget.inventoryRepository.getAllInventoryWithUserMasterData();
      setState(() => _inventoryList = allData);
    } catch (e) {
      debugPrint('Error loading inventory data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addRejectStock(
      InventoryWithUserMasterData inventory, int rejectAmount) async {
    try {
      final updatedInventory = inventory.inventoryData.copyWith(
        stock: inventory.inventoryData.stock - rejectAmount,
        stockReject: inventory.inventoryData.stockReject! + rejectAmount,
        updatedAt: DateTime.now(),
      );

      final rowsAffected = await widget.inventoryRepository
          .addReject(updatedInventory, rejectAmount);

      if (rowsAffected > 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock reject berhasil ditambahkan')),
        );
        _loadInventoryData();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan stock reject: $e')),
      );
    }
  }

  Future<void> _addStock(
    InventoryWithUserMasterData inventory,
    int addAmount,
    String? note,
  ) async {
    if (addAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah stok harus lebih dari 0')),
      );
      return;
    }

    try {
      final rowsAffected = await widget.inventoryRepository.addStock(
        inventory.inventoryData,
        addAmount,
        note: note,
      );

      if (rowsAffected > 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stok berhasil ditambahkan')),
        );
        await _loadInventoryData();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan stok: $e')),
      );
    }
  }

  @override
  void didUpdateWidget(covariant InventoryTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadInventoryData();
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
        case 'category':
          valueA = a.categoryName;
          valueB = b.categoryName;
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
    final totalPages = (sortedInventoryData.length / itemsPerPage).ceil();
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage > sortedInventoryData.length)
        ? sortedInventoryData.length
        : currentPage * itemsPerPage;

    return Container(
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        border: Border.all(color: CustomColors.borderCardColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            isAllSelected: isAllSelected,
            onSelectAllChanged: toggleSelectAll,
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
                                      categoryName: data.categoryName,
                                      stock: data.inventoryData.stock,
                                      stockReject:
                                          data.inventoryData.stockReject!,
                                      notes: data.inventoryData.notes,
                                      addedBy: data.addedBy,
                                      key: ValueKey(data.inventoryData.id),
                                      isSelected: selectedTransactionIds
                                          .contains(data.inventoryData.id),
                                      onSelectChanged: (value) =>
                                          toggleSelectOne(
                                              data.inventoryData.id!, value),
                                      onEdit: () => widget
                                          .onEditInventory(data.inventoryData),
                                      onDelete: () => widget.onDeleteInventory(
                                          data.inventoryData),
                                      onViewLog: () => widget
                                          .onViewLog(data.inventoryData.id!),
                                      onAddReject: (rejectAmount) =>
                                          _addRejectStock(data, rejectAmount),
                                      onAddStock: (quantity, note) =>
                                          _addStock(data, quantity, note),
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
