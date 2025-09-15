import 'package:flutter/material.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/inventory_log_repository.dart';
import 'package:meko_poin/services/master_data_repository.dart';
import 'package:meko_poin/services/transaction_item_repository.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_gudang.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_kertas_terjual.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_pelanggan.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_penjualan.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_penjualan_harian.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_plastik_terpakai.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_produk.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_produk_terjual.dart';

class RingkasanContent extends StatelessWidget {
  const RingkasanContent({super.key});

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
          Text("Data ringkasan berdasarkan hari ini",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF9A9CAE))),
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
                        )),
                        const SizedBox(width: 24),
                        const Expanded(child: CardPenjualan()),
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
                        )),
                        const SizedBox(width: 24),
                        Expanded(
                            child: CardProduk(
                          transactionRepo:
                              TransactionRepository(DatabaseHelper.instance),
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
                                    DatabaseHelper.instance))),
                        const SizedBox(width: 24),
                        Expanded(
                            child: CardKertasTerjual(
                                masterDataRepo: MasterDataRepository(
                                    DatabaseHelper.instance),
                                transactionItemRepo: TransactionItemRepository(
                                    DatabaseHelper.instance))),
                        const SizedBox(width: 24),
                        Expanded(
                            child: CardPlastikTerjual(
                                masterDataRepo: MasterDataRepository(
                                    DatabaseHelper.instance),
                                transactionItemRepo: TransactionItemRepository(
                                    DatabaseHelper.instance))),
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
                    ),
                    const SizedBox(height: 16),
                    const CardPenjualan(),
                    const SizedBox(height: 16),
                    CardGudang(
                      inventoryLogRepo:
                          InventoryLogRepository(DatabaseHelper.instance),
                    ),
                    const SizedBox(height: 16),
                    CardProduk(
                      transactionRepo:
                          TransactionRepository(DatabaseHelper.instance),
                    ),
                    const SizedBox(height: 16),
                    CardProdukTerjual(
                        masterDataRepo:
                            MasterDataRepository(DatabaseHelper.instance),
                        transactionItemRepo:
                            TransactionItemRepository(DatabaseHelper.instance)),
                    const SizedBox(height: 16),
                    CardKertasTerjual(
                        masterDataRepo:
                            MasterDataRepository(DatabaseHelper.instance),
                        transactionItemRepo:
                            TransactionItemRepository(DatabaseHelper.instance)),
                    const SizedBox(height: 16),
                    CardPlastikTerjual(
                        masterDataRepo:
                            MasterDataRepository(DatabaseHelper.instance),
                        transactionItemRepo:
                            TransactionItemRepository(DatabaseHelper.instance)),
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
