import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:meko_poin/models/customer.dart';
import 'package:meko_poin/models/master_data.dart';
import 'package:meko_poin/models/transaction_item.dart';
import 'package:meko_poin/services/customer_repository.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/master_data_repository.dart';
import 'package:meko_poin/services/transaction_item_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionForm extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(Map<String, dynamic>) onSubmit;
  final VoidCallback onSuccess;

  const TransactionForm({
    super.key,
    required this.onCancel,
    required this.onSubmit,
    required this.onSuccess,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isNameEnabled = false;
  List<Customer> _searchResults = [];
  OverlayEntry? _overlayEntry;
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();
  final GlobalKey _phoneFieldKey = GlobalKey();

  final TextEditingController _orderQuantityController =
      TextEditingController();
  final TextEditingController _discountNominalController =
      TextEditingController();
  final TextEditingController _discountPercentController =
      TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _selectedOrderCategory;
  String? _selectedOrderItem;
  String? _selectedPaymentMethod;
  TransactionItem? _hoveredCartItem;

  final MasterDataRepository _masterDataRepo =
      MasterDataRepository(DatabaseHelper.instance);
  final TransactionItemRepository _transactionItemRepo =
      TransactionItemRepository(DatabaseHelper.instance);

  TransactionItem? _selectedCartItem;
  List<TransactionItem> _cartItems = [];
  List<MasterData> _masterDataItems = [];
  List<MasterData> _filteredMasterDataItems = [];

  int _totalPrice = 0;
  int _finalPrice = 0;
  bool _isNominalDiscount = false;
  bool _isPercentageDiscount = false;

  @override
  void initState() {
    super.initState();
    _loadMasterData();
    _loadCartItems();
    _clearCartItem();
    _phoneController.addListener(_onPhoneChanged);
    _phoneFocusNode.addListener(_onPhoneFocusChanged);
    _nameFocusNode.addListener(_onNameFocusChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneFocusNode.removeListener(_onPhoneFocusChanged);
    _nameFocusNode.removeListener(_onNameFocusChanged);
    _phoneController.dispose();
    _nameController.dispose();
    _phoneFocusNode.dispose();
    _nameFocusNode.dispose();
    _removeOverlay();

    _orderQuantityController.dispose();
    _discountNominalController.dispose();
    _discountPercentController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _processTransaction(Map<String, dynamic> transactionData) async {
    try {
      // 1. Simpan data customer
      final customer = await _saveCustomer(
          transactionData['name'], transactionData['phone']);

      // 2. Simpan data transaksi
      final transactionId =
          await _saveTransaction(customer.id!, transactionData);

      // 3. Update transaction items dengan transaction_id
      await _updateTransactionItems(transactionId);

      // 4. Update stok inventory dan buat log
      await _updateInventoryAndLog(transactionId);

      // Berhasil, tampilkan notifikasi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil diproses')),
        );

        // Kosongkan keranjang dan reset form
        await _clearCartItem();
        _phoneController.clear();
        _nameController.clear();
        setState(() {
          _selectedPaymentMethod = null;
          _discountNominalController.clear();
          _discountPercentController.clear();
          _noteController.clear();
        });

        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses transaksi: $e')),
        );
      }
    }
  }

  Future<Customer> _saveCustomer(String name, String phone) async {
    final customerRepo = CustomerRepository(DatabaseHelper.instance);

    // Cek apakah customer sudah ada
    final existingCustomer = await customerRepo.findCustomerByPhone(phone);

    if (existingCustomer != null) {
      // Update customer jika ada perubahan
      if (existingCustomer.name != name) {
        final updatedCustomer = Customer(
          id: existingCustomer.id,
          userId: existingCustomer.userId,
          name: name,
          phone: phone,
          createdAt: existingCustomer.createdAt,
          updatedAt: DateTime.now(),
        );
        await customerRepo.updateCustomer(updatedCustomer);
        return updatedCustomer;
      }
      return existingCustomer;
    } else {
      // Buat customer baru
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId') ?? 0;

      final newCustomer = Customer(
        id: null,
        userId: userId,
        name: name,
        phone: phone,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final customerId = await customerRepo.insertCustomer(newCustomer);
      return Customer(
        id: customerId,
        userId: newCustomer.userId,
        name: newCustomer.name,
        phone: newCustomer.phone,
        createdAt: newCustomer.createdAt,
        updatedAt: newCustomer.updatedAt,
      );
    }
  }

  Future<int> _saveTransaction(
      int customerId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;

    final db = await DatabaseHelper.instance.database;

    final transactionId = await db.insert('Data_Transaction', {
      'user_id': userId,
      'customer_id': customerId,
      'discount_price': data['discount_nominal'],
      'final_price': data['final_price'],
      'payment_method': data['payment_method']?.toLowerCase(),
      'notes': data['note'],
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    return transactionId;
  }

  Future<void> _updateTransactionItems(int transactionId) async {
    final db = await DatabaseHelper.instance.database;

    // Update semua cart items yang transaction_id masih null
    await db.update(
      'Data_Transaction_Item',
      {
        'transaction_id': transactionId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'transaction_id IS NULL',
    );
  }

  Future<void> _updateInventoryAndLog(int transactionId) async {
    final db = await DatabaseHelper.instance.database;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;

    // Dapatkan semua item transaksi
    final items = await db.query(
      'Data_Transaction_Item',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );

    for (final item in items) {
      final masterDataId = item['master_data_id'] as int;
      final qty = item['qty'] as int;

      // Dapatkan data inventory
      final inventory = await db.query(
        'Data_Inventory',
        where: 'master_data_id = ?',
        whereArgs: [masterDataId],
        limit: 1,
      );

      if (inventory.isNotEmpty) {
        final initialStock = inventory.first['stock'] as int;
        final currentStock = initialStock - qty;

        // Update stok inventory
        await db.update(
          'Data_Inventory',
          {
            'stock': currentStock,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'master_data_id = ?',
          whereArgs: [masterDataId],
        );

        // Buat log inventory
        final now = DateTime.now();
        final formattedDate = DateFormat('d MMM y, HH:mm:ss').format(now);

        await db.insert('Data_Inventory_Log', {
          'inventory_id': inventory.first['id'],
          'user_id': userId,
          'type': 'decrement',
          'initial_stock': initialStock,
          'current_stock': currentStock,
          'difference': qty,
          'notes':
              'Transaksi pada $formattedDate dengan pengurangan sebesar $qty',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
      }
    }
  }

  Future<int> _getLastTransactionId() async {
    final db = await DatabaseHelper.instance.database;
    final result =
        await db.rawQuery('SELECT MAX(id) as last_id FROM Data_Transaction');
    return result.first['last_id'] as int? ?? 0;
  }

  bool _isFormValid() {
    if (_phoneController.text.isEmpty || _nameController.text.isEmpty) {
      return false;
    }

    if (_cartItems.isEmpty) {
      return false;
    }

    if (_selectedPaymentMethod == null) {
      return false;
    }

    return true;
  }

  void _calculateTotalPrice() {
    final total = _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
    setState(() {
      _totalPrice = total;
      _finalPrice = total;
    });
    _calculateDiscount();
  }

  void _calculateDiscount() {
    int discount = 0;

    if (_isNominalDiscount) {
      final nominal = int.tryParse(_discountNominalController.text) ?? 0;
      discount = nominal;
    } else if (_isPercentageDiscount) {
      final percentage = int.tryParse(_discountPercentController.text) ?? 0;
      discount = (_totalPrice * percentage) ~/ 100;
    }

    setState(() {
      _finalPrice = _totalPrice - discount;
    });
  }

  Future<void> _loadMasterData() async {
    try {
      final items = await _masterDataRepo.getAllMasterData();
      setState(() {
        _masterDataItems = items;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data master: $e')),
      );
    }
  }

  Future<void> _loadCartItems() async {
    final items = await _transactionItemRepo.getAllCartItems();
    if (mounted) {
      setState(() {
        _cartItems = items;
      });
      _calculateTotalPrice();
    }
  }

  void _filterMasterDataItems(String? category) {
    if (category == null) {
      setState(() {
        _filteredMasterDataItems = [];
      });
      return;
    }

    setState(() {
      _filteredMasterDataItems =
          _masterDataItems.where((item) => item.category == category).toList();
    });
  }

  Future<void> _addOrUpdateItemToCart(bool isNewItem) async {
    if (_selectedOrderCategory == null || _selectedOrderItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pilih kategori dan item terlebih dahulu')),
      );
      return;
    }

    final qty = int.tryParse(_orderQuantityController.text) ?? 1;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }

    // Cari master data yang dipilih
    final selectedMasterData = _filteredMasterDataItems.firstWhere(
      (item) => item.name == _selectedOrderItem,
      orElse: () => throw Exception('Item tidak ditemukan'),
    );

    try {
      final availableStock =
          await _masterDataRepo.getStockByMasterDataId(selectedMasterData.id!);
      print(availableStock);
      if (availableStock == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Stok belum tersedia, harap hubungi admin')),
        );
        return;
      }
      final existingItem = await _transactionItemRepo
          .findExistingCartItem(selectedMasterData.id!);

      if (existingItem != null) {
        final totalQty;
        final totalPrice;
        if (isNewItem == false) {
          totalQty = qty;
          totalPrice = (selectedMasterData.price ?? 0) * qty;
        } else {
          totalQty = existingItem.qty + qty;
          totalPrice = (existingItem.totalPrice ~/ existingItem.qty) *
              (existingItem.qty + qty);
        }
        if (totalQty > availableStock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Stok tidak mencukupi. Stok tersedia: $availableStock')),
          );
          return;
        }
        final updatedItem = TransactionItem(
          id: existingItem.id,
          masterDataId: existingItem.masterDataId,
          qty: totalQty,
          totalPrice: totalPrice,
          createdAt: existingItem.createdAt,
          updatedAt: DateTime.now(),
        );

        await _transactionItemRepo.updateTransactionItem(updatedItem);
      } else {
        final totalPrice = (selectedMasterData.price ?? 0) * qty;
        if (qty > availableStock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Stok tidak mencukupi. Stok tersedia: $availableStock')),
          );
          return;
        }

        final newItem = TransactionItem(
          masterDataId: selectedMasterData.id!,
          qty: qty,
          totalPrice: totalPrice,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _transactionItemRepo.insertTransactionItem(newItem);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existingItem != null
              ? 'Jumlah item diperbarui'
              : 'Item ditambahkan ke keranjang'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan item: $e')),
      );
    }

    _resetItemForm();
    await _loadCartItems();
  }

  void _editCartItem(TransactionItem item) async {
    final masterData =
        await _masterDataRepo.getMasterDataById(item.masterDataId);

    setState(() {
      _selectedCartItem = item;
      _selectedOrderCategory = masterData?.category;
      _filterMasterDataItems(masterData?.category);
      _selectedOrderItem = masterData?.name;
      _orderQuantityController.text = item.qty.toString();
    });
  }

  Future<void> _deleteCartItem(int id) async {
    await _transactionItemRepo.deleteTransactionItem(id);
    _resetItemForm();
    await _loadCartItems();
  }

  Future<void> _clearCartItem() async {
    await _transactionItemRepo.clearCart();
    _resetItemForm();
    await _loadCartItems();
  }

  void _resetItemForm() {
    setState(() {
      _selectedOrderCategory = null;
      _selectedOrderItem = null;
      _filteredMasterDataItems = [];
      _orderQuantityController.text = '';
      _selectedCartItem = null;
    });
  }

  void _onPhoneFocusChanged() {
    if (!_phoneFocusNode.hasFocus && _overlayEntry != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_phoneFocusNode.hasFocus && !_nameFocusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _onNameFocusChanged() {
    if (!_nameFocusNode.hasFocus &&
        !_phoneFocusNode.hasFocus &&
        _overlayEntry != null) {
      _removeOverlay();
    }
  }

  Future<void> _onPhoneChanged() async {
    final text = _phoneController.text;

    if (text.length >= 3) {
      final results = await CustomerRepository(DatabaseHelper.instance)
          .searchCustomers(text);
      setState(() {
        _searchResults = results;
      });
      if (_phoneFocusNode.hasFocus) {
        _showOverlay();
      }
    } else {
      _removeOverlay();
      if (_nameController.text.isNotEmpty) {
        _nameController.clear();
      }
      setState(() {
        _isNameEnabled = false;
      });
    }
  }

  void _showOverlay() {
    _removeOverlay();

    final renderBox =
        _phoneFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _removeOverlay();
                _phoneFocusNode.unfocus();
              },
              behavior: HitTestBehavior.translucent,
            ),
          ),
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height + 4,
            width: size.width,
            child: Material(
              color: Colors.transparent,
              elevation: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    children: [
                      if (_searchResults.isEmpty)
                        _buildDropdownItem(
                          title: 'Tambahkan pelanggan baru',
                          subtitle: _phoneController.text,
                          onTap: _selectAddNewOption,
                        )
                      else
                        ..._searchResults.map((customer) => _buildDropdownItem(
                              title: customer.name,
                              subtitle: customer.phone,
                              onTap: () => _selectCustomer(customer),
                            )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (mounted) {
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  Widget _buildDropdownItem({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTap();
          _removeOverlay();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _phoneController.text = customer.phone;
      _nameController.text = customer.name;
      _isNameEnabled = false;
    });
    _phoneFocusNode.unfocus();
    _removeOverlay();
  }

  void _selectAddNewOption() {
    setState(() {
      _isNameEnabled = true;
      _nameController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_nameFocusNode);
    });
    _removeOverlay();
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormLabel('No. Hp'),
        const SizedBox(height: 8),
        SizedBox(
          key: _phoneFieldKey,
          child: TextField(
            controller: _phoneController,
            focusNode: _phoneFocusNode,
            onTap: () {
              if (_phoneController.text.length >= 3) {
                _showOverlay();
              }
            },
            decoration: InputDecoration(
              hintText: 'Masukkan no HP',
              hintStyle: const TextStyle(
                fontSize: 14,
                fontFamily: 'Inter',
                color: Color(0xFF78829D),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF1379F0),
                  width: 1.0,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF111B37),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormLabel('Nama'),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          enabled: _isNameEnabled,
          decoration: InputDecoration(
            hintText: 'Masukkan nama',
            hintStyle: TextStyle(
              fontSize: 14,
              fontFamily: 'Inter',
              color:
                  _isNameEnabled ? const Color(0xFF78829D) : Colors.grey[400],
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1.0,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF1379F0),
                width: 1.0,
              ),
            ),
            filled: true,
            fillColor: _isNameEnabled ? Colors.white : Colors.grey.shade100,
            isDense: true,
          ),
          style: TextStyle(
            fontSize: 14,
            color: _isNameEnabled ? const Color(0xFF111B37) : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _submitTransaction() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang tidak boleh kosong')),
      );
      return;
    }

    final lastId = await _getLastTransactionId();
    final invoiceNumber = '#${lastId + 1}';
    final now = DateTime.now();
    final formattedDate = DateFormat('d MMM y, HH:mm:ss').format(now);

    // Hitung total harga
    final totalPrice = _cartItems.fold(0, (sum, item) => sum + item.totalPrice);

    // Hitung diskon
    final discountNominal = int.tryParse(_discountNominalController.text) ?? 0;
    final discountPercent = int.tryParse(_discountPercentController.text) ?? 0;
    final discountPrice =
        discountNominal + (totalPrice * discountPercent ~/ 100);
    final finalPrice = totalPrice - discountPrice;

    final transactionData = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'date': formattedDate,
      'invoice': invoiceNumber,
      'discount_nominal':
          discountNominal == 0 ? discountPrice : discountNominal,
      'discount_percent': discountPercent,
      'final_price': finalPrice,
      'payment_method': _selectedPaymentMethod,
      'note': _noteController.text,
      'cart_items': _cartItems,
    };

    _showReviewOrderModal(transactionData);
  }

  void _showReviewOrderModal(Map<String, dynamic> transactionData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ReviewOrderModal(
            onProcess: _processTransaction,
            onCancel: () {
              Navigator.of(context).pop(); // Close the modal
            },
            transactionData: transactionData,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildPhoneField()),
                                const SizedBox(width: 24),
                                Expanded(child: _buildNameField()),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOrderInputRow(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Keranjang Section
                      _buildSectionCard(
                        title: 'Keranjang',
                        content: _buildCartTable(),
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
                            const SizedBox(height: 8),
                            // Diskon Nominal
                            const Text(
                              'Diskon (Nominal)',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111B37),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _discountNominalController,
                              enabled: !_isPercentageDiscount,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Masukkan diskon nominal',
                                hintStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF78829D),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade300, width: 1.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF1379F0), width: 1.0),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                isDense: true,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF111B37),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _isNominalDiscount = value.isNotEmpty;
                                  if (_isNominalDiscount) {
                                    _isPercentageDiscount = false;
                                    _discountPercentController.clear();
                                  }
                                  _calculateDiscount();
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Diskon Persen
                            const Text(
                              'Diskon (Persen)',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111B37),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _discountPercentController,
                              enabled: !_isNominalDiscount,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Masukkan diskon persen',
                                hintStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF78829D),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade300, width: 1.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF1379F0), width: 1.0),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                isDense: true,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF111B37),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _isPercentageDiscount = value.isNotEmpty;
                                  if (_isPercentageDiscount) {
                                    _isNominalDiscount = false;
                                    _discountNominalController.clear();
                                  }
                                  _calculateDiscount();
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Total Harga
                            const Text(
                              'Total Harga',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111B37),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatPrice(_finalPrice),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 20,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111B37),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Metode Pembayaran
                            const Text(
                              'Metode Pembayaran',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111B37),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPaymentMethodDropdown(),
                            const SizedBox(height: 16),

                            // Catatan
                            const Text(
                              'Catatan (Opsional)',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111B37),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                                _noteController, 'Masukkan catatan'),
                            const SizedBox(height: 16),

                            // Buttons moved here
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: widget.onCancel,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    child: Text(
                                      'Batal',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: Color(0xFF4B5675),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: _isFormValid()
                                      ? _submitTransaction
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isFormValid()
                                        ? const Color(0xFF1379F0)
                                        : Colors.grey.shade400,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 11),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: const Text(
                                    'Tinjau',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12),
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
                top: BorderSide(color: Colors.grey.shade300),
                bottom: title == 'Keranjang'
                    ? BorderSide.none
                    : BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                color: Color(0xFF111B37),
              ),
            ),
          ),
          // Content
          Padding(
            padding: title == 'Keranjang'
                ? const EdgeInsets.all(0)
                : const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        color: Color(0xFF111B37),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText) {
    final isNoteField = controller == _noteController;

    return SizedBox(
      height: isNoteField ? null : 36,
      child: TextField(
        maxLines: isNoteField ? null : 1,
        minLines: isNoteField ? 4 : 1,
        controller: controller,
        keyboardType:
            isNoteField ? TextInputType.multiline : TextInputType.text,
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          color: Color(0xFF111B37),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            color: Color(0xFF78829D),
          ),
          contentPadding: const EdgeInsets.all(12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFF1379F0),
              width: 1.0,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          alignLabelWithHint: isNoteField, // Better alignment for multiline
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required Function(String?) onChanged,
    required List<String> items,
  }) {
    return SizedBox(
      height: 34,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            color: Color(0xFF78829D),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1379F0), width: 1.0),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        dropdownColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        iconSize: 20,
        isExpanded: true,
        items: items.map<DropdownMenuItem<String>>((String itemValue) {
          return DropdownMenuItem<String>(
            value: itemValue,
            child: Text(
              itemValue,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                color: Color(0xFF111B37),
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 13,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          color: Color(0xFF111B37),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    // Ambil kategori unik dari master data
    final categories = _masterDataItems.map((e) => e.category).toSet().toList();

    return DropdownButtonFormField<String>(
      value: _selectedOrderCategory,
      hint: const Text(
        'Pilih kategori',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: Color(0xFF78829D),
        ),
      ),
      items: categories.map((category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedOrderCategory = value;
          _filterMasterDataItems(value);
          _selectedOrderItem = null;
        });
      },
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1379F0), width: 1.0),
        ),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
      ),
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF111B37),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
      dropdownColor: Colors.white,
    );
  }

  Widget _buildItemDropdown() {
    if (_filteredMasterDataItems.isEmpty) {
      return DropdownButtonFormField<String>(
        value: null,
        hint: const Text(
          'Pilih kategori terlebih dahulu',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            color: Color(0xFF78829D),
          ),
        ),
        items: null,
        onChanged: null,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          isDense: true,
        ),
      );
    }
    return DropdownButtonFormField<String>(
      value: _selectedOrderItem,
      hint: const Text(
        'Pilih Item',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF78829D),
        ),
      ),
      items: _filteredMasterDataItems.map((item) {
        return DropdownMenuItem<String>(
          value: item.name,
          child: Text(item.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedOrderItem = value;
        });
      },
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1379F0), width: 1.0),
        ),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
      ),
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF111B37),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
    );
  }

  Widget _buildOrderInputRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormLabel('Kategori'),
              const SizedBox(height: 8),
              _buildCategoryDropdown(),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormLabel('Item'),
              const SizedBox(height: 8),
              _buildItemDropdown(),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormLabel('Jumlah'),
              const SizedBox(height: 6),
              SizedBox(
                height: 36,
                child: TextField(
                  controller: _orderQuantityController,
                  keyboardType: TextInputType.number,
                  textAlignVertical: TextAlignVertical.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF111B37),
                    height: 1.0,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Masukkan jumlah',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9AA4B8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF1379F0),
                        width: 1.0,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: SizedBox(
                      width: 24,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Up Button
                          SizedBox(
                            width: 24,
                            height: 16,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                                onTap: () {
                                  final current = int.tryParse(
                                          _orderQuantityController.text) ??
                                      0;
                                  _orderQuantityController.text =
                                      (current + 1).toString();
                                },
                                child: const Center(
                                  child: Icon(
                                    Icons.keyboard_arrow_up,
                                    size: 16,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Divider
                          Container(
                            height: 1,
                            width: 16,
                            color: Colors.grey.shade200,
                          ),
                          // Down Button
                          SizedBox(
                            width: 24,
                            height: 16,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(4),
                                ),
                                onTap: () {
                                  final current = int.tryParse(
                                          _orderQuantityController.text) ??
                                      1;
                                  if (current > 1) {
                                    _orderQuantityController.text =
                                        (current - 1).toString();
                                  }
                                },
                                child: const Center(
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (_selectedCartItem == null)
          // Add button
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF1379F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              onPressed: () async {
                await _addOrUpdateItemToCart(true);
              },
            ),
          )
        else
          // Edit and Delete buttons
          Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                  onPressed: () async {
                    await _addOrUpdateItemToCart(false);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                  onPressed: () => _deleteCartItem(_selectedCartItem!.id!),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return _buildDropdownField(
      value: _selectedPaymentMethod,
      hint: 'Pilih metode pembayaran',
      onChanged: (newValue) {
        setState(() {
          _selectedPaymentMethod = newValue;
        });
      },
      items: const ['Cash', 'QRIS'],
    );
  }

  Widget _buildCartTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
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
          if (_cartItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: Text(
                  'Keranjang kosong',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ..._cartItems.map((item) {
              final masterData = _masterDataItems.firstWhere(
                (m) => m.id == item.masterDataId,
                orElse: () => MasterData(
                  userId: 0,
                  name: 'Item tidak ditemukan',
                  category: 'Unknown',
                ),
              );

              return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _hoveredCartItem = item),
                  onExit: (_) => setState(() => _hoveredCartItem = null),
                  child: GestureDetector(
                    onTap: () => _editCartItem(item),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedCartItem?.id == item.id
                            ? Colors.blue.shade50
                            : _hoveredCartItem?.id == item.id
                                ? Colors.grey.shade100
                                : Colors.white,
                        border: const Border(
                            bottom: BorderSide(color: Color(0xFFE5E7EB))),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            _buildTableCell(masterData.category, 2),
                            VerticalDivider(
                                thickness: 1,
                                width: 1,
                                color: Colors.grey[300]),
                            _buildTableCell(masterData.name, 3),
                            VerticalDivider(
                                thickness: 1,
                                width: 1,
                                color: Colors.grey[300]),
                            _buildTableCell(item.qty.toString(), 1),
                            VerticalDivider(
                                thickness: 1,
                                width: 1,
                                color: Colors.grey[300]),
                            _buildTableCell(_formatPrice(item.totalPrice), 2),
                          ],
                        ),
                      ),
                    ),
                  ));
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
            right: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF4B5675),
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
            fontSize: 13,
            height: 1.2,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111B37),
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

