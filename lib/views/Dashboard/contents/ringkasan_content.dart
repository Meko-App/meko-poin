import 'package:flutter/material.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/inventory_log_repository.dart';
import 'package:meko_poin/services/master_data_repository.dart';
import 'package:meko_poin/services/transaction_item_repository.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:meko_poin/views/Dashboard/components/date_range_filter.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_gudang.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_kertas_terjual.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_pelanggan.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_penjualan.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_penjualan_harian.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_plastik_terpakai.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_produk.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_produk_terjual.dart';

class RingkasanContent extends StatefulWidget {
  const RingkasanContent({super.key});

  @override
  State<RingkasanContent> createState() => _RingkasanContentState();
}

class _RingkasanContentState extends State<RingkasanContent> {
  late DateTimeRange _selectedDateRange;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _selectedDateRange = DateTimeRange(
      start: today.subtract(const Duration(days: 30)),
      end: today,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Dashboard",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text("Data ringkasan berdasarkan rentang tanggal terpilih",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF9A9CAE))),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: DateRangeFilter(
              key: const ValueKey('dashboard-summary-date-range-filter'),
              initialStartDate: _selectedDateRange.start,
              initialEndDate: _selectedDateRange.end,
              width: 260,
              onDateRangeSelected: (start, end) {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                setState(() {
                  _selectedDateRange = DateTimeRange(
                    start: start ?? today.subtract(const Duration(days: 30)),
                    end: end ?? today,
                  );
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                // Desktop/tablet
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: CardPelanggan(
                          transactionRepo:
                              TransactionRepository(DatabaseHelper.instance),
                          dateRange: _selectedDateRange,
                        )),
                        const SizedBox(width: 24),
                        Expanded(
                            child:
                                CardPenjualan(dateRange: _selectedDateRange)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: CardGudang(
                          inventoryLogRepo:
                              InventoryLogRepository(DatabaseHelper.instance),
                          dateRange: _selectedDateRange,
                        )),
                        const SizedBox(width: 24),
                        Expanded(
                            child: CardProduk(
                          transactionRepo:
                              TransactionRepository(DatabaseHelper.instance),
                          dateRange: _selectedDateRange,
                        )),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: CardProdukTerjual(
                                masterDataRepo: MasterDataRepository(
                                    DatabaseHelper.instance),
                                transactionItemRepo: TransactionItemRepository(
                                    DatabaseHelper.instance),
                                dateRange: _selectedDateRange)),
                        const SizedBox(width: 24),
                        Expanded(
                            child: CardKertasTerjual(
                                inventoryLogRepo: InventoryLogRepository(
                                    DatabaseHelper.instance),
                                dateRange: _selectedDateRange)),
                        const SizedBox(width: 24),
                        Expanded(
                            child: CardPlastikTerjual(
                                inventoryLogRepo: InventoryLogRepository(
                                    DatabaseHelper.instance),
                                dateRange: _selectedDateRange)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: CardPenjualanHarian(
                            transactionRepository:
                                TransactionRepository(DatabaseHelper.instance),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                // Mobile layout (stack vertically)
                return Column(
                  children: [
                    CardPelanggan(
                      transactionRepo:
                          TransactionRepository(DatabaseHelper.instance),
                      dateRange: _selectedDateRange,
                    ),
                    const SizedBox(height: 16),
                    CardPenjualan(dateRange: _selectedDateRange),
                    const SizedBox(height: 16),
                    CardGudang(
                      inventoryLogRepo:
                          InventoryLogRepository(DatabaseHelper.instance),
                      dateRange: _selectedDateRange,
                    ),
                    const SizedBox(height: 16),
                    CardProduk(
                      transactionRepo:
                          TransactionRepository(DatabaseHelper.instance),
                      dateRange: _selectedDateRange,
                    ),
                    const SizedBox(height: 16),
                    CardProdukTerjual(
                        masterDataRepo:
                            MasterDataRepository(DatabaseHelper.instance),
                        transactionItemRepo:
                            TransactionItemRepository(DatabaseHelper.instance),
                        dateRange: _selectedDateRange),
                    const SizedBox(height: 16),
                    CardKertasTerjual(
                        inventoryLogRepo:
                            InventoryLogRepository(DatabaseHelper.instance),
                        dateRange: _selectedDateRange),
                    const SizedBox(height: 16),
                    CardPlastikTerjual(
                        inventoryLogRepo:
                            InventoryLogRepository(DatabaseHelper.instance),
                        dateRange: _selectedDateRange),
                    const SizedBox(height: 16),
                    CardPenjualanHarian(
                      transactionRepository:
                          TransactionRepository(DatabaseHelper.instance),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
