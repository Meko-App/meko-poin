import 'package:flutter/material.dart';
import 'package:meko_poin/models/additional/master_data_with_user.dart';
import 'package:meko_poin/models/master_data.dart';
import 'package:meko_poin/services/master_data_repository.dart';
import 'package:meko_poin/views/Dashboard/components/table/master_data_table/packaging_dialog.dart';
import 'master_data_table_header.dart';
import 'master_data_table_row.dart';
import 'master_data_table_pagination.dart';
import 'master_data_table_search.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class MasterDataTable extends StatefulWidget {
  final VoidCallback onAddNew;
  final MasterDataRepository masterDataRepository;
  final Function(MasterData) onEditMasterData;
  final Function(MasterData) onDeleteMasterData;

  const MasterDataTable({
    super.key,
    required this.onAddNew,
    required this.masterDataRepository,
    required this.onEditMasterData,
    required this.onDeleteMasterData,
  });

  @override
  State<MasterDataTable> createState() => _MasterDataTableState();
}

class _MasterDataTableState extends State<MasterDataTable> {
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  int itemsPerPage = 10;
  List<MasterDataWithUser> _masterDataList = [];
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
    _loadMasterData();
  }

  void toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        selectedTransactionIds
            .addAll(currentPageData.map((data) => data.masterData.id!));
      } else {
        selectedTransactionIds
            .removeAll(currentPageData.map((data) => data.masterData.id));
      }
    });
  }

  void toggleSelectOne(int masterDataId, bool? value) {
    setState(() {
      if (value == true) {
        selectedTransactionIds.add(masterDataId);
      } else {
        selectedTransactionIds.remove(masterDataId);
      }
    });
  }

  Future<void> _loadMasterData() async {
    setState(() => _isLoading = true);
    try {
      final allData =
          await widget.masterDataRepository.getAllMasterDataWithUser();
      setState(() => _masterDataList = allData);
    } catch (e) {
      debugPrint('Error loading master data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void didUpdateWidget(covariant MasterDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadMasterData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<MasterDataWithUser> get filteredMasterData {
    if (_searchQuery.isEmpty) return _masterDataList;
    return _masterDataList
        .where((masterdata) => masterdata.masterData.name
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<MasterDataWithUser> get sortedMasterData {
    List<MasterDataWithUser> sorted = List.from(filteredMasterData);
    sorted.sort((a, b) {
      dynamic valueA;
      dynamic valueB;

      switch (sortBy) {
        case 'name':
          valueA = a.masterData.name;
          valueB = b.masterData.name;
          break;
        case 'category':
          valueA = a.masterData.category;
          valueB = b.masterData.category;
          break;
        case 'harga':
          valueA = a.masterData.price;
          valueB = b.masterData.price;
          break;
        case 'addedBy':
          valueA = a.addedBy;
          valueB = b.addedBy;
          break;
        default:
          valueA = a.masterData.name;
          valueB = b.masterData.name;
      }

      int result = valueA.toString().compareTo(valueB.toString());
      return isAscending ? result : -result;
    });
    return sorted;
  }

  List<MasterDataWithUser> get currentPageData {
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    return sortedMasterData.sublist(
        start, end > sortedMasterData.length ? sortedMasterData.length : end);
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

  void _handlePackagingAction(MasterData masterData) async {
    final isPaper = (masterData.categoryCode ?? '').toLowerCase() == 'paper' ||
        masterData.category.toLowerCase() == 'paper';
    if (isPaper) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => PackagingDialog(
          paperData: masterData,
          repository: widget.masterDataRepository,
        ),
      );

      if (result == true) {
        // Refresh data jika berhasil
        _loadMasterData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Packaging berhasil diperbarui')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (sortedMasterData.length / itemsPerPage).ceil();
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage > sortedMasterData.length)
        ? sortedMasterData.length
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
          MasterDataTableSearch(
            currentPageData: currentPageData,
            data: sortedMasterData,
            onAddNew: widget.onAddNew,
            onSearch: (query) {
              setState(() {
                _searchQuery = query;
                currentPage = 1;
              });
            },
          ),

          // Header
          MasterDataTableHeader(
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
                : sortedMasterData.isEmpty
                    ? const Center(child: Text('Tidak ada data master'))
                    : Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: currentPageData
                                .map((data) => MasterDataTableRow(
                                      name: data.masterData.name,
                                      category: data.masterData.category,
                                      categoryCode:
                                          data.masterData.categoryCode,
                                      price: data.masterData.price ?? 0,
                                      addedBy: data.addedBy,
                                      packagingId: data.masterData.packagingId,
                                      key: ValueKey(data.masterData.id),
                                      isSelected: selectedTransactionIds
                                          .contains(data.masterData.id),
                                      onSelectChanged: (value) =>
                                          toggleSelectOne(
                                              data.masterData.id!, value),
                                      onEdit: () => widget
                                          .onEditMasterData(data.masterData),
                                      onDelete: () => widget
                                          .onDeleteMasterData(data.masterData),
                                      onPackaging: () => _handlePackagingAction(
                                          data.masterData),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
          ),

          // Pagination
          if (!_isLoading && sortedMasterData.isNotEmpty)
            MasterDataTablePagination(
              currentPage: currentPage,
              totalPages: totalPages,
              startItem: startItem,
              endItem: endItem,
              data: sortedMasterData,
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
