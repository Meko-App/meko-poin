import 'package:flutter/material.dart';
import 'package:meko_poin/services/kas_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:meko_poin/views/Dashboard/components/table/kas_table/kas_table_pagination.dart';
import 'package:intl/intl.dart';

class KasDetailTable extends StatefulWidget {
  final KasRepository kasRepository;
  final DateTime selectedMonth;
  final VoidCallback onBack;

  const KasDetailTable({
    super.key,
    required this.kasRepository,
    required this.selectedMonth,
    required this.onBack,
  });

  @override
  State<KasDetailTable> createState() => _KasDetailTableState();
}

class _KasDetailTableState extends State<KasDetailTable> {
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  int itemsPerPage = 10;
  List<dynamic> _kasDetailList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKasDetailData();
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

  List<dynamic> get currentPageData {
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    return _kasDetailList.sublist(
        start, end > _kasDetailList.length ? _kasDetailList.length : end);
  }

  String formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_kasDetailList.length / itemsPerPage).ceil();
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage > _kasDetailList.length)
        ? _kasDetailList.length
        : currentPage * itemsPerPage;

    final monthName =
        DateFormat('MMMM yyyy', 'id_ID').format(widget.selectedMonth);

    return Container(
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        border: Border.all(color: CustomColors.borderCardColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header dengan bulan dan tombol back
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: CustomColors.borderCardColor),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: widget.onBack,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  'Detail Kas - $monthName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _kasDetailList.isEmpty
                    ? const Center(child: Text('Tidak ada data transaksi'))
                    : Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Table Header
                              Container(
                                decoration: BoxDecoration(
                                  color: CustomColors.cardColor,
                                  border: Border(
                                    top: BorderSide(
                                        color: CustomColors.borderCardColor),
                                    bottom: BorderSide(
                                        color: CustomColors.borderCardColor),
                                  ),
                                ),
                                child: const IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 18, vertical: 12),
                                          child: Text(
                                            'Tanggal',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                              color: CustomColors.fontSubColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 18, vertical: 12),
                                          child: Text(
                                            'Keterangan',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                              color: CustomColors.fontSubColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 18, vertical: 12),
                                          child: Text(
                                            'Jenis',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                              color: CustomColors.fontSubColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 18, vertical: 12),
                                          child: Text(
                                            'Jumlah',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                              color: CustomColors.fontSubColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Table Rows
                              ...currentPageData
                                  .map((kas) => Container(
                                        constraints:
                                            const BoxConstraints(minHeight: 55),
                                        decoration: BoxDecoration(
                                          border: Border(
                                              bottom: BorderSide(
                                                  color: CustomColors
                                                      .borderCardColor)),
                                        ),
                                        child: IntrinsicHeight(
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 18,
                                                      vertical: 20),
                                                  child: Text(
                                                    formatDate(kas.cashDate),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 3,
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 18,
                                                      vertical: 20),
                                                  child: Text(
                                                    kas.description,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 18,
                                                      vertical: 20),
                                                  child: Text(
                                                    kas.type == 'income'
                                                        ? 'Pemasukan'
                                                        : 'Pengeluaran',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: kas.type ==
                                                              'income'
                                                          ? Colors.green[300]
                                                          : Colors.red[300],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 18,
                                                      vertical: 20),
                                                  child: Text(
                                                    formatCurrency(kas.amount),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: kas.type ==
                                                              'income'
                                                          ? Colors.green[300]
                                                          : Colors.red[300],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ],
                          ),
                        ),
                      ),
          ),

          // Pagination
          if (!_isLoading && _kasDetailList.isNotEmpty)
            KasTablePagination(
              currentPage: currentPage,
              totalPages: totalPages,
              startItem: startItem,
              endItem: endItem,
              data: _kasDetailList,
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
