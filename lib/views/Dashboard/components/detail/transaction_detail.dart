import 'package:flutter/material.dart';

class TransactionDetail extends StatelessWidget {
  const TransactionDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column (2/3 width)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pelanggan Section Card
                        _buildSectionCard(
                          title: 'Pelanggan',
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('No. Hp', '081221430378'),
                              const SizedBox(height: 16),
                              _buildDetailRow('Nama', 'John Doe'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Pesanan Section Card
                        _buildSectionCard(
                          title: 'Pesanan',
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildOrderTable(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Right Column (1/3 width)
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pembayaran Section Card
                        _buildSectionCard(
                          title: 'Pembayaran',
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('Diskon', '0'),
                              const SizedBox(height: 16),
                              _buildDetailRow('Total Harga', 'Rp 60.000'),
                              const SizedBox(height: 16),
                              _buildDetailRow('Metode Pembayaran', 'QRIS'),
                              const SizedBox(height: 16),
                              _buildDetailRow('Catatan (Opsional)', '-'),
                              const SizedBox(height: 24),

                              // Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Kembali'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget content}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111B37),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5675),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF111B37),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderTable() {
    final List<Map<String, dynamic>> orderItems = [
      {
        'category': 'Produk',
        'item': 'SELF PHOTO 1-2 Orang',
        'quantity': '1',
        'price': 'Rp 45.000'
      },
      {
        'category': 'Bahan',
        'item': 'STRIPE GLOSSY',
        'quantity': '1',
        'price': 'Rp 15.000'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Kategori',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B5675),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Item',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B5675),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Jumlah',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B5675),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Harga',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B5675),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          ...orderItems.map((item) => Container(
                decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        item['category']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF111B37),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        item['item']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF111B37),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item['quantity']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF111B37),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item['price']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF111B37),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
