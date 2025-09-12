import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meko_poin/models/additional/daily_report.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:meko_poin/views/Dashboard/components/table/transaction_table/transaction_table_pagination.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/daily_report_service.dart';

class CardPenjualanHarian extends StatefulWidget {
  final TransactionRepository transactionRepository;

  const CardPenjualanHarian({super.key, required this.transactionRepository});

  @override
  State<CardPenjualanHarian> createState() => _CardPenjualanHarianState();
}

class _CardPenjualanHarianState extends State<CardPenjualanHarian> {
  List<Map<String, dynamic>> _availableMonths = [];
  Map<String, dynamic>? _selectedMonth;
  List<DailyReport> _allDailyReports = [];
  List<DailyReport> _sortedDailyReports = [];
  bool _isLoading = false;

  // Sorting state
  String _sortBy = 'date';
  bool _isAscending = false;

  // Pagination state
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadAvailableMonths();
  }

  void _exportToExcel() async {
    if (_selectedMonth == null || _sortedDailyReports.isEmpty) return;

    final monthYear = _formatMonthYear(_selectedMonth!);

    await DailyReportExportService.exportDailyReportsToExcel(
      dailyReports: _sortedDailyReports,
      monthYear: monthYear,
      context: context,
    );
  }

  Future<void> _loadAvailableMonths() async {
    try {
      final months = await widget.transactionRepository.getAvailableMonths();
      setState(() {
        _availableMonths = months;
        if (_availableMonths.isNotEmpty) {
          // Pastikan selectedMonth ada dalam availableMonths
          _selectedMonth = _availableMonths.first;
          _loadDailyReports();
        }
      });
    } catch (e) {
      debugPrint('Error loading available months: $e');
    }
  }

  Future<void> _loadDailyReports() async {
    if (_selectedMonth == null) return;

    setState(() => _isLoading = true);
    try {
      final year = int.parse(_selectedMonth!['year'] as String);
      final month = int.parse(_selectedMonth!['month'] as String);

      final reports = await widget.transactionRepository
          .getDailyReportsByMonth(year, month);
      setState(() {
        _allDailyReports = reports;
        _applySorting();
        _currentPage = 1;
      });
    } catch (e) {
      debugPrint('Error loading daily reports: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onMonthChanged(Map<String, dynamic>? newValue) {
    if (newValue == null) return;

    setState(() {
      _selectedMonth = newValue;
    });
    _loadDailyReports();
  }

  void _applySorting() {
    List<DailyReport> sorted = List.from(_allDailyReports);

    sorted.sort((a, b) {
      dynamic valueA;
      dynamic valueB;

      switch (_sortBy) {
        case 'date':
          valueA = a.date;
          valueB = b.date;
          break;
        case 'customerCount':
          valueA = a.customerCount;
          valueB = b.customerCount;
          break;
        case 'totalRevenue':
          valueA = a.totalRevenue;
          valueB = b.totalRevenue;
          break;
        case 'totalCash':
          valueA = a.totalCash;
          valueB = b.totalCash;
          break;
        case 'totalQris':
          valueA = a.totalQris;
          valueB = b.totalQris;
          break;
        case 'totalSales':
          valueA = a.totalSales;
          valueB = b.totalSales;
          break;
        default:
          valueA = a.date;
          valueB = b.date;
      }

      if (valueA is DateTime && valueB is DateTime) {
        return _isAscending
            ? valueA.compareTo(valueB)
            : valueB.compareTo(valueA);
      } else if (valueA is num && valueB is num) {
        return _isAscending
            ? valueA.compareTo(valueB)
            : valueB.compareTo(valueA);
      }

      return _isAscending
          ? valueA.toString().compareTo(valueB.toString())
          : valueB.toString().compareTo(valueA.toString());
    });

    setState(() => _sortedDailyReports = sorted);
  }

  void _onSort(String column) {
    setState(() {
      if (_sortBy == column) {
        _isAscending = !_isAscending;
      } else {
        _sortBy = column;
        _isAscending = true;
      }
      _applySorting();
    });
  }

  Icon _sortIcon(String column) {
    if (_sortBy != column) {
      return const Icon(
        Icons.unfold_more,
        size: 14,
        color: CustomColors.fontSubColor,
      );
    }
    return Icon(
      _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
      size: 14,
      color: CustomColors.fontSubColor,
    );
  }

  List<DailyReport> get _currentPageData {
    int start = (_currentPage - 1) * _itemsPerPage;
    int end = start + _itemsPerPage;
    return _sortedDailyReports.sublist(
      start,
      end > _sortedDailyReports.length ? _sortedDailyReports.length : end,
    );
  }

  String _formatMonthYear(Map<String, dynamic> monthData) {
    final year = monthData['year'] as String;
    final month = monthData['month'] as String;
    final date = DateTime(int.parse(year), int.parse(month), 1);
    return DateFormat('MMMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_sortedDailyReports.length / _itemsPerPage).ceil();
    final startItem = (_currentPage - 1) * _itemsPerPage + 1;
    final endItem = (_currentPage * _itemsPerPage > _sortedDailyReports.length)
        ? _sortedDailyReports.length
        : _currentPage * _itemsPerPage;

    return Container(
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        border: Border.all(color: CustomColors.borderCardColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filter Section dengan Title di Kiri
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Diubah dari end ke spaceBetween
              children: [
                // Title di sebelah kiri
                const Text(
                  'Catatan Penjualan Bulanan', // Title baru
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // Filter dropdown di sebelah kanan
                Row(
                  children: [
                    const Text(
                      'Pilih Bulan:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 200,
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: CustomColors.inputColor,
                        border:
                            Border.all(color: CustomColors.borderInputColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Map<String, dynamic>>(
                          value: _selectedMonth,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                          dropdownColor: CustomColors.inputColor,
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: CustomColors.fontSubColor),
                          onChanged: _onMonthChanged,
                          items: _availableMonths.map((month) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: month,
                              child: Text(
                                _formatMonthYear(month),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tombol Export Excel
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF0BC33F), // Green background
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(color: Color(0xFF0BC33F)),
                        ),
                        minimumSize: const Size(108, 40),
                      ),
                      onPressed:
                          _sortedDailyReports.isEmpty ? null : _exportToExcel,
                      child: const Text(
                        'Cetak Laporan',
                        style: TextStyle(
                          color: Colors.white, // White text color
                          fontFamily: 'Inter',
                          fontSize: 12,
                          height: 1.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table Header dengan Sorting
          _DailyReportHeader(
            sortBy: _sortBy,
            isAscending: _isAscending,
            onSort: _onSort,
            sortIcon: _sortIcon,
          ),

          // Table Body
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 200,
                maxHeight: 400,
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _sortedDailyReports.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada data untuk bulan ini',
                            style: TextStyle(
                              color: CustomColors.fontSubColor,
                              fontFamily: 'Inter',
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: _currentPageData.length,
                          itemBuilder: (context, index) {
                            final report = _currentPageData[index];
                            return _DailyReportRow(report: report);
                          },
                        ),
            ),
          ),

          // Pagination
          if (!_isLoading && _sortedDailyReports.isNotEmpty)
            TransactionTablePagination(
              currentPage: _currentPage,
              totalPages: totalPages,
              startItem: startItem,
              endItem: endItem,
              totalItems: _sortedDailyReports.length,
              itemsPerPage: _itemsPerPage,
              onItemsPerPageChanged: (value) {
                setState(() {
                  _itemsPerPage = value;
                  _currentPage = 1;
                });
              },
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
            ),
        ],
      ),
    );
  }
}

class _DailyReportHeader extends StatelessWidget {
  final String sortBy;
  final bool isAscending;
  final Function(String) onSort;
  final Icon Function(String) sortIcon;

  const _DailyReportHeader({
    required this.sortBy,
    required this.isAscending,
    required this.onSort,
    required this.sortIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: () => onSort('date'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: CustomColors.borderCardColor),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          'Tanggal',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: CustomColors.fontSubColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 4),
                        sortIcon('date'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => onSort('customerCount'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: CustomColors.borderCardColor),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Jumlah Pelanggan',
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                              color: CustomColors.fontSubColor,
                              fontFamily: 'Inter',
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        sortIcon('customerCount'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => onSort('totalRevenue'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: CustomColors.borderCardColor),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: CustomColors.fontSubColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 4),
                        sortIcon('totalRevenue'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => onSort('totalCash'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: CustomColors.borderCardColor),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Tunai',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: CustomColors.fontSubColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 4),
                        sortIcon('totalCash'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => onSort('totalQris'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: CustomColors.borderCardColor),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          'Total QRIS',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: CustomColors.fontSubColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 4),
                        sortIcon('totalQris'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => onSort('totalSales'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          'Penjualan',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: CustomColors.fontSubColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 4),
                        sortIcon('totalSales'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyReportRow extends StatelessWidget {
  final DailyReport report;
  final NumberFormat currencyFormat = NumberFormat('#,###');

  _DailyReportRow({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 55),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: CustomColors.borderCardColor)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: CustomColors.borderCardColor),
                  ),
                ),
                child: Text(
                  DateFormat('d MMMM yyyy').format(report.date),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: CustomColors.borderCardColor),
                  ),
                ),
                child: Text(
                  // report.customerCount.toString(),
                  report.totalSales.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: CustomColors.borderCardColor),
                  ),
                ),
                child: Text(
                  'Rp ${currencyFormat.format(report.totalRevenue)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: CustomColors.borderCardColor),
                  ),
                ),
                child: Text(
                  'Rp ${currencyFormat.format(report.totalCash)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: CustomColors.borderCardColor),
                  ),
                ),
                child: Text(
                  'Rp ${currencyFormat.format(report.totalQris)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                child: Text(
                  // report.totalSales.toInt().toString(),
                  'Rp ${currencyFormat.format(report.totalRevenue)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
