import 'package:flutter/material.dart';
import 'package:meko_poin/services/master_data_repository.dart';
import 'package:meko_poin/services/transaction_item_repository.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_table_pagination.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class CardKertasTerjual extends StatefulWidget {
  final MasterDataRepository masterDataRepo;
  final TransactionItemRepository transactionItemRepo;
  final DateTimeRange dateRange;

  const CardKertasTerjual(
      {super.key,
      required this.masterDataRepo,
      required this.transactionItemRepo,
      required this.dateRange});

  @override
  State<CardKertasTerjual> createState() => _CardKertasTerjualState();
}

class _CardKertasTerjualState extends State<CardKertasTerjual> {
  int currentPage = 1;
  int itemsPerPage = 5;
  List<Map<String, dynamic>> summaryData = [];
  bool isLoading = true;
  String errorMessage = '';
  String sortBy = 'item'; // default sort
  bool isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadSummaryData();
  }

  @override
  void didUpdateWidget(covariant CardKertasTerjual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateRange.start != widget.dateRange.start ||
        oldWidget.dateRange.end != widget.dateRange.end) {
      _loadSummaryData();
    }
  }

  Future<void> _loadSummaryData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Get master data with category 'Product' and 'Background'
      final masterDataList = await widget.masterDataRepo.getAllMasterData();
      final filteredMasterData = masterDataList.where((data) {
        final code = (data.categoryCode ?? '').toLowerCase();
        return code == 'paper' || data.category == 'Paper';
      }).toList();

      // Get transaction items for this month
      final transactionItems = await widget.transactionItemRepo
          .getTransactionItemsByDateRange(
              widget.dateRange.start, widget.dateRange.end);

      // Create summary data
      final List<Map<String, dynamic>> tempSummaryData = [];

      for (final masterData in filteredMasterData) {
        final relatedTransactions = transactionItems
            .where((item) => item.masterDataId == masterData.id)
            .toList();

        final totalQty =
            relatedTransactions.fold(0, (sum, item) => sum + item.qty);

        if (totalQty > 0) {
          tempSummaryData.add({
            'masterData': masterData,
            'totalQty': totalQty,
          });
        }
      }

      setState(() {
        summaryData = tempSummaryData;
        currentPage = 1;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat data: ${e.toString()}';
      });
    }
  }

  List<Map<String, dynamic>> get sortedData {
    List<Map<String, dynamic>> sorted = List.from(summaryData);
    sorted.sort((a, b) {
      int result;
      switch (sortBy) {
        case 'item':
          result = a['masterData'].name.compareTo(b['masterData'].name);
          break;
        case 'total':
          result = a['totalQty'].compareTo(b['totalQty']);
          break;
        default:
          result = a['masterData'].name.compareTo(b['masterData'].name);
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
    const double cardHeight = 365;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }

    final totalPages = (summaryData.length / itemsPerPage).ceil();
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage > summaryData.length)
        ? summaryData.length
        : currentPage * itemsPerPage;

    return Container(
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        border: Border.all(color: CustomColors.borderCardColor),
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: BoxConstraints(
        minHeight: cardHeight,
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Kertas Terjual',
            style: TextStyle(
              fontSize: 16,
              height: 1.0,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 16),

          // Table Header
          Container(
            decoration: BoxDecoration(
              color: CustomColors.cardColor,
              border: Border(
                top: BorderSide(color: CustomColors.borderCardColor),
                bottom: BorderSide(color: CustomColors.borderCardColor),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Kolom Item
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: () => onSort('item'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                              right: BorderSide(
                                  color: CustomColors.borderCardColor)),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text('Item',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                    color: CustomColors.fontSubColor,
                                    fontFamily: 'Inter',
                                  )),
                              const SizedBox(width: 4),
                              _sortIcon('item'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Kolom Total
                  Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: () => onSort('total'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                'Jumlah',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                  color: CustomColors.fontSubColor,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(width: 4),
                              _sortIcon('total'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (summaryData.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: const Center(
                child: Text(
                  'Tidak ada data transaksi bulan ini',
                  style: TextStyle(
                    fontSize: 14,
                    color: CustomColors.fontSubColor,
                  ),
                ),
              ),
            )
          else
            ...currentPageData.map((data) => Container(
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: CustomColors.borderCardColor)),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        // Kolom Item
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18.0, vertical: 18.0),
                            child: Text(
                              data['masterData'].name,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.1,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                        const VerticalDivider(
                            thickness: 1,
                            width: 1,
                            color: CustomColors.borderCardColor),

                        // Kolom Total
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18.0, vertical: 18.0),
                            child: Text(
                              data['totalQty'].toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.1,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Inter',
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),

          // Pagination
          if (summaryData.length > itemsPerPage)
            CardTablePagination(
              currentPage: currentPage,
              totalPages: totalPages,
              startItem: startItem,
              endItem: endItem,
              totalItems: summaryData.length,
              itemsPerPage: itemsPerPage,
              onItemsPerPageChanged: (value) {
                setState(() {
                  itemsPerPage = value;
                  currentPage = 1;
                });
              },
              onPageChanged: (page) => setState(() => currentPage = page),
            ),
        ],
      ),
    );
  }
}
