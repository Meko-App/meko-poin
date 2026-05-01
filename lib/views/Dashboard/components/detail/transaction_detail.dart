import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:meko_poin/models/additional/transaction_with_customer_user.dart';
import 'package:meko_poin/models/transaction_item.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:meko_poin/services/user_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/receipt_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isEditingPayment = false;
  String? _editingPaymentMethod;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isSaving = false;
  bool _isDeleting = false;
  int? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _getCurrentUserRole();
  }

  Future<void> _getCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole');
    setState(() {
      _currentUserRole = role != null ? int.tryParse(role) : null;
    });
  }

  bool get _isAdmin => _currentUserRole == 1;

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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _DeleteConfirmationDialog(
          onConfirm: (password, isConfirmed) =>
              _deleteTransaction(password, isConfirmed),
          onCancel: () => Navigator.of(context).pop(),
          isLoading: _isDeleting,
        );
      },
    );
  }

  Future<void> _deleteTransaction(String password, bool isConfirmed) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      // Dapatkan user ID dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getInt('userId');

      if (currentUserId == null) {
        // Tampilkan error di modal tanpa menutup
        _updateModalWithError('User tidak terautentikasi');
        return;
      }

      // Buat UserRepository instance langsung
      final userRepository = UserRepository(DatabaseHelper.instance);
      final isValidPassword =
          await userRepository.verifyPassword(currentUserId, password);

      if (!isValidPassword) {
        _updateModalWithError('Password salah');
        return;
      }

      // Hapus transaksi
      final result = await widget.transactionRepository
          .deleteTransaction(widget.transactionId);

      if (result > 0) {
        // Tutup dialog
        if (mounted) Navigator.of(context).pop();

        // Tampilkan snackbar sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dihapus')),
        );

        // Kembali ke halaman tabel
        widget.onBackPressed();
      } else {
        _updateModalWithError('Gagal menghapus transaksi');
      }
    } catch (e) {
      _updateModalWithError('Error menghapus transaksi: $e');
      debugPrint('Error deleting transaction: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

// Method untuk update modal dengan error (menggunakan Navigator untuk update state)
  void _updateModalWithError(String errorMessage) {
    // Karena kita tidak bisa langsung update state dialog dari sini,
    // kita gunakan Navigator untuk push modal baru dengan error
    Navigator.of(context).pop(); // Tutup modal lama
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _DeleteConfirmationDialog(
          onConfirm: (password, isConfirmed) =>
              _deleteTransaction(password, isConfirmed),
          onCancel: () => Navigator.of(context).pop(),
          isLoading: false, // Reset loading state karena ada error
          externalError: errorMessage,
        );
      },
    );
  }

  Future<void> _savePaymentMethod(int transactionId) async {
    if (_editingPaymentMethod == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      final result = await db.update(
        'Data_Transaction',
        {
          'payment_method': _editingPaymentMethod!.toLowerCase(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      if (result > 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Metode pembayaran berhasil diperbarui')),
          );
          setState(() {
            _isEditingPayment = false;
            _editingPaymentMethod = null;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Gagal memperbarui metode pembayaran')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui metode pembayaran: $e')),
        );
        debugPrint('Error updating payment method: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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

  List<Map<String, dynamic>> _parseBundleSnapshot(String snapshot) {
    try {
      final decoded = jsonDecode(snapshot);
      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => item.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
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
          'bundle_components': item.bundleSnapshot != null
              ? _parseBundleSnapshot(item.bundleSnapshot!)
              : [],
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
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const Expanded(
                                            child: Text(
                                              'Metode Pembayaran',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w400,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          if (_isAdmin && !_isEditingPayment)
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _isEditingPayment = true;
                                                  _editingPaymentMethod =
                                                      transaction.paymentMethod
                                                          .toLowerCase();
                                                });
                                              },
                                              child: const Text(
                                                'Edit',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w400,
                                                  color: Color(0xFF1379F0),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      if (_isEditingPayment) ...[
                                        DropdownButtonFormField<String>(
                                          value: _editingPaymentMethod,
                                          isExpanded: true,
                                          items: const ['cash', 'qris']
                                              .map((method) =>
                                                  DropdownMenuItem<String>(
                                                    value: method,
                                                    child: Text(
                                                      method.toUpperCase(),
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white,
                                                        fontFamily: 'Inter',
                                                      ),
                                                    ),
                                                  ))
                                              .toList(),
                                          onChanged: (v) => setState(
                                              () => _editingPaymentMethod = v),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 7),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: BorderSide(
                                                  color: CustomColors
                                                      .borderInputColor),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: BorderSide(
                                                  color: CustomColors
                                                      .fontSubColor),
                                            ),
                                            filled: true,
                                            fillColor: CustomColors.cardColor,
                                            isDense: true,
                                          ),
                                          dropdownColor: CustomColors.cardColor,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            ElevatedButton(
                                              onPressed: _isSaving
                                                  ? null
                                                  : () => setState(() {
                                                        _isEditingPayment =
                                                            false;
                                                        _editingPaymentMethod =
                                                            null;
                                                      }),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFFED143B),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                              child: const Text(
                                                'Batal',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: _isSaving
                                                  ? null
                                                  : () => _savePaymentMethod(
                                                      transaction.id),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                              child: _isSaving
                                                  ? const SizedBox(
                                                      width: 14,
                                                      height: 14,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                Color>(
                                                          Colors.white,
                                                        ),
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Simpan',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ] else
                                        Text(
                                          transaction.paymentMethod
                                              .toUpperCase(),
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
                                          // Tombol Kembali (selalu tampil)
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

                                          // Tombol Hapus (hanya untuk admin)
                                          if (_isAdmin) ...[
                                            ElevatedButton(
                                              onPressed: _isDeleting
                                                  ? null
                                                  : _showDeleteConfirmation,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 10),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                              child: _isDeleting
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                    Color>(
                                                                Colors.white),
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Hapus',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                            ),
                                            const SizedBox(width: 10),
                                          ],

                                          // Tombol Cetak (selalu tampil)
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
                          child: Column(
                            children: [
                              IntrinsicHeight(
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
                              if (item.bundleSnapshot != null)
                                _buildBundleSnapshotDetail(
                                  item.bundleSnapshot!,
                                  item.qty,
                                ),
                            ],
                          ),
                        );
                      },
                    )),
        ],
      ),
    );
  }

  Widget _buildBundleSnapshotDetail(String snapshot, int bundleQty) {
    final details = _parseBundleSnapshot(snapshot);
    if (details.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Komponen Bundle:',
            style: TextStyle(
              fontSize: 12,
              color: CustomColors.fontSubColor,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          ...details.map((detail) {
            final type = (detail['component_type'] ?? '-') as String;
            final name = (detail['component_name'] ?? '-') as String;
            final qty = (detail['qty'] as int? ?? 1) * bundleQty;
            return Text(
              '- ${type[0].toUpperCase()}${type.substring(1)}: $name x$qty',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontFamily: 'Inter',
              ),
            );
          }),
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

class _DeleteConfirmationDialog extends StatefulWidget {
  final Function(String password, bool isConfirmed) onConfirm;
  final VoidCallback onCancel;
  final bool isLoading;
  final String? externalError; // Tambahkan untuk error dari parent

  const _DeleteConfirmationDialog({
    required this.onConfirm,
    required this.onCancel,
    required this.isLoading,
    this.externalError, // Tambahkan parameter ini
  });

  @override
  State<_DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isConfirmed = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Set initial error message dari external error jika ada
    if (widget.externalError != null) {
      _errorMessage = widget.externalError!;
    }
  }

  @override
  void didUpdateWidget(_DeleteConfirmationDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update error message ketika external error berubah
    if (widget.externalError != oldWidget.externalError) {
      setState(() {
        _errorMessage = widget.externalError ?? '';
      });
    }
  }

  void _clearError() {
    if (_errorMessage.isNotEmpty) {
      setState(() {
        _errorMessage = '';
      });
    }
  }

  void _validateAndSubmit() async {
    // Clear previous errors
    _clearError();

    // Validasi checkbox
    if (!_isConfirmed) {
      setState(() {
        _errorMessage = 'Harus menyetujui tindakan yang dilakukan';
      });
      return;
    }

    // Validasi password
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Password harus diisi';
      });
      return;
    }

    // Jika semua valid, panggil onConfirm
    widget.onConfirm(_passwordController.text, _isConfirmed);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: CustomColors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CustomColors.borderCardColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CustomColors.borderCardColor,
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hapus Transaksi',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: CustomColors.fontSubColor,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: widget.isLoading ? null : widget.onCancel,
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning Icon and Message
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tindakan ini akan menghapus transaksi secara permanen. Data yang sudah dihapus tidak dapat dikembalikan.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Error Message (jika ada)
                  if (_errorMessage.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Password Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        enabled: !widget.isLoading,
                        onChanged: (_) => _clearError(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: _errorMessage.isNotEmpty
                                  ? Colors.red
                                  : CustomColors.borderInputColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: _errorMessage.isNotEmpty
                                  ? Colors.red
                                  : CustomColors.borderInputColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: _errorMessage.isNotEmpty
                                  ? Colors.red
                                  : CustomColors.fontSubColor,
                            ),
                          ),
                          filled: true,
                          fillColor: CustomColors.cardColor,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: CustomColors.fontSubColor,
                              size: 20,
                            ),
                            onPressed: widget.isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                          ),
                          hintText: 'Masukkan password Anda',
                          hintStyle: TextStyle(
                            color: CustomColors.fontSubColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Confirmation Checkbox
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _isConfirmed,
                          onChanged: widget.isLoading
                              ? null
                              : (bool? value) {
                                  setState(() {
                                    _isConfirmed = value ?? false;
                                    _clearError();
                                  });
                                },
                          checkColor: Colors.white,
                          fillColor: MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.selected)) {
                                return Colors.blueAccent;
                              }
                              return CustomColors.borderInputColor;
                            },
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isConfirmed = !_isConfirmed;
                                    _clearError();
                                  });
                                },
                          child: const Text(
                            'Saya mengerti dengan tindakan yang saya lakukan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: CustomColors.borderCardColor,
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel Button
                  ElevatedButton(
                    onPressed: widget.isLoading ? null : widget.onCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                          color: CustomColors.borderInputColor,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Delete Button
                  ElevatedButton(
                    onPressed: widget.isLoading ? null : _validateAndSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Hapus',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
