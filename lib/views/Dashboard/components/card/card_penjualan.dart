import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SalesData {
  final String time;
  final double sales;
  final double change;

  SalesData(this.time, this.sales, this.change);
}

class CardPenjualan extends StatelessWidget {
  const CardPenjualan({super.key});

  @override
  Widget build(BuildContext context) {
    final List<SalesData> chartData = [
      SalesData("00.00", 30000, 0),
      SalesData("01.00", 22000, 0),
      SalesData("02.00", 28000, 0),
      SalesData("03.00", 18000, 0),
      SalesData("04.00", 25000, 0),
      SalesData("05.00", 20000, 0),
      SalesData("06.00", 50000, 24),
      SalesData("07.00", 45000, 0),
      SalesData("08.00", 23000, 0),
      SalesData("09.00", 17000, 0),
      SalesData("10.00", 24000, 0),
      SalesData("11.00", 20000, 0),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      height: 395,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              'Penjualan Hari Ini',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
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
                          color: Colors.black.withOpacity(0.15),
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
                          "${sales.time}, Sales",
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                "Rp${sales.sales.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}",
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
              ),
              primaryYAxis: NumericAxis(
                labelFormat: '{value}k',
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                majorGridLines: MajorGridLines(color: Colors.grey.shade200),
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
