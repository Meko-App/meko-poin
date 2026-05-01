import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meko_poin/models/transaction.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class SalesData {
  final String time;
  final double sales;
  final double change;

  SalesData(this.time, this.sales, this.change);
}

class CardPenjualan extends StatefulWidget {
  final DateTimeRange dateRange;

  const CardPenjualan({super.key, required this.dateRange});

  @override
  State<CardPenjualan> createState() => _CardPenjualanState();
}

class _CardPenjualanState extends State<CardPenjualan> {
  late final TransactionRepository transactionRepo;

  @override
  void initState() {
    super.initState();
    transactionRepo = TransactionRepository(DatabaseHelper.instance);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Transaction>>(
      future: transactionRepo.getGraphTransactionsByDateRange(
        widget.dateRange.start,
        widget.dateRange.end,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final transactions = snapshot.data ?? [];
        return _buildChart(transactions);
      },
    );
  }

  Widget _buildChart(List<Transaction> transactions) {
    // Group transactions by hour and calculate total sales for each hour
    final Map<String, double> hourlySales = {};

    for (final transaction in transactions) {
      final hour = DateFormat('HH').format(transaction.createdAt);
      final formattedHour = '$hour.00';

      hourlySales.update(
        formattedHour,
        (value) => value + transaction.finalPrice,
        ifAbsent: () => transaction.finalPrice.toDouble(),
      );
    }

    // Fill all 24 hours with data
    final List<SalesData> chartData = [];
    for (int i = 0; i < 24; i++) {
      final hour = i.toString().padLeft(2, '0');
      final formattedHour = '$hour.00';
      final currentSales = hourlySales[formattedHour] ?? 0.0;

      double change = 0.0;
      if (i > 0) {
        final prevHour = (i - 1).toString().padLeft(2, '0');
        final prevFormattedHour = '$prevHour.00';
        final prevSales = hourlySales[prevFormattedHour] ?? 0.0;

        if (prevSales > 0) {
          change = ((currentSales - prevSales) / prevSales) * 100;
        }
      }

      chartData.add(SalesData(formattedHour, currentSales, change));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      height: 450,
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CustomColors.borderCardColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Penjualan',
              style: TextStyle(
                fontSize: 16,
                height: 1.0,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SfCartesianChart(
              tooltipBehavior: TooltipBehavior(
                enable: true,
                builder: (dynamic data, dynamic point, dynamic series,
                    int pointIndex, int seriesIndex) {
                  final SalesData sales = data;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    width: 160,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Penjualan pada ${sales.time}",
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                "Rp ${sales.sales.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (sales.change != 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: sales.change > 0
                                      ? Colors.green[50]
                                      : Colors.red[50],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${sales.change > 0 ? '+' : ''}${sales.change.toStringAsFixed(0)}%",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: sales.change > 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                interval: 3,
              ),
              primaryYAxis: NumericAxis(
                labelFormat: '{value}k',
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                majorGridLines:
                    MajorGridLines(color: CustomColors.borderInputColor),
              ),
              series: <ChartSeries>[
                SplineSeries<SalesData, String>(
                  dataSource: chartData,
                  xValueMapper: (SalesData data, _) => data.time,
                  yValueMapper: (SalesData data, _) => data.sales / 1000,
                  color: const Color(0xFF3B82F6),
                  width: 2,
                  markerSettings: const MarkerSettings(isVisible: true),
                  enableTooltip: true,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
