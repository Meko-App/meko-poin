import 'package:flutter/material.dart';
import 'package:meko_poin/services/kas_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:meko_poin/views/Dashboard/components/table/kas_table/kas_table_header.dart';
import 'package:meko_poin/views/Dashboard/components/table/kas_table/kas_table_pagination.dart';
import 'package:meko_poin/views/Dashboard/components/table/kas_table/kas_table_row.dart';
import 'package:meko_poin/views/Dashboard/components/table/kas_table/kas_table_filter.dart';

class KasTable extends StatefulWidget {
  final KasRepository kasRepository;
  final Function(DateTime) onViewDetail;
  final VoidCallback onAddNew;

  const KasTable({
    super.key,
    required this.kasRepository,
    required this.onViewDetail,
    required this.onAddNew,
  });

  @override
  State<KasTable> createState() => _KasTableState();
}

class _KasTableState extends State<KasTable> {
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  int itemsPerPage = 10;
  List<Map<String, dynamic>> _kasSummaryList = [];
  bool _isLoading = true;
  int? _selectedYear;
  int? _selectedMonth;
  String sortBy = 'month'; // Default sort by month
  bool isAscending = false;

  Set<int> selectedMonthIds = {};
  bool get isAllSelected =>
      selectedMonthIds.length == currentPageData.length &&
      currentPageData.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadKasSummaryData();
  }

  void toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        selectedMonthIds.addAll(
            currentPageData.map((data) => data['month'] + data['year'] * 100));
      } else {
        selectedMonthIds.clear();
      }
    });
  }

  void toggleSelectOne(int monthYearId, bool? value) {
    setState(() {
      if (value == true) {
        selectedMonthIds.add(monthYearId);
      } else {
        selectedMonthIds.remove(monthYearId);
      }
    });
  }

  Future<void> _loadKasSummaryData() async {
    setState(() => _isLoading = true);
    try {
      final summaryData = await widget.kasRepository.getKasSummaryByMonth(
        year: _selectedYear,
        month: _selectedMonth,
      );
      setState(() => _kasSummaryList = summaryData);
    } catch (e) {
      debugPrint('Error loading kas summary data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleFilterChange(int? year, int? month) {
    setState(() {
      _selectedYear = year;
      _selectedMonth = month;
      currentPage = 1;
      selectedMonthIds.clear();
    });
    _loadKasSummaryData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get sortedKasSummaryList {
    List<Map<String, dynamic>> sorted = List.from(_kasSummaryList);
    sorted.sort((a, b) {
      dynamic valueA;
      dynamic valueB;

      switch (sortBy) {
        case 'month':
          valueA = DateTime(a['year'], a['month']);
          valueB = DateTime(b['year'], b['month']);
          break;
        case 'saldo':
          valueA = a['net_amount'];
          valueB = b['net_amount'];
          break;
        default:
          valueA = DateTime(a['year'], a['month']);
          valueB = DateTime(b['year'], b['month']);
      }

      int result;
      if (valueA is DateTime && valueB is DateTime) {
        result = valueA.compareTo(valueB);
      } else if (valueA is num && valueB is num) {
        result = valueA.compareTo(valueB);
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
    return sortedKasSummaryList.sublist(start,
        end > sortedKasSummaryList.length ? sortedKasSummaryList.length : end);
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
    final totalPages = (sortedKasSummaryList.length / itemsPerPage).ceil();
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage > sortedKasSummaryList.length)
        ? sortedKasSummaryList.length
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
          // Filter Bar
          KasTableFilter(
            kasRepository: widget.kasRepository,
            currentPageData: currentPageData,
            data: sortedKasSummaryList,
            onFilterChanged: _handleFilterChange,
            onAddNew: widget.onAddNew,
            currentYear: _selectedYear,
            currentMonth: _selectedMonth,
          ),

          // Header - Updated to support sorting
          KasTableHeader(
            isAllSelected: isAllSelected,
            onSelectAllChanged: toggleSelectAll,
            sortBy: sortBy,
            isAscending: isAscending,
            onSort: onSort,
            sortIcon: _sortIcon,
          ),

          // Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : sortedKasSummaryList.isEmpty
                    ? const Center(child: Text('Tidak ada data kas'))
                    : Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: currentPageData.map((data) {
                              final monthYearId =
                                  data['month'] + data['year'] * 100;
                              return KasTableRow(
                                month: data['month'],
                                year: data['year'],
                                totalIncome: data['total_income'],
                                totalOutcome: data['total_outcome'],
                                netAmount: data['net_amount'],
                                isSelected:
                                    selectedMonthIds.contains(monthYearId),
                                onSelectChanged: (value) =>
                                    toggleSelectOne(monthYearId, value),
                                onViewDetail: () {
                                  final date =
                                      DateTime(data['year'], data['month']);
                                  widget.onViewDetail(date);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),

          // Pagination
          if (!_isLoading && sortedKasSummaryList.isNotEmpty)
            KasTablePagination(
              currentPage: currentPage,
              totalPages: totalPages,
              startItem: startItem,
              endItem: endItem,
              data: sortedKasSummaryList,
              itemsPerPage: itemsPerPage,
              onItemsPerPageChanged: (value) {
                setState(() {
                  itemsPerPage = value;
                  currentPage = 1;
                  selectedMonthIds.clear();
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
