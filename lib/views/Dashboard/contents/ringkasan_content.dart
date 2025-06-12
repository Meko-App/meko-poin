import 'package:flutter/material.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_gudang.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_pelanggan.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_penjualan.dart';
import 'package:meko_poin/views/Dashboard/components/card/card_produk.dart';

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
                  color: Colors.grey.shade900)),
          const SizedBox(height: 4),
          Text("Data ringkasan berdasarkan hari ini",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade700)),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                // Desktop/tablet
                return Column(
                  children: [
                    Row(
                      children: const [
                        Expanded(child: CardPelanggan()),
                        SizedBox(width: 24),
                        Expanded(child: CardPenjualan()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: const [
                        Expanded(child: CardGudang()),
                        SizedBox(width: 24),
                        Expanded(child: CardProduk()),
                      ],
                    ),
                  ],
                );
              } else {
                // Mobile layout (stack vertically)
                return Column(
                  children: const [
                    CardPelanggan(),
                    SizedBox(height: 16),
                    CardPenjualan(),
                    SizedBox(height: 16),
                    CardGudang(),
                    SizedBox(height: 16),
                    CardProduk(),
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
