import 'package:flutter/material.dart';
import 'package:meko_poin/models/inventory_log.dart';
import 'package:meko_poin/services/inventory_log_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:meko_poin/views/Dashboard/components/table/inventory_log_table/inventory_log_table_header.dart';
import 'package:meko_poin/views/Dashboard/components/table/inventory_log_table/inventory_log_table_pagination.dart';
import 'package:meko_poin/views/Dashboard/components/table/inventory_log_table/inventory_log_table_row.dart';
import 'package:meko_poin/views/Dashboard/components/table/inventory_log_table/inventory_log_table_search.dart';

class InventoryLogTable extends StatefulWidget {
  final int inventoryId;
  final InventoryLogRepository inventoryLogRepository;

  const InventoryLogTable({
    super.key,
    required this.inventoryId,
    required this.inventoryLogRepository,
  });

  @override
  State<InventoryLogTable> createState() => _InventoryLogTableState();
}

class _InventoryLogTableState extends State<InventoryLogTable> {
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  int itemsPerPage = 10;
  List<InventoryLog> _inventoryLogList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String sortBy = 'createdAt';
  bool isAscending = false;

  @override
  void initState() {
    super.initState();
    _loadLogData();
  }

  Future<void> _loadLogData() async {
    setState(() => _isLoading = true);
    try {
      // Use your existing method
      final allLogs = await widget.inventoryLogRepository
          .getLogsByInventoryId(widget.inventoryId);
      setState(() => _inventoryLogList = allLogs);
    } catch (e) {
      debugPrint('Error loading inventory log data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void didUpdateWidget(covariant InventoryLogTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data if the inventoryId changes
    if (widget.inventoryId != oldWidget.inventoryId) {
      _loadLogData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<InventoryLog> get filteredInventoryLogData {
    if (_searchQuery.isEmpty) return _inventoryLogList;
    return _inventoryLogList
        .where((log) =>
            log.notes.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<InventoryLog> get sortedInventoryLogData {
    List<InventoryLog> sorted = List.from(filteredInventoryLogData);
    sorted.sort((a, b) {
      dynamic valueA;
      dynamic valueB;

      switch (sortBy) {
        case 'createdAt':
          valueA = a.createdAt;
          valueB = b.createdAt;
          break;
        case 'initialStock':
          valueA = a.initialStock;
          valueB = b.initialStock;
          break;
        case 'currentStock':
          valueA = a.currentStock;
          valueB = b.currentStock;
          break;
        case 'difference':
          valueA = a.difference;
          valueB = b.difference;
          break;
        case 'notes':
          valueA = a.notes;
          valueB = b.notes;
          break;
        default:
          valueA = a.createdAt;
          valueB = b.createdAt;
      }

      int result;
      if (valueA is String && valueB is String) {
        result = valueA.compareTo(valueB);
      } else if (valueA is num && valueB is num) {
        result = valueA.compareTo(valueB);
      } else if (valueA is DateTime && valueB is DateTime) {
        result = valueA.compareTo(valueB);
      } else {
        result = valueA.toString().compareTo(valueB.toString());
      }

      return isAscending ? result : -result;
    });
    return sorted;
  }

  List<InventoryLog> get currentPageData {
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    return sortedInventoryLogData.sublist(
        start,
        end > sortedInventoryLogData.length
            ? sortedInventoryLogData.length
            : end);
  }

  void onSort(String column) {
    setState(() {
      if (sortBy == column) {
        isAscending = !isAscending;
      } else {
        sortBy = column;
        isAscending = false;
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
    final totalPages = (sortedInventoryLogData.length / itemsPerPage).ceil();
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage > sortedInventoryLogData.length)
        ? sortedInventoryLogData.length
        : currentPage * itemsPerPage;

    return Container(
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        border: Border.all(color: CustomColors.borderCardColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InventoryLogTableSearch(
            currentPageData: currentPageData,
            data: sortedInventoryLogData,
            onSearch: (query) {
              setState(() {
                _searchQuery = query;
                currentPage = 1;
              });
            },
          ),
          InventoryLogTableHeader(
            sortBy: sortBy,
            isAscending: isAscending,
            onSort: onSort,
            sortIcon: _sortIcon,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : sortedInventoryLogData.isEmpty
                    ? const Center(child: Text('Tidak ada data log inventory'))
                    : Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: currentPageData
                                .map((log) => InventoryLogTableRow(
                                      key: ValueKey(log.id),
                                      createdAt: log.createdAt,
                                      notes: log.notes,
                                      initialStock: log.initialStock,
                                      currentStock: log.currentStock,
                                      difference: log.difference,
                                      type: log.type,
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
          ),
          if (!_isLoading && sortedInventoryLogData.isNotEmpty)
            InventoryLogTablePagination(
              currentPage: currentPage,
              totalPages: totalPages,
              startItem: startItem,
              endItem: endItem,
              data: sortedInventoryLogData,
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
