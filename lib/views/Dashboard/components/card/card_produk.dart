import 'package:flutter/material.dart';
import 'package:meko_poin/models/additional/favorite_product.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class _ChartData {
  final String label;
  final String category;
  final double value;
  final Color color;

  _ChartData(this.label, this.category, this.value, this.color);
}

class CardProduk extends StatelessWidget {
  final TransactionRepository transactionRepo;

  const CardProduk({super.key, required this.transactionRepo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: transactionRepo.getFavoriteProducts(),
      builder: (context, snapshot) {
        // Tampilkan loading indicator saat data dimuat
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        // Tampilkan error message jika terjadi error
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        // Tampilkan empty state jika tidak ada data
        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        // Proses data untuk chart
        final favoriteProducts =
            snapshot.data!.map((e) => FavoriteProduct.fromMap(e)).toList();

        // Siapkan warna untuk chart
        final List<Color> colorPalette = [
          Color(0xFF007ed5),
          Color(0xFF8399ec),
          Color(0xFF8c6dee),
          Color(0xFF9c46cf),
          Color(0xFFc658cf),
          Color(0xFFdf1e84),
          Color(0xFFfd0000),
          Color(0xFFff7300),
          Color(0xFFffaf00),
          Color(0xFFffec00),
          Color(0xFFd6f30d),
          Color(0xFF52d726),
          Color(0xFF1ba92f),
          Color(0xFF2fc975),
          Color(0xFF24d7ad),
          Color(0xFF7bdddc),
          Color(0xFF60b7d3),
          Color(0xFF95d9fc),
        ];

        // Buat chart data
        final List<_ChartData> chartData = [];
        for (int i = 0; i < favoriteProducts.length; i++) {
          chartData.add(
            _ChartData(
              favoriteProducts[i].name,
              favoriteProducts[i].category,
              favoriteProducts[i].totalQty.toDouble(),
              colorPalette[i % colorPalette.length],
            ),
          );
        }

        return _buildChart(chartData);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 370,
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
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
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 370,
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
      child: Center(
        child: Text(
          'Error: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 370,
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CustomColors.borderCardColor),
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
                fontSize: 16,
                height: 1.0,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Tidak ada transaksi hari ini',
              style: TextStyle(color: CustomColors.fontSubColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<_ChartData> chartData) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 450,
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CustomColors.borderCardColor),
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
                fontSize: 16,
                height: 1.0,
                fontWeight: FontWeight.w600,
                color: Colors.white,
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
                        dataLabelMapper: (data, _) => '${data.value.toInt()}',
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: false,
                          textStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                    tooltipBehavior: TooltipBehavior(
                      enable: true,
                      format: 'point.x : point.y',
                      header: 'Jumlah Terjual',
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Legend
                  // Legend dengan Wrap yang bisa di-scroll horizontal dan vertical
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          direction: Axis.horizontal,
                          spacing: 16.0,
                          runSpacing: 12.0,
                          children: chartData.map((data) {
                            return ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
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
                                  Flexible(
                                    child: Text(
                                      data.category == 'Background'
                                          ? 'Background ${data.label}'
                                          : data.label,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
