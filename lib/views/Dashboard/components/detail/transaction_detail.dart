import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meko_poin/models/additional/transaction_with_customer_user.dart';
import 'package:meko_poin/models/transaction_item.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class TransactionDetail extends StatelessWidget {
  final int transactionId;
  final TransactionRepository transactionRepository;
  final VoidCallback onBackPressed;

  const TransactionDetail({
    super.key,
    required this.transactionId,
    required this.transactionRepository,
    required this.onBackPressed,
  });

  String _formatPrice(int price) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TransactionWithCustomerUser>(
      future:
          transactionRepository.getTransactionWithCustomerUser(transactionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.hasError) {
          return const Center(child: Text('Gagal memuat detail transaksi'));
        }

        return FutureBuilder<List<TransactionItem>>(
          future: transactionRepository.getTransactionItems(transactionId),
          builder: (context, itemsSnapshot) {
            if (itemsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final transactionData = snapshot.data!;
            final transaction = transactionData.transaction;
            final customerName = transactionData.customerName;
            final customerPhone = transactionData.customerPhone;

            if (!itemsSnapshot.hasData || itemsSnapshot.hasError) {
              return const Center(child: Text('Gagal memuat item transaksi'));
            }

            final transactionItems = itemsSnapshot.data!;

            return Container(
              decoration: BoxDecoration(
                color: CustomColors.cardColor,
              ),
              child: Column(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                              child: _buildReadOnlyField(
                                            label: 'No. Hp',
                                            value: customerPhone,
                                          )),
                                          const SizedBox(width: 24),
                                          Expanded(
                                              child: _buildReadOnlyField(
                                            label: 'Nama',
                                            value: customerName,
                                          )),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Pesanan Section Card
                                _buildSectionCard(
                                  title: 'Pesanan',
                                  content: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildOrderTable(transactionItems),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      // Diskon Nominal
                                      const Text(
                                        'Diskon (Nominal)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        _formatPrice(
                                            transaction.discountPrice!),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Total Harga
                                      const Text(
                                        'Total Harga',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        _formatPrice(transaction.finalPrice),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Metode Pembayaran
                                      const Text(
                                        'Metode Pembayaran',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        transaction.paymentMethod.toUpperCase(),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Catatan (read-only)
                                      const Text(
                                        'Catatan',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        transaction.notes.isNotEmpty == true
                                            ? transaction.notes
                                            : '-',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Buttons
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          ElevatedButton(
                                            onPressed: onBackPressed,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF1379F0),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                            child: const Text(
                                              'Kembali',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400),
                                            ),
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
          },
        );
      },
    );
  }

  Widget _buildSectionCard({required String title, required Widget content}) {
    return Card(
      elevation: 0,
      color: CustomColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: CustomColors.borderCardColor, width: 1),
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
                top: BorderSide(color: CustomColors.borderCardColor),
                bottom: title == 'Pesanan'
                    ? BorderSide.none
                    : BorderSide(color: CustomColors.borderCardColor),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Content
          Padding(
            padding: title == 'Pesanan'
                ? const EdgeInsets.all(0)
                : const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderTable(List<TransactionItem> transactionItems) {
    return Container(
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        border: Border.all(color: CustomColors.borderCardColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            decoration: BoxDecoration(
              color: CustomColors.cardColor,
              border: Border(
                top: BorderSide(color: CustomColors.borderCardColor),
                bottom: BorderSide(color: CustomColors.borderCardColor),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _buildTableHeaderCell('Kategori', 2),
                  _buildTableHeaderCell('Item', 3),
                  _buildTableHeaderCell('Jumlah', 1),
                  _buildTableHeaderCell('Harga', 2),
                ],
              ),
            ),
          ),

          // Table Rows
          if (transactionItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: Text(
                  'Tidak ada data pesanan',
                  style: TextStyle(color: CustomColors.fontSubColor),
                ),
              ),
            )
          else
            ...transactionItems
                .map((item) => FutureBuilder<Map<String, dynamic>>(
                      future: transactionRepository
                          .getItemDetails(item.masterDataId),
                      builder: (context, detailsSnapshot) {
                        final itemDetails = detailsSnapshot.hasData
                            ? detailsSnapshot.data!
                            : {
                                'category': 'Uncategorized',
                                'name': 'Item #${item.masterDataId}',
                                'price': item.totalPrice ~/ item.qty
                              };

                        return Container(
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: CustomColors.borderCardColor))),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                _buildTableCell(itemDetails['category'], 2),
                                VerticalDivider(
                                    thickness: 1,
                                    width: 1,
                                    color: CustomColors.borderCardColor),
                                _buildTableCell(itemDetails['name'], 3),
                                VerticalDivider(
                                    thickness: 1,
                                    width: 1,
                                    color: CustomColors.borderCardColor),
                                _buildTableCell(item.qty.toString(), 1),
                                VerticalDivider(
                                    thickness: 1,
                                    width: 1,
                                    color: CustomColors.borderCardColor),
                                _buildTableCell(
                                    'Rp ${NumberFormat('#,###').format(itemDetails['price'])}',
                                    2),
                              ],
                            ),
                          ),
                        );
                      },
                    )),
        ],
      ),
    );
  }

// Helper methods for table cells
  Widget _buildTableHeaderCell(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: CustomColors.borderCardColor),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            height: 2,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