String _formatPrice(int price) {
  final formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  return formatter.format(price);
}

class ReviewOrderModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onProcess;
  final VoidCallback onCancel;
  final Map<String, dynamic> transactionData;

  const ReviewOrderModal({
    Key? key,
    required this.onProcess,
    required this.onCancel,
    required this.transactionData,
  }) : super(key: key);

  @override
  _ReviewOrderModalState createState() => _ReviewOrderModalState();
}

class _ReviewOrderModalState extends State<ReviewOrderModal> {
  late final List<TransactionItem> _cartItems;
  // final MasterDataService _masterDataService = MasterDataService();
  Map<int, MasterData> _masterDataMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cartItems = widget.transactionData['cart_items'] as List<TransactionItem>;
    _fetchMasterData();
  }

  Future<void> _fetchMasterData() async {
    final Set<int> masterDataIds =
        _cartItems.map((item) => item.masterDataId).toSet();
    final Map<int, MasterData> fetchedData = {};

    for (int id in masterDataIds) {
      final MasterData? data =
          await MasterDataRepository(DatabaseHelper.instance)
              .getMasterDataById(id);
      if (data != null) {
        fetchedData[id] = data;
      }
    }

    setState(() {
      _masterDataMap = fetchedData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.transactionData['name'] as String;
    final phone = widget.transactionData['phone'] as String;
    final date = widget.transactionData['date'] as String;
    final invoice = widget.transactionData['invoice'] as String;
    final paymentMethod =
        widget.transactionData['payment_method'] as String? ?? '-';
    final totalPrice = _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
    final discountNominal = widget.transactionData['discount_nominal'] as int;
    final discountPercent = widget.transactionData['discount_percent'] as int;
    final discountPrice =
        discountNominal + (totalPrice * discountPercent ~/ 100);
    final finalPrice = totalPrice - discountPrice;

    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tinjau Pesanan',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111B37),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 20, color: Color(0xFF78829D)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Nama', name),
                      const SizedBox(height: 8),
                      _buildInfoRow('No. HP', phone),
                      const SizedBox(height: 8),
                      _buildInfoRow('Tanggal', date),
                      const SizedBox(height: 8),
                      _buildInfoRow('Invoice', invoice),

                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 16),

                      // Order items
                      Column(
                        children: _cartItems.map((item) {
                          final MasterData? masterData =
                              _masterDataMap[item.masterDataId];
                          final String itemName = masterData?.name ??
                              'Unknown Item (ID: ${item.masterDataId})';

                          return _buildItemPesanan(
                            itemName,
                            item.qty.toString(),
                            'Rp ${item.totalPrice}',
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 16),

                      _buildPaymentRow('Diskon', 'Rp $discountPrice'),
                      const SizedBox(height: 8),
                      _buildPaymentRow('Total', 'Rp $finalPrice'),
                      const SizedBox(height: 8),
                      _buildPaymentRow('Pembayaran', paymentMethod),
                    ],
                  ),
          ),

          // Footer buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: Color(0xFF4B5675),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    widget.onProcess(widget
                        .transactionData); // Panggil dengan data transaksi
                    widget.onCancel(); // Tutup dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1379F0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Proses',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              color: Color(0xFF4B5675),
            ),
          ),
        ),
        const Text(
          ':',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            color: Color(0xFF4B5675),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              color: Color(0xFF111B37),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5675),
            ),
          ),
        ),
        const Text(
          ':',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            color: Color(0xFF4B5675),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              color: Color(0xFF111B37),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemPesanan(String name, String qty, String price) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111B37),
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(
              width: 10,
              child: Text(
                qty,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111B37),
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(
              width: 130,
              child: Text(
                price,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111B37),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ));
  }
}
