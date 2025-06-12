import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CardProduk extends StatelessWidget {
  const CardProduk({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_ChartData> chartData = [
      _ChartData('Self Photo', 30, Colors.blue),
      _ChartData('Self Photo', 25, Colors.orange),
      _ChartData('Self Photo', 20, Colors.green),
      _ChartData('Self Photo', 15, Colors.purple),
      _ChartData('Self Photo', 10, Colors.yellow),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      height: 410,
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
        children: [
          const Center(
            child: Text(
              'Produk Terfavorit',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Chart
                  SfCircularChart(
                    margin: EdgeInsets.zero,
                    series: <DoughnutSeries<_ChartData, String>>[
                      DoughnutSeries<_ChartData, String>(
                        dataSource: chartData,
                        pointColorMapper: (data, _) => data.color,
                        xValueMapper: (data, _) => data.label,
                        yValueMapper: (data, _) => data.value,
                        radius: '90%',
                        innerRadius: '60%',
                      )
                    ],
                    tooltipBehavior: TooltipBehavior(enable: true),
                  ),
                  const SizedBox(width: 24),
                  // Legend
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: chartData.map((data) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: data.color,
                              ),
                            ),
                            Text(
                              data.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter',
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  final String label;
  final double value;
  final Color color;

  _ChartData(this.label, this.value, this.color);
}
