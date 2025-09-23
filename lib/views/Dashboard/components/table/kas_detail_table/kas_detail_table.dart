import 'package:flutter/material.dart';
import 'package:meko_poin/models/additional/kas_with_balance.dart';
import 'package:meko_poin/services/kas_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:intl/intl.dart';
import 'package:meko_poin/views/Dashboard/components/table/kas_detail_table/kas_detail_table_header.dart';
import 'package:meko_poin/views/Dashboard/components/table/kas_detail_table/kas_detail_table_pagination.dart';
import 'package:meko_poin/views/Dashboard/components/table/kas_detail_table/kas_detail_table_row.dart';
import 'package:meko_poin/views/Dashboard/components/table/kas_detail_table/kas_detail_table_search.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/kas_report_service.dart';

class KasDetailTable extends StatefulWidget {
  final KasRepository kasRepository;
  final DateTime selectedMonth;
  final VoidCallback onBack;
  final Function(Map<String, dynamic>) onEdit;
  final VoidCallback onAddNew;

  const KasDetailTable({
    super.key,
    required this.kasRepository,
    required this.selectedMonth,
    required this.onBack,
    required this.onEdit,
    required this.onAddNew,
  });

  @override
  State<KasDetailTable> createState() => _KasDetailTableState();
}

class _KasDetailTableState extends State<KasDetailTable> {
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  int itemsPerPage = 10;
  List<KasWithBalance> _kasDetailList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String sortBy = 'id'; // Default sort by month
  bool isAscending = false;

  Set<int> selectedTransactionIds = {};
  bool get isAllSelected =>
      selectedTransactionIds.length == currentPageData.length &&
      currentPageData.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadKasDetailData();
  }

  void toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        selectedTransactionIds
            .addAll(currentPageData.map((data) => data.kas.id!));
      } else {
        selectedTransactionIds.clear();
      }
    });
  }

  void toggleSelectOne(int kasId, bool? value) {
    setState(() {
      if (value == true) {
        selectedTransactionIds.add(kasId);
      } else {
        selectedTransactionIds.remove(kasId);
      }
    });
  }

  Future<void> _loadKasDetailData() async {
    setState(() => _isLoading = true);
    try {
      final detailData = await widget.kasRepository.getKasByMonth(
        widget.selectedMonth.year,
        widget.selectedMonth.month,
      );
      setState(() => _kasDetailList = detailData);
    } catch (e) {
      debugPrint('Error loading kas detail data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<KasWithBalance> get filteredKasData {
    if (_searchQuery.isEmpty) return _kasDetailList;
    return _kasDetailList
        .where((kasWithBalance) => kasWithBalance.kas.description
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<KasWithBalance> get sortedKasData {
    List<KasWithBalance> sorted = List.from(filteredKasData);
    sorted.sort((a, b) {
      dynamic valueA;
      dynamic valueB;

      switch (sortBy) {
        case 'tanggal':
          valueA = a.kas.cashDate;
          valueB = b.kas.cashDate;
          break;
        case 'nominal':
          valueA = a.kas.amount;
          valueB = b.kas.amount;
          break;
        case 'tipe':
          valueA = a.kas.type;
          valueB = b.kas.type;
          break;
        case 'saldoAwal':
          valueA = a.initialBalance;
          valueB = b.initialBalance;
          break;
        case 'saldoAkhir':
          valueA = a.finalBalance;
          valueB = b.finalBalance;
          break;
        case 'keterangan':
          valueA = a.kas.description;
          valueB = b.kas.description;
          break;
        case 'id':
          final dateA = DateTime(
              a.kas.cashDate.year, a.kas.cashDate.month, a.kas.cashDate.day);
          final dateB = DateTime(
              b.kas.cashDate.year, b.kas.cashDate.month, b.kas.cashDate.day);

          final dateCompare = dateA.compareTo(dateB);
          if (dateCompare != 0) {
            return isAscending ? dateCompare : -dateCompare;
          }
          valueA = a.kas.id;
          valueB = b.kas.id;
          break;
        default:
          valueA = a.kas.cashDate;
          valueB = b.kas.cashDate;
      }

      int result = valueA.toString().compareTo(valueB.toString());
      return isAscending ? result : -result;
    });
    return sorted;
  }

  void _exportToExcel() async {
    if (_kasDetailList.isEmpty) return;

    final sortedList = List<KasWithBalance>.from(_kasDetailList)
      ..sort((a, b) {
        final dateCompare = a.kas.cashDate.compareTo(b.kas.cashDate);
        if (dateCompare != 0) return dateCompare;
        return b.kas.id!.compareTo(a.kas.id!);
      });

    final lastBalance =
        sortedList.isNotEmpty ? sortedList.last.finalBalance : 0;

    await KasReportService.exportKasReportToExcel(
      kasData: sortedList,
      finalBalance: lastBalance,
      monthYear: monthName,
      context: context,
    );
  }

  List<KasWithBalance> get currentPageData {
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    return sortedKasData.sublist(
        start, end > sortedKasData.length ? sortedKasData.length : end);
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

  String get monthName {
    return DateFormat('MMMM yyyy', 'id_ID').format(widget.selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (sortedKasData.length / itemsPerPage).ceil();
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage > sortedKasData.length)
        ? sortedKasData.length
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
          // Search Bar dengan tombol
          KasDetailTableSearch(
            currentPageData: currentPageData,
            data: sortedKasData,
            onBack: widget.onBack,
            onSearch: (query) {
              setState(() {
                _searchQuery = query;
                currentPage = 1;
              });
            },
            onAddNew: widget.onAddNew,
            onPrint: _exportToExcel,
            monthName: monthName,
          ),

          // Header
          KasDetailTableHeader(
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
                : sortedKasData.isEmpty
                    ? const Center(child: Text('Tidak ada data transaksi'))
                    : Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: currentPageData
                                .map((kas) => KasDetailTableRow(
                                      kasWithBalance: kas,
                                      isSelected: selectedTransactionIds
                                          .contains(kas.kas.id),
                                      onSelectChanged: (value) =>
                                          toggleSelectOne(kas.kas.id!, value),
                                      onEdit: () =>
                                          widget.onEdit(kas.kas.toMap()),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
          ),

          // Pagination
          if (!_isLoading && sortedKasData.isNotEmpty)
            KasDetailTablePagination(
              currentPage: currentPage,
              totalPages: totalPages,
              startItem: startItem,
              endItem: endItem,
              data: sortedKasData,
              itemsPerPage: itemsPerPage,
              onItemsPerPageChanged: (value) {
                setState(() {
                  itemsPerPage = value;
                  currentPage = 1;
                  selectedTransactionIds.clear();
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
