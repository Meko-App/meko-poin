import 'package:flutter/material.dart';
import 'package:meko_poin/models/transaction.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'attendance_table_header.dart';
import 'attendance_table_row.dart';
import 'attendance_table_pagination.dart';
import 'attendance_table_search.dart';

class AttendanceTable extends StatefulWidget {
  final TransactionRepository transactionRepository;
  final int userId;

  const AttendanceTable({
    super.key,
    required this.transactionRepository,
    required this.userId,
  });

  @override
  State<AttendanceTable> createState() => _AttendanceTableState();
}

class _AttendanceTableState extends State<AttendanceTable> {
  List<Transaction> _transactions = [];
  List<Transaction> _allTransactions = []; // Menyimpan semua transaksi
  bool _isLoading = true;
  int currentPage = 1;
  int itemsPerPage = 10;
  String sortBy = 'date';
  bool isAscending = false; // Default descending untuk tampilkan terbaru dulu
  int? _filterYear;
  int? _filterMonth;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      // Load semua transaksi untuk filter
      final allTransactions =
          await widget.transactionRepository.getAllTransactions();

      // Load transaksi bulan ini untuk tampilan awal
      final thisMonthTransactions =
          await widget.transactionRepository.getAllTransactionsThisMonth();

      final userAllTransactions = allTransactions
          .where((transaction) => transaction.userId == widget.userId)
          .toList();

      final userThisMonthTransactions = thisMonthTransactions
          .where((transaction) => transaction.userId == widget.userId)
          .toList();

      setState(() {
        _allTransactions = userAllTransactions;
        _transactions = userThisMonthTransactions;
        // Biarkan _filterYear dan _filterMonth null (kosong)
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Method untuk filter transaksi berdasarkan tahun/bulan
  void _applyFilter(int? year, int? month) {
    setState(() {
      _filterYear = year;
      _filterMonth = month;
      currentPage = 1;

      if (year == null && month == null) {
        // Jika tidak ada filter, tampilkan data bulan ini
        _loadThisMonthData();
      } else {
        // Filter transaksi berdasarkan tahun/bulan
        _transactions = _allTransactions.where((transaction) {
          final transactionDate = transaction.createdAt;
          if (year != null && transactionDate.year != year) return false;
          if (month != null && transactionDate.month != month) return false;
          return true;
        }).toList();
      }
    });
  }

  // Method untuk load data bulan ini
  Future<void> _loadThisMonthData() async {
    try {
      final thisMonthTransactions =
          await widget.transactionRepository.getAllTransactionsThisMonth();

      final userThisMonthTransactions = thisMonthTransactions
          .where((transaction) => transaction.userId == widget.userId)
          .toList();

      setState(() {
        _transactions = userThisMonthTransactions;
      });
    } catch (e) {
      debugPrint('Error loading this month data: $e');
    }
  }

  // Group transactions by date
  Map<String, List<Transaction>> get groupedTransactions {
    final Map<String, List<Transaction>> grouped = {};
    for (var transaction in _transactions) {
      final dateKey = _formatDate(transaction.createdAt);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }
    return grouped;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDisplayDate(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) return dateKey;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) return dateKey;

    return '$day ${_getMonthName(month)} $year';
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Januari';
      case 2:
        return 'Februari';
      case 3:
        return 'Maret';
      case 4:
        return 'April';
      case 5:
        return 'Mei';
      case 6:
        return 'Juni';
      case 7:
        return 'Juli';
      case 8:
        return 'Agustus';
      case 9:
        return 'September';
      case 10:
        return 'Oktober';
      case 11:
        return 'November';
      case 12:
        return 'Desember';
      default:
        return 'Bulan $month';
    }
  }

  int _getTransactionCount(List<Transaction> transactions) {
    return transactions.length;
  }

  int _getTotalRevenue(List<Transaction> transactions) {
    return transactions.fold(
        0, (sum, transaction) => sum + transaction.finalPrice);
  }

  String _formatCurrency(int amount) {
    if (amount == 0) return 'Rp 0';

    return 'Rp ${amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  List<Map<String, dynamic>> get dailyReports {
    final grouped = groupedTransactions;
    return grouped.entries.map((entry) {
      final totalRevenue = _getTotalRevenue(entry.value);
      return {
        'date': entry.key,
        'displayDate': _formatDisplayDate(entry.key),
        'transactionCount': _getTransactionCount(entry.value),
        'totalRevenue': totalRevenue,
        'formattedRevenue': _formatCurrency(totalRevenue),
      };
    }).toList();
  }

  List<Map<String, dynamic>> get sortedDailyReports {
    List<Map<String, dynamic>> sorted = List.from(dailyReports);
    sorted.sort((a, b) {
      int result;
      switch (sortBy) {
        case 'date':
          result = a['date'].compareTo(b['date']);
          break;
        case 'transactions':
          result = a['transactionCount'].compareTo(b['transactionCount']);
          break;
        case 'revenue':
          result = a['totalRevenue'].compareTo(b['totalRevenue']);
          break;
        default:
          result = a['date'].compareTo(b['date']);
      }
      return isAscending ? result : -result;
    });
    return sorted;
  }

  List<Map<String, dynamic>> get currentPageData {
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    return sortedDailyReports.sublist(start,
        end > sortedDailyReports.length ? sortedDailyReports.length : end);
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

  // Method untuk mendapatkan semua daily reports (tanpa filter)
  List<Map<String, dynamic>> _getAllDailyReports() {
    final Map<String, List<Transaction>> allGrouped = {};
    for (var transaction in _allTransactions) {
      final dateKey = _formatDate(transaction.createdAt);
      if (!allGrouped.containsKey(dateKey)) {
        allGrouped[dateKey] = [];
      }
      allGrouped[dateKey]!.add(transaction);
    }

    return allGrouped.entries.map((entry) {
      final totalRevenue = _getTotalRevenue(entry.value);
      return {
        'date': entry.key,
        'displayDate': _formatDisplayDate(entry.key),
        'transactionCount': _getTransactionCount(entry.value),
        'totalRevenue': totalRevenue,
        'formattedRevenue': _formatCurrency(totalRevenue),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (sortedDailyReports.length / itemsPerPage).ceil();
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage > sortedDailyReports.length)
        ? sortedDailyReports.length
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
          AttendanceTableSearch(
            data: _getAllDailyReports(),
            data2: sortedDailyReports,
            currentPageData: currentPageData,
            currentYear: _filterYear,
            currentMonth: _filterMonth,
            onFilterChanged: _applyFilter,
          ),

          // Header
          AttendanceTableHeader(
            sortBy: sortBy,
            isAscending: isAscending,
            onSort: onSort,
            sortIcon: _sortIcon,
          ),

          // Body
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : sortedDailyReports.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'Tidak ada data kehadiran',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  : Column(
                      children: currentPageData
                          .map((report) => AttendanceTableRow(
                                date: report['displayDate'],
                                transactionCount:
                                    report['transactionCount'].toString(),
                                revenue: report['formattedRevenue'],
                              ))
                          .toList(),
                    ),

          // Pagination
          if (!_isLoading && sortedDailyReports.isNotEmpty)
            AttendanceTablePagination(
              currentPage: currentPage,
              totalPages: totalPages,
              startItem: startItem,
              endItem: endItem,
              data: sortedDailyReports,
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
