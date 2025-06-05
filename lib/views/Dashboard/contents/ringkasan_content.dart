import 'package:flutter/material.dart';

class RingkasanContent extends StatelessWidget {
  const RingkasanContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Row(
          children: [
            Expanded(child: _buildCard("Pelanggan")),
            const SizedBox(width: 24),
            Expanded(child: _buildCard("Penjualan Hari Ini")),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildCard("Gudang")),
            const SizedBox(width: 24),
            Expanded(child: _buildCard("Produk Terfavorit")),
          ],
        ),
      ],
    );
  }

  Widget _buildCard(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 220,
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
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
