import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meko_poin/models/additional/transaction_with_customer_user.dart';
import 'package:meko_poin/models/transaction_item.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/receipt_service.dart';

class TransactionDetail extends StatefulWidget {
  final int transactionId;
  final TransactionRepository transactionRepository;
  final VoidCallback onBackPressed;

  const TransactionDetail({
    super.key,
    required this.transactionId,
    required this.transactionRepository,
    required this.onBackPressed,
  });

  @override
  State<TransactionDetail> createState() => _TransactionDetailState();
}

class _TransactionDetailState extends State<TransactionDetail> {
  bool _isEditingCustomer = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startEditing(String currentName, String currentPhone) {
    setState(() {
      _isEditingCustomer = true;
      _nameController.text = currentName;
      _phoneController.text = currentPhone;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditingCustomer = false;
      _nameController.clear();
      _phoneController.clear();
    });
  }

  Future<void> _saveCustomerChanges(int customerId) async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan nomor HP harus diisi')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      // Update customer langsung ke database
      final result = await db.update(
        'Data_Customer',
        {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [customerId],
      );

      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data customer berhasil diperbarui')),
        );

        setState(() {
          _isEditingCustomer = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui data customer')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui data customer: $e')),
      );
      debugPrint('Error updating customer: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  String _formatPrice(int price) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(price);
  }

  void _showPrintOptions(
      BuildContext context,
      TransactionWithCustomerUser transactionData,
      List<TransactionItem> items) async {
    // Konversi data ke format yang sesuai untuk receipt service
    final transaction = transactionData.transaction;

    final masterDataItems = await Future.wait(
      items.map((item) =>
          widget.transactionRepository.getItemDetails(item.masterDataId)),
    );

    final formattedData = {
      'name': transactionData.customerName,
      'phone': transactionData.customerPhone,
      'date': DateFormat('d MMM y, HH:mm:ss').format(transaction.createdAt),
      'invoice': transactionData.transaction.invoiceNumber,
      'discount_nominal': transaction.discountPrice ?? 0,
      'discount_percent': 0,
      'discount_price': transaction.discountPrice ?? 0,
      'total_price': transaction.finalPrice + (transaction.discountPrice ?? 0),
      'final_price': transaction.finalPrice,
      'payment_method': transaction.paymentMethod,
      'note': transaction.notes,
      'cart_items': items.map((item) {
        final masterData = masterDataItems.firstWhere(
          (m) => m['id'] == item.masterDataId,
          orElse: () => {
            'name': 'Unknown Item',
            'price': item.totalPrice ~/ item.qty,
          },
        );
        return {
          'id': item.id,
          'master_data_id': item.masterDataId,
          'name': masterData['name'],
          'category': masterData['category'],
          'qty': item.qty,
          'price': masterData['price'],
          'total_price': item.totalPrice,
        };
      }).toList(),
    };

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: _PrintOptionsDialog(
            transactionData: formattedData,
            customerPhone: transactionData.customerPhone,
            onClose: () => Navigator.of(context).pop(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TransactionWithCustomerUser>(
      future: widget.transactionRepository
          .getTransactionWithCustomerUser(widget.transactionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.hasError) {
          return const Center(child: Text('Gagal memuat detail transaksi'));
        }

        return FutureBuilder<List<TransactionItem>>(
          future: widget.transactionRepository
              .getTransactionItems(widget.transactionId),
          builder: (context, itemsSnapshot) {
            if (itemsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final transactionData = snapshot.data!;
            final transaction = transactionData.transaction;
            final customerName = transactionData.customerName;
            final customerPhone = transactionData.customerPhone;
            final customerId = transactionData.transaction.customerId;

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
                                            child: _buildCustomerField(
                                              label: 'No. Hp',
                                              value: customerPhone,
                                              isEditing: _isEditingCustomer,
                                              controller: _phoneController,
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          Expanded(
                                            child: _buildCustomerField(
                                              label: 'Nama',
                                              value: customerName,
                                              isEditing: _isEditingCustomer,
                                              controller: _nameController,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Edit/Save Button - sekarang sejajar dengan field
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 25),
                                            child: _isEditingCustomer
                                                ? Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      ElevatedButton(
                                                        onPressed: _isSaving
                                                            ? null
                                                            : _cancelEditing,
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              const Color(
                                                                  0xFFED143B),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 11),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'Batal',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      ElevatedButton(
                                                        onPressed: _isSaving
                                                            ? null
                                                            : () =>
                                                                _saveCustomerChanges(
                                                                    customerId!),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.green,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 11),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                          ),
                                                        ),
                                                        child: _isSaving
                                                            ? const SizedBox(
                                                                width: 16,
                                                                height: 16,
                                                                child:
                                                                    CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  valueColor: AlwaysStoppedAnimation<
                                                                          Color>(
                                                                      Colors
                                                                          .white),
                                                                ),
                                                              )
                                                            : const Text(
                                                                'Simpan',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                ),
                                                              ),
                                                      ),
                                                    ],
                                                  )
                                                : ElevatedButton(
                                                    onPressed: () =>
                                                        _startEditing(
                                                            customerName,
                                                            customerPhone),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                              0xFF1379F0),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16,
                                                          vertical: 11),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Edit',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                          ),
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
                                      // Invoice Number
                                      const Text(
                                        'Invoice',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        transaction.invoiceNumber,
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

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
                                            onPressed: widget.onBackPressed,
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
                                          const SizedBox(width: 10),
                                          ElevatedButton(
                                            onPressed: () {
                                              _showPrintOptions(
                                                context,
                                                snapshot.data!,
                                                itemsSnapshot.data!,
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
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
                                              'Cetak',
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

  Widget _buildCustomerField({
    required String label,
    required String value,
    required bool isEditing,
    required TextEditingController controller,
  }) {
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
        isEditing
            ? SizedBox(
                height: 36, // Sesuaikan tinggi dengan container non-edit
                child: TextFormField(
                  controller: controller,
                  enabled: isEditing,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7, // Sesuaikan padding
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: CustomColors.borderInputColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: CustomColors.borderInputColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: CustomColors.fontSubColor,
                      ),
                    ),
                    filled: true,
                    fillColor: CustomColors.cardColor,
                    // Tambahkan constraint untuk konsistensi
                    constraints: const BoxConstraints(
                      minHeight: 36,
                    ),
                  ),
                ),
              )
            : Container(
                height: 36, // Tinggi yang sama dengan TextFormField
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7, // Padding yang sama
                ),
                decoration: BoxDecoration(
                  color: CustomColors.cardColor,
                  border: Border.all(
                    color: CustomColors.borderInputColor,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      ],
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
                      future: widget.transactionRepository
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

// _PrintOptionsDialog class remains the same...
class _PrintOptionsDialog extends StatelessWidget {
  final Map<String, dynamic> transactionData;
  final String customerPhone;
  final VoidCallback onClose;

  const _PrintOptionsDialog({
    required this.transactionData,
    required this.customerPhone,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      decoration: BoxDecoration(
          color: CustomColors.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CustomColors.borderCardColor)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom:
                    BorderSide(color: CustomColors.borderCardColor, width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cetak Struk',
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 20, color: CustomColors.fontSubColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              children: [
                const Text(
                  'Pilih opsi struk:',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildReceiptOptionButton(
                      icon: Icons.print,
                      label: 'Cetak',
                      onTap: () {
                        ReceiptService.printReceipt(transactionData);
                        onClose();
                      },
                    ),
                    _buildReceiptOptionButton(
                      icon: Icons.save_alt,
                      label: 'Simpan PDF',
                      onTap: () async {
                        try {
                          await ReceiptService.saveReceiptPdf(
                              transactionData, context);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Gagal menyimpan PDF: $e')),
                            );
                          }
                        }
                      },
                    ),
                    _buildReceiptOptionButton(
                      icon: Icons.share,
                      label: 'Share ke WA',
                      onTap: () {
                        ReceiptService.shareReceipt(
                          transactionData,
                          customerPhone,
                        );
                        onClose();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Footer buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top:
                    BorderSide(color: CustomColors.borderCardColor, width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: CustomColors.borderInputColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
