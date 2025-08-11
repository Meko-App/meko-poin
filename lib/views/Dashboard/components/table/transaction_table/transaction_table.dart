import 'package:flutter/material.dart';
import 'package:meko_poin/models/additional/transaction_with_customer_user.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'transaction_table_header.dart';
import 'transaction_table_pagination.dart';
import 'transaction_table_row.dart';
import 'transaction_table_search.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class TransactionTable extends StatefulWidget {
  final TransactionRepository transactionRepository;
  final Function(int transactionId) onViewDetail;
  final VoidCallback onAddNew;
  final VoidCallback onPrintReport;

  const TransactionTable({
    super.key,
    required this.transactionRepository,
    required this.onViewDetail,
    required this.onAddNew,
    required this.onPrintReport,
  });

  @override
  State<TransactionTable> createState() => _TransactionTableState();
}

class _TransactionTableState extends State<TransactionTable> {
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  int itemsPerPage = 10;
  List<TransactionWithCustomerUser> _transactionList = [];
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;
  String sortBy = 'createdAt';
  bool isAscending = false;

  Set<int> selectedTransactionIds = {};
  bool get isAllSelected =>
      selectedTransactionIds.length == currentPageData.length &&
      currentPageData.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        selectedTransactionIds
            .addAll(currentPageData.map((t) => t.transaction.id));
      } else {
        selectedTransactionIds
            .removeAll(currentPageData.map((t) => t.transaction.id));
      }
    });
  }

  void toggleSelectOne(int transactionId, bool? value) {
    setState(() {
      if (value == true) {
        selectedTransactionIds.add(transactionId);
      } else {
        selectedTransactionIds.remove(transactionId);
      }
    });
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = _startDate == null || _endDate == null
          ? await widget.transactionRepository
              .getAllTransactionsWithCustomerUser()
          : await widget.transactionRepository
              .getTransactionsByDateRange(_startDate!, _endDate!);
      setState(() => _transactionList = transactions);
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleDateRangeSelected(DateTime? start, DateTime? end) {
    setState(() {
      _startDate = start;
      _endDate = end;
      currentPage = 1;
    });
    _loadTransactions();
  }

  List<TransactionWithCustomerUser> get sortedTransactionData {
    List<TransactionWithCustomerUser> sorted = List.from(_transactionList);
    sorted.sort((a, b) {
      dynamic valueA;
      dynamic valueB;

      switch (sortBy) {
        case 'customerName':
          valueA = a.customerName;
          valueB = b.customerName;
          break;
        case 'amount':
          valueA = a.transaction.finalPrice;
          valueB = b.transaction.finalPrice;
          break;
        case 'paymentMethod':
          valueA = a.transaction.paymentMethod;
          valueB = b.transaction.paymentMethod;
          break;
        case 'date':
          valueA = a.transaction.createdAt;
          valueB = b.transaction.createdAt;
          break;
        case 'addedBy':
          valueA = a.addedBy;
          valueB = b.addedBy;
          break;
        default:
          valueA = a.transaction.createdAt;
          valueB = b.transaction.createdAt;
      }

      int result = valueA.toString().compareTo(valueB.toString());
      return isAscending ? result : -result;
    });
    return sorted;
  }

  List<TransactionWithCustomerUser> get currentPageData {
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    return sortedTransactionData.sublist(
        start,
        end > sortedTransactionData.length
            ? sortedTransactionData.length
            : end);
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
    final totalPages = (sortedTransactionData.length / itemsPerPage).ceil();
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage > sortedTransactionData.length)
        ? sortedTransactionData.length
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
          TransactionTableSearch(
            currentPageData: currentPageData,
            data: sortedTransactionData,
            onDateRangeSelected: _handleDateRangeSelected,
            onAddNew: widget.onAddNew,
            onPrintReport: widget.onPrintReport,
          ),

          // Header
          TransactionTableHeader(
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
                : sortedTransactionData.isEmpty
                    ? const Center(child: Text('Tidak ada data transaksi'))
                    : Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: currentPageData
                                .map((t) => TransactionTableRow(
                                      transaction: t.transaction,
                                      customerName: t.customerName,
                                      customerPhone: t.customerPhone,
                                      discountDisplay: t.discountDisplay,
                                      addedBy: t.addedBy,
                                      key: ValueKey(t.transaction.id),
                                      isSelected: selectedTransactionIds
                                          .contains(t.transaction.id),
                                      onSelectChanged: (value) =>
                                          toggleSelectOne(
                                              t.transaction.id, value),
                                      onViewDetail: () =>
                                          widget.onViewDetail(t.transaction.id),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
          ),

          // Pagination
          if (!_isLoading && sortedTransactionData.isNotEmpty)
            TransactionTablePagination(
              currentPage: currentPage,
              totalPages: totalPages,
              startItem: startItem,
              endItem: endItem,
              totalItems: sortedTransactionData.length,
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
