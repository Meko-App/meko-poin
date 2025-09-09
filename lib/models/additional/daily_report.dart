import 'package:intl/intl.dart';

class DailyReport {
  final DateTime date;
  final int customerCount;
  final double totalRevenue;
  final double totalCash;
  final double totalQris;
  final double totalSales;

  DailyReport({
    required this.date,
    required this.customerCount,
    required this.totalRevenue,
    required this.totalCash,
    required this.totalQris,
    required this.totalSales,
  });

  // Helper methods for sorting
  String get dateString => DateFormat('yyyy-MM-dd').format(date);
}
