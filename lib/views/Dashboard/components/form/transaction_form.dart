import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:meko_poin/models/customer.dart';
import 'package:meko_poin/models/master_data.dart';
import 'package:meko_poin/models/transaction_item.dart';
import 'package:meko_poin/services/bundle_repository.dart';
import 'package:meko_poin/services/customer_repository.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/master_data_repository.dart';
import 'package:meko_poin/services/transaction_item_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/receipt_service.dart';
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
  List<Customer> _searchResults = [];
  OverlayEntry? _overlayEntry;
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();
  final GlobalKey _phoneFieldKey = GlobalKey();
  final GlobalKey _nameFieldKey = GlobalKey();
  String _overlaySource = 'phone';

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
  String? _selectedBackground;
  TransactionItem? _hoveredCartItem;

  final MasterDataRepository _masterDataRepo =
      MasterDataRepository(DatabaseHelper.instance);
  final TransactionItemRepository _transactionItemRepo =
      TransactionItemRepository(DatabaseHelper.instance);
  final BundleRepository _bundleRepository =
      BundleRepository(DatabaseHelper.instance);

  TransactionItem? _selectedCartItem;
  List<TransactionItem> _cartItems = [];
  List<MasterData> _masterDataItems = [];
  List<MasterData> _backgroundDataItems = [];
  List<MasterData> _filteredMasterDataItems = [];
  Map<int, List<Map<String, dynamic>>> _bundleDetailByBundleId = {};

  int _totalPrice = 0;
  int _finalPrice = 0;
  bool _isNominalDiscount = false;
  bool _isPercentageDiscount = false;
  bool _useRemainingPaper = false;

  @override
  void initState() {
    super.initState();
    _loadMasterData();
    _loadCartItems();
    _clearCartItem();
    _phoneController.addListener(_onPhoneChanged);
    _nameController.addListener(_onNameChanged);
    _phoneFocusNode.addListener(_onPhoneFocusChanged);
    _nameFocusNode.addListener(_onNameFocusChanged);
    _selectedBackground = null;
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _nameController.removeListener(_onNameChanged);
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

  bool _isCategoryCode(MasterData data, String code) {
    return data.category.toLowerCase() == code.toLowerCase();
  }

  bool _isPaperComponent(Map<String, dynamic> component) {
    final type = (component['component_type'] as String?)?.toLowerCase();
    if (type == 'paper' || type == 'print') {
      return true;
    }
    final categoryName =
        (component['component_category_name'] as String?)?.toLowerCase();
    return categoryName == 'paper' || categoryName == 'print';
  }

  String? _selectedCategoryCode() {
    if (_selectedOrderCategory == null) {
      return null;
    }

    return _selectedOrderCategory!.toLowerCase();
  }

  bool _selectedBundleHasPaperComponent() {
    if (_selectedOrderItem == null) return false;
    final selectedMd = _filteredMasterDataItems.cast<MasterData?>().firstWhere(
          (item) => item?.name == _selectedOrderItem,
          orElse: () => null,
        );
    if (selectedMd?.id == null) return false;
    final details = _bundleDetailByBundleId[selectedMd!.id] ?? [];
    return details.any((d) =>
        (d['component_type'] as String?)?.toLowerCase() == 'paper' ||
        (d['component_type'] as String?)?.toLowerCase() == 'print');
  }

  Future<void> _ensureBundleDetailsLoadedForSelectedItem(
      String? itemName) async {
    if (itemName == null) {
      return;
    }

    MasterData? selectedMd;
    for (final item in _filteredMasterDataItems) {
      if (item.name == itemName) {
        selectedMd = item;
        break;
      }
    }

    if (selectedMd == null || selectedMd.id == null) {
      return;
    }

    if ((_bundleDetailByBundleId[selectedMd.id!] ?? []).isNotEmpty) {
      return;
    }

    final bundleItems =
        await _bundleRepository.getBundleItemsWithMasterData(selectedMd.id!);

    if (!mounted) {
      return;
    }

    setState(() {
      _bundleDetailByBundleId[selectedMd!.id!] = bundleItems;
    });
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
          _useRemainingPaper = false;
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

    await db.execute('BEGIN TRANSACTION');

    try {
      final transactionId = await db.insert('Data_Transaction', {
        'user_id': userId,
        'customer_id': customerId,
        'discount_price': data['discount_nominal'],
        'final_price': data['final_price'],
        'invoice_number': data['invoice'],
        'payment_method': data['payment_method']?.toLowerCase(),
        'notes': data['note'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (data['payment_method']?.toLowerCase() == 'cash') {
        final customerName = data['name'];
        final invoiceNumber = data['invoice'];
        final finalPrice = data['final_price'];

        await db.insert('Data_Kas', {
          'amount': finalPrice,
          'description':
              'Pemasukan dari transaksi atas nama $customerName Invoice $invoiceNumber',
          'type': 'income',
          'cash_date': DateTime.now().toIso8601String(),
          'transaction_id': transactionId,
          'created_by': userId,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      await db.execute('COMMIT');

      return transactionId;
    } catch (e) {
      await db.execute('ROLLBACK');
      rethrow;
    }
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
      final bundleSnapshot = item['bundle_snapshot'] as String?;

      // Dapatkan data master untuk mengetahui kategorinya
      final masterData = await _masterDataRepo.getMasterDataById(masterDataId);

      if (masterData == null) continue;

      // Untuk bundle, stok dikurangi berdasarkan komponen bundle.
      var bundleComponents = <Map<String, dynamic>>[];

      if (bundleSnapshot != null && bundleSnapshot.isNotEmpty) {
        bundleComponents = _parseBundleSnapshot(bundleSnapshot);
      }

      if (bundleComponents.isEmpty && masterData.id != null) {
        bundleComponents = await _bundleRepository
            .getBundleItemsWithMasterData(masterData.id!);
      }

      if (bundleComponents.isNotEmpty) {
        for (final component in bundleComponents) {
          final componentInventoryId =
              component['component_inventory_id'] as int?;
          if (componentInventoryId == null) {
            continue;
          }

          // Jika pakai sisa kertas, komponen paper tidak dikurangi.
          if (_isPaperComponent(component) && _useRemainingPaper) {
            continue;
          }

          final componentQty = (component['qty'] as int? ?? 1) * qty;

          await _decrementInventoryByIdAndLog(
            db: db,
            userId: userId,
            inventoryId: componentInventoryId,
            qty: componentQty,
            notes:
                'Transaksi bundle ${masterData.name} dengan pengurangan sebesar $componentQty',
          );
        }

        continue;
      }

      // Skip stock reduction untuk Paper jika "gunakan sisa kertas" aktif.
      if (_isCategoryCode(masterData, 'paper') && _useRemainingPaper) {
        continue;
      }

      await _decrementInventoryAndLog(
        db: db,
        userId: userId,
        masterDataId: masterDataId,
        qty: qty,
      );
    }
  }

  Future<void> _decrementInventoryAndLog({
    required dynamic db,
    required int userId,
    required int masterDataId,
    required int qty,
    String? notes,
  }) async {
    final inventory = await db.query(
      'Data_Inventory',
      where: 'master_data_id = ?',
      whereArgs: [masterDataId],
      limit: 1,
    );

    if (inventory.isEmpty) {
      return;
    }

    final initialStock = inventory.first['stock'] as int;
    final currentStock = initialStock - qty;

    await db.update(
      'Data_Inventory',
      {
        'stock': currentStock,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'master_data_id = ?',
      whereArgs: [masterDataId],
    );

    final now = DateTime.now();
    final formattedDate = DateFormat('d MMM y, HH:mm:ss').format(now);

    await db.insert('Data_Inventory_Log', {
      'inventory_id': inventory.first['id'],
      'user_id': userId,
      'type': 'decrement',
      'initial_stock': initialStock,
      'current_stock': currentStock,
      'difference': qty,
      'notes': notes ??
          'Transaksi pada $formattedDate dengan pengurangan sebesar $qty',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
  }

  Future<void> _decrementInventoryByIdAndLog({
    required dynamic db,
    required int userId,
    required int inventoryId,
    required int qty,
    String? notes,
  }) async {
    final inventory = await db.query(
      'Data_Inventory',
      where: 'id = ?',
      whereArgs: [inventoryId],
      limit: 1,
    );

    if (inventory.isEmpty) {
      return;
    }

    final initialStock = inventory.first['stock'] as int;
    final currentStock = initialStock - qty;

    await db.update(
      'Data_Inventory',
      {
        'stock': currentStock,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [inventoryId],
    );

    final now = DateTime.now();
    final formattedDate = DateFormat('d MMM y, HH:mm:ss').format(now);

    await db.insert('Data_Inventory_Log', {
      'inventory_id': inventoryId,
      'user_id': userId,
      'type': 'decrement',
      'initial_stock': initialStock,
      'current_stock': currentStock,
      'difference': qty,
      'notes': notes ??
          'Transaksi pada $formattedDate dengan pengurangan sebesar $qty',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
  }

  Future<Map<String, int>> _getDailyTransactionCount() async {
    final db = await DatabaseHelper.instance.database;

    // Dapatkan tanggal hari ini dalam format YYYY-MM-DD
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Hitung jumlah transaksi hari ini
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM Data_Transaction WHERE DATE(created_at) = ?',
        [today]);

    final dailyCount = result.first['count'] as int? ?? 0;

    // Dapatkan ID transaksi terakhir
    final lastIdResult =
        await db.rawQuery('SELECT MAX(id) as last_id FROM Data_Transaction');

    final lastId = lastIdResult.first['last_id'] as int? ?? 0;

    return {
      'dailyCount': dailyCount + 1, // +1 untuk transaksi yang akan dibuat
      'lastId': lastId + 1 // +1 untuk transaksi yang akan dibuat
    };
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
      final nominal =
          int.tryParse(_discountNominalController.text.replaceAll('.', '')) ??
              0;
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
      final items = await _masterDataRepo.getAllMasterDataForSelectCategory();
      setState(() {
        _masterDataItems = items;
      });
      final items2 = await _masterDataRepo.getAllMasterData();
      setState(() {
        _backgroundDataItems = items2;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data master: $e')),
      );
    }
  }

  Future<void> _loadCartItems() async {
    final items = await _transactionItemRepo.getAllCartItems();
    final bundleDetails = await _loadBundleDetails(items);

    if (mounted) {
      setState(() {
        _cartItems = items;
        _bundleDetailByBundleId = bundleDetails;
      });
      _calculateTotalPrice();
    }
  }

  Future<Map<int, List<Map<String, dynamic>>>> _loadBundleDetails(
      List<TransactionItem> items) async {
    final details = <int, List<Map<String, dynamic>>>{};

    for (final item in items) {
      if (item.bundleId != null && item.bundleSnapshot != null) {
        final parsed = _parseBundleSnapshot(item.bundleSnapshot!);
        if (parsed.isNotEmpty) {
          details[item.bundleId!] = parsed;
          continue;
        }
      }

      final master = await _masterDataRepo.getMasterDataById(item.masterDataId);
      if (master == null || master.id == null) {
        continue;
      }

      final bundleItems =
          await _bundleRepository.getBundleItemsWithMasterData(master.id!);
      if (bundleItems.isNotEmpty) {
        details[master.id!] = bundleItems;
      }
    }

    return details;
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

  Future<String?> _buildBundleSnapshot(MasterData selectedMasterData) async {
    if (selectedMasterData.id == null) {
      return null;
    }

    final bundleItems = await _bundleRepository
        .getBundleItemsWithMasterData(selectedMasterData.id!);

    if (bundleItems.isEmpty) {
      return null;
    }

    final snapshot = bundleItems
        .map(
          (item) => {
            'component_inventory_id': item['component_inventory_id'],
            'component_master_data_id': item['component_master_data_id'],
            'component_type': item['component_type'],
            'component_name': item['component_name'],
            'component_category_name': item['component_category_name'],
            'qty': item['qty'],
          },
        )
        .toList();

    return jsonEncode(snapshot);
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

    // Validasi untuk Product: harus ada data background
    // if (_selectedOrderCategory == "Product") {
    //   final backgroundItems = _backgroundDataItems
    //       .where((item) => item.category == "Background")
    //       .toList();

    //   if (backgroundItems.isEmpty) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(
    //           content: Text(
    //               'Tidak dapat menambahkan produk karena belum ada data background. Harap hubungi admin.')),
    //     );
    //     return;
    //   }

    //   if (_selectedBackground == null) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text('Harap pilih background untuk produk')),
    //     );
    //     return;
    //   }
    // }

    final qty = int.tryParse(_orderQuantityController.text) ?? 1;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }

    try {
      // 1. Cari data master yang dipilih
      final selectedMasterData = _filteredMasterDataItems.firstWhere(
        (item) => item.name == _selectedOrderItem,
        orElse: () => throw Exception('Item tidak ditemukan'),
      );

      final isProduct = _isCategoryCode(selectedMasterData, 'product');

      // Lakukan pengecekan stok jika item memiliki stok di inventory.
      final availableStock = await _masterDataRepo
          .getStockByMasterDataId(selectedMasterData.id!);
      if (availableStock != null) {
        // Cek apakah stok cukup
        if (availableStock < qty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Stok ${selectedMasterData.name} tidak cukup. Stok tersedia: $availableStock')),
          );
          return;
        }
      }

      // Tambahkan produk utama ke keranjang
      await _addItemToCart(_selectedOrderItem!, qty, isNewItem);

      // Jika kategori Product, tambahkan background juga
      if (isProduct && _selectedBackground != null) {
        await _addItemToCart(_selectedBackground!, qty, isNewItem);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item ditambahkan ke keranjang'),
          duration: Duration(seconds: 1),
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

  Future<void> _addItemToCart(String itemName, int qty, bool isNewItem) async {
    try {
      // Cari master data yang dipilih
      final selectedMasterData = _backgroundDataItems.firstWhere(
        (item) => item.name == itemName,
        orElse: () => throw Exception('Item $itemName tidak ditemukan'),
      );

      final existingItem = await _transactionItemRepo
          .findExistingCartItem(selectedMasterData.id!);
      final bundleSnapshot = await _buildBundleSnapshot(selectedMasterData);
      final bundleId =
          bundleSnapshot != null ? selectedMasterData.id : null;

      if (existingItem != null) {
        final int totalQty;
        final int totalPrice;
        if (!isNewItem) {
          totalQty = qty;
          totalPrice = (selectedMasterData.price ?? 0) * qty;
        } else {
          totalQty = existingItem.qty + qty;
          totalPrice = (existingItem.totalPrice ~/ existingItem.qty) * totalQty;
        }

        final updatedItem = TransactionItem(
          id: existingItem.id,
          masterDataId: existingItem.masterDataId,
          bundleId: bundleId,
          bundleSnapshot: bundleSnapshot,
          qty: totalQty,
          totalPrice: totalPrice,
          createdAt: existingItem.createdAt,
          updatedAt: DateTime.now(),
        );

        await _transactionItemRepo.updateTransactionItem(updatedItem);
      } else {
        final totalPrice = (selectedMasterData.price ?? 0) * qty;

        final newItem = TransactionItem(
          masterDataId: selectedMasterData.id!,
          bundleId: bundleId,
          bundleSnapshot: bundleSnapshot,
          qty: qty,
          totalPrice: totalPrice,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _transactionItemRepo.insertTransactionItem(newItem);
      }
    } catch (e) {
      print('Error adding item to cart: $e');
      rethrow; // Kembalikan error untuk ditangani di level atas
    }
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

    await _ensureBundleDetailsLoadedForSelectedItem(masterData?.name);
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
      _selectedBackground = null;
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
        _overlaySource = 'phone';
      });
      if (_phoneFocusNode.hasFocus) {
        _showOverlay();
      }
    } else {
      _removeOverlay();
    }
  }

  Future<void> _onNameChanged() async {
    final text = _nameController.text;

    if (text.length >= 3) {
      final results = await CustomerRepository(DatabaseHelper.instance)
          .searchCustomers(text);
      setState(() {
        _searchResults = results;
        _overlaySource = 'name';
      });
      if (_nameFocusNode.hasFocus) {
        _showOverlay();
      }
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    final activeKey = _overlaySource == 'name' ? _nameFieldKey : _phoneFieldKey;
    final renderBox =
        activeKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final searchText =
        _overlaySource == 'name' ? _nameController.text : _phoneController.text;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _removeOverlay();
                _phoneFocusNode.unfocus();
                _nameFocusNode.unfocus();
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
                          subtitle: searchText,
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
    });
    _phoneFocusNode.unfocus();
    _nameFocusNode.unfocus();
    _removeOverlay();
  }

  void _selectAddNewOption() {
    _removeOverlay();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_overlaySource == 'name') {
        FocusScope.of(context).requestFocus(_phoneFocusNode);
      } else {
        FocusScope.of(context).requestFocus(_nameFocusNode);
      }
    });
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
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
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
                color: CustomColors.fontSubColor,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: CustomColors.borderInputColor,
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
              fillColor: CustomColors.inputColor,
              isDense: true,
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
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
        SizedBox(
          key: _nameFieldKey,
          child: TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            onTap: () {
              if (_nameController.text.length >= 3) {
                setState(() => _overlaySource = 'name');
                _showOverlay();
              }
            },
            decoration: InputDecoration(
              hintText: 'Masukkan nama',
              hintStyle: TextStyle(
                fontSize: 14,
                fontFamily: 'Inter',
                color: CustomColors.fontSubColor,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: CustomColors.borderInputColor,
                  width: 1.0,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: CustomColors.borderInputColor,
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
              fillColor: CustomColors.inputColor,
              isDense: true,
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
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

    final transactionCounts = await _getDailyTransactionCount();
    final dailyCount = transactionCounts['dailyCount']!;
    final lastId = transactionCounts['lastId']!;

    // Format invoice number: CUST-001-123
    final dailyCountFormatted = dailyCount.toString().padLeft(3, '0');
    final transactionId = lastId.toString().padLeft(3, '0');
    final invoiceNumber = 'CUST-$dailyCountFormatted-$transactionId';

    final now = DateTime.now();
    final formattedDate = DateFormat('d MMM y, HH:mm:ss').format(now);

    // Hitung total harga
    final totalPrice = _cartItems.fold(0, (sum, item) => sum + item.totalPrice);

    // Hitung diskon
    final discountNominal =
        int.tryParse(_discountNominalController.text.replaceAll('.', '')) ?? 0;
    final discountPercent = int.tryParse(_discountPercentController.text) ?? 0;
    final discountPrice =
        discountNominal + (totalPrice * discountPercent ~/ 100);
    final finalPrice = totalPrice - discountPrice;

    final cartItemsAsMaps = _cartItems.map((item) {
      final masterData =
          _backgroundDataItems.firstWhere((m) => m.id == item.masterDataId);
      return {
        'id': item.id,
        'master_data_id': item.masterDataId,
        'name': masterData.name,
        'category': masterData.category,
        'qty': item.qty,
        'price': masterData.price,
        'total_price': item.totalPrice,
        'bundle_components': item.bundleSnapshot != null
            ? _parseBundleSnapshot(item.bundleSnapshot!)
            : [],
      };
    }).toList();

    final transactionData = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'date': formattedDate,
      'invoice': invoiceNumber,
      'daily_count': dailyCount, // Simpan juga daily count untuk keperluan lain
      'discount_nominal': discountNominal,
      'discount_percent': discountPercent,
      'discount_price': discountPrice,
      'total_price': totalPrice,
      'final_price': finalPrice,
      'payment_method': _selectedPaymentMethod,
      'note': _noteController.text,
      'cart_items': cartItemsAsMaps
    };

    _showReviewOrderModal(transactionData);
  }

  void _showReviewOrderModal(Map<String, dynamic> transactionData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ReviewOrderModal(
            onProcess: _processTransaction,
            onCancel: () => Navigator.of(context).pop(),
            transactionData: transactionData,
            customerPhone: _phoneController.text,
          ),
        );
      },
    );
  }

  // void _showReviewOrderModal(Map<String, dynamic> transactionData) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Dialog(
  //         insetPadding: EdgeInsets.all(16.0),
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         child: ReviewOrderModal(
  //           onProcess: _processTransaction,
  //           onCancel: () {
  //             Navigator.of(context).pop(); // Close the modal
  //           },
  //           transactionData: transactionData,
  //         ),
  //       );
  //     },
  //   );
  // }

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
                                color: Colors.white,
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
                                  color: CustomColors.fontSubColor,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: CustomColors.borderInputColor,
                                      width: 1.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF1379F0), width: 1.0),
                                ),
                                filled: true,
                                fillColor: CustomColors.inputColor,
                                isDense: true,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              onChanged: (value) {
                                String digitsOnly =
                                    value.replaceAll(RegExp(r'[^0-9]'), '');
                                setState(() {
                                  _isNominalDiscount = value.isNotEmpty;
                                  if (_isNominalDiscount) {
                                    _isPercentageDiscount = false;
                                    _discountPercentController.clear();
                                  }

                                  // Periksa apakah digitsOnly tidak kosong sebelum parsing
                                  if (digitsOnly.isNotEmpty) {
                                    try {
                                      final number = int.parse(digitsOnly);
                                      final formatted =
                                          _formatWithThousandSeparator(number);

                                      _discountNominalController.value =
                                          TextEditingValue(
                                        text: formatted,
                                        selection: TextSelection.collapsed(
                                            offset: formatted.length),
                                      );
                                    } catch (e) {
                                      // Handle error parsing jika diperlukan
                                      _discountNominalController.value =
                                          TextEditingValue(
                                        text: '',
                                        selection:
                                            const TextSelection.collapsed(
                                                offset: 0),
                                      );
                                    }
                                  } else {
                                    // Jika digitsOnly kosong (semua dihapus)
                                    _discountNominalController.value =
                                        TextEditingValue(
                                      text: '',
                                      selection: const TextSelection.collapsed(
                                          offset: 0),
                                    );
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
                                color: Colors.white,
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
                                  color: CustomColors.fontSubColor,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: CustomColors.borderInputColor,
                                      width: 1.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF1379F0), width: 1.0),
                                ),
                                filled: true,
                                fillColor: CustomColors.inputColor,
                                isDense: true,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
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
                                color: Colors.white,
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
                                color: Colors.white,
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
                                color: Colors.white,
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
                                color: Colors.white,
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
                                        color: CustomColors.fontSubColor,
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
                bottom: title == 'Keranjang'
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
        color: Colors.white,
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
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            color: CustomColors.fontSubColor,
          ),
          contentPadding: const EdgeInsets.all(12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: CustomColors.borderInputColor,
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
          fillColor: CustomColors.inputColor,
          alignLabelWithHint: isNoteField, // Better alignment for multiline
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = _masterDataItems.map((e) => e.category).toSet().toList();

    return DropdownButtonFormField<String>(
      value: _selectedOrderCategory,
      isExpanded: true,
      hint: const Text(
        'Pilih kategori',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: CustomColors.fontSubColor,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      items: categories.map((category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(
            category,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedOrderCategory = value;
          _filterMasterDataItems(value);
          _useRemainingPaper = false;
          _selectedOrderItem = null;
        });
      },
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: CustomColors.borderInputColor, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1379F0), width: 1.0),
        ),
        filled: true,
        fillColor: CustomColors.inputColor,
        isDense: true,
      ),
      style: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
      dropdownColor: CustomColors.inputColor,
      borderRadius: BorderRadius.circular(8),
    );
  }

  Widget _buildItemDropdown() {
    return DropdownButtonFormField<String>(
      value: _filteredMasterDataItems.isEmpty ? null : _selectedOrderItem,
      isExpanded: true, // Tambahkan ini
      hint: Text(
        _filteredMasterDataItems.isEmpty
            ? 'Pilih kategori terlebih dahulu'
            : 'Pilih Item',
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          color: CustomColors.fontSubColor,
          overflow: TextOverflow.ellipsis, // Tambahkan ini
        ),
      ),
      items: _filteredMasterDataItems.isEmpty
          ? null
          : _filteredMasterDataItems.map((item) {
              return DropdownMenuItem<String>(
                value: item.name,
                child: Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
      onChanged: _filteredMasterDataItems.isEmpty
          ? null
          : (value) async {
              setState(() {
                _selectedOrderItem = value;
                _useRemainingPaper = false;
              });

              await _ensureBundleDetailsLoadedForSelectedItem(value);
            },
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: CustomColors.borderInputColor, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1379F0), width: 1.0),
        ),
        filled: true,
        fillColor: _filteredMasterDataItems.isEmpty
            ? CustomColors.borderCardColor
            : CustomColors.inputColor,
        isDense: true,
      ),
      style: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
      dropdownColor: CustomColors.inputColor,
    );
  }

  Widget _buildOrderInputRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormLabel('Kategori'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: _buildCategoryDropdown(),
                  ),
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
                  SizedBox(
                    width: double.infinity,
                    child: _buildItemDropdown(),
                  ),
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
                        color: Colors.white,
                        height: 1.0,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Masukkan jumlah',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          color: CustomColors.fontSubColor,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: CustomColors.inputColor,
                        suffixIcon: SizedBox(
                          width: 24,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                                        color: CustomColors.fontSubColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 1,
                                width: 16,
                                color: CustomColors.borderInputColor,
                              ),
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
                                        color: CustomColors.fontSubColor,
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
                      icon:
                          const Icon(Icons.edit, color: Colors.white, size: 20),
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
                      icon: const Icon(Icons.delete,
                          color: Colors.white, size: 20),
                      onPressed: () => _deleteCartItem(_selectedCartItem!.id!),
                    ),
                  ),
                ],
              ),
          ],
        ),

        if (_selectedCategoryCode() == 'paper' ||
            ((_selectedCategoryCode()?.startsWith('bundle') == true ||
                    _selectedCategoryCode() == 'bundling') &&
                _selectedBundleHasPaperComponent())) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _useRemainingPaper,
                onChanged: (value) {
                  setState(() {
                    _useRemainingPaper = value ?? false;
                  });
                },
                activeColor: const Color(0xFF1379F0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 4),
              const Text(
                'Gunakan sisa kertas',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
        // Add background selection for Product category
        if (_selectedCategoryCode() == 'product') ...[
          const SizedBox(height: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildFormLabel('Pilih Background'),
                  const SizedBox(width: 4),
                  const Text(
                    '(Opsional)',
                    style: TextStyle(
                      fontSize: 12,
                      color: CustomColors.fontSubColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildBackgroundRadioButtons(),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBackgroundRadioButtons() {
    // Filter master data to get only background items
    final backgroundItems = _backgroundDataItems
        .where((item) => _isCategoryCode(item, 'background'))
        .toList();

    // Jika tidak ada data background
    if (backgroundItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          'Belum ada data background',
          style: TextStyle(
            color: Colors.orange.shade300,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: backgroundItems.map((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(
                  value: item.name,
                  groupValue: _selectedBackground,
                  onChanged: (value) {
                    setState(() {
                      _selectedBackground = value;
                    });
                  },
                  activeColor: const Color(0xFF1379F0),
                  fillColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return const Color(0xFF1379F0);
                      }
                      return CustomColors.borderInputColor;
                    },
                  ),
                ),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPaymentMethod,
      isExpanded: true,
      hint: const Text(
        'Pilih metode pembayaran',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: CustomColors.fontSubColor,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      items: const ['Cash', 'QRIS'].map((method) {
        return DropdownMenuItem<String>(
          value: method,
          child: Text(
            method,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedPaymentMethod = newValue;
        });
      },
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: CustomColors.borderInputColor, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1379F0), width: 1.0),
        ),
        filled: true,
        fillColor: CustomColors.inputColor,
        isDense: true,
      ),
      style: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
      dropdownColor: CustomColors.inputColor,
      borderRadius: BorderRadius.circular(8),
    );
  }

  Widget _buildCartTable() {
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
          if (_cartItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: Text(
                  'Keranjang kosong',
                  style: TextStyle(color: CustomColors.fontSubColor),
                ),
              ),
            )
          else
            ..._cartItems.map((item) {
              final masterData = _backgroundDataItems.firstWhere(
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
                            ? CustomColors.borderInputColor
                            : _hoveredCartItem?.id == item.id
                                ? CustomColors.borderCardColor
                                : CustomColors.cardColor,
                        border: const Border(
                            bottom: BorderSide(
                                color: CustomColors.borderCardColor)),
                      ),
                      child: Column(
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                _buildTableCell(masterData.category, 2),
                                VerticalDivider(
                                    thickness: 1,
                                    width: 1,
                                    color: CustomColors.borderCardColor),
                                _buildTableCell(masterData.name, 3),
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
                                    _formatPrice(item.totalPrice), 2),
                              ],
                            ),
                          ),
                          if (item.bundleId != null && masterData.id != null)
                            _buildBundleDetailCell(masterData.id!, item.qty),
                        ],
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
              color: CustomColors.fontSubColor,
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
            color: Colors.white,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildBundleDetailCell(int bundleId, int bundleQty) {
    final details = _bundleDetailByBundleId[bundleId] ?? [];
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
}

String _formatWithThousandSeparator(dynamic value) {
  if (value == null) return '';

  int number;
  if (value is String) {
    number = int.tryParse(value.replaceAll('.', '')) ?? 0;
  } else {
    number = value as int;
  }

  return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
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
  final String customerPhone;

  const ReviewOrderModal({
    Key? key,
    required this.onProcess,
    required this.onCancel,
    required this.transactionData,
    required this.customerPhone,
  }) : super(key: key);

  @override
  _ReviewOrderModalState createState() => _ReviewOrderModalState();
}

class _ReviewOrderModalState extends State<ReviewOrderModal> {
  bool _isProcessing = false;
  bool _showReceiptOptions = false;
  List<dynamic> _cartItems = [];
  Map<int, MasterData> _masterDataMap = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeCartItems();
    _fetchMasterData();
  }

  void _initializeCartItems() {
    final items = widget.transactionData['cart_items'];
    if (items is List<TransactionItem>) {
      _cartItems = items;
    } else if (items is List<Map<String, dynamic>>) {
      // Convert maps to TransactionItems if needed
      _cartItems = items
          .map((item) => TransactionItem(
                id: item['id'],
                masterDataId: item['master_data_id'],
                qty: item['qty'],
                totalPrice: item['total_price'],
                createdAt:
                    DateTime.now(), // You might need to handle this properly
                updatedAt: DateTime.now(),
              ))
          .toList();
    }
    setState(() => isLoading = false);
  }

  Future<void> _fetchMasterData() async {
    final Set<int> masterDataIds = _cartItems.map((item) {
      return (item as TransactionItem).masterDataId;
    }).toSet();
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
      isLoading = false;
    });
  }

  Future<void> _handleProcessTransaction() async {
    setState(() => _isProcessing = true);
    try {
      await widget.onProcess(widget.transactionData);
      setState(() => _showReceiptOptions = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Widget _buildTransactionReview() {
    final name = widget.transactionData['name'] as String;
    final phone = widget.transactionData['phone'] as String;
    final date = widget.transactionData['date'] as String;
    final invoice = widget.transactionData['invoice'] as String;
    final paymentMethod =
        widget.transactionData['payment_method'] as String? ?? '-';
    final num totalPrice = _cartItems.fold(0.0, (sum, item) {
      return sum + (item as TransactionItem).totalPrice;
    });
    final discountNominal = widget.transactionData['discount_nominal'] as int;
    final discountPercent = widget.transactionData['discount_percent'] as int;
    final discountPrice =
        discountNominal + (totalPrice * discountPercent ~/ 100);
    final finalPrice = totalPrice - discountPrice;

    return Column(
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
        const Divider(height: 1, color: CustomColors.borderCardColor),
        const SizedBox(height: 16),

        // Order items
        Column(
          children: _cartItems.map((item) {
            final masterData = _masterDataMap[item is TransactionItem
                ? item.masterDataId
                : item['master_data_id']];
            final String itemName = masterData?.name ?? 'Unknown Item';
            final int qty = item is TransactionItem ? item.qty : item['qty'];
            final int totalPrice =
                item is TransactionItem ? item.totalPrice : item['total_price'];

            return _buildItemPesanan(
              itemName,
              qty.toString(),
              _formatPrice(totalPrice),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),
        const Divider(height: 1, color: CustomColors.borderCardColor),
        const SizedBox(height: 16),

        _buildPaymentRow('Diskon', _formatPrice(discountPrice)),
        const SizedBox(height: 8),
        _buildPaymentRow('Total', _formatPrice(finalPrice.toDouble().toInt())),
        const SizedBox(height: 8),
        _buildPaymentRow('Pembayaran', paymentMethod),
      ],
    );
  }

  Widget _buildTransactionActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: widget.onCancel,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: CustomColors.cardColor),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text(
            'Batal',
            style: TextStyle(
              color: CustomColors.fontSubColor,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isProcessing ? null : _handleProcessTransaction,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1379F0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Proses',
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 14),
                ),
        ),
      ],
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
              color: Colors.white,
            ),
          ),
        ),
        const Text(
          ':',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            color: Colors.white,
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
              color: Colors.white,
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
              color: Colors.white,
            ),
          ),
        ),
        const Text(
          ':',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            color: Colors.white,
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
              color: Colors.white,
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
                color: Colors.white,
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
                color: Colors.white,
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
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

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
                Text(
                  _showReceiptOptions ? 'Cetak Struk' : 'Tinjau Pesanan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 20, color: CustomColors.fontSubColor),
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
            child: _showReceiptOptions
                ? _buildReceiptOptions()
                : _buildTransactionReview(),
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
            child: _showReceiptOptions
                ? _buildReceiptActionButtons()
                : _buildTransactionActionButtons(),
          ),

          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     border: Border(
          //       top: BorderSide(color: Colors.grey.shade200, width: 1.0),
          //     ),
          //   ),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.end,
          //     children: [
          //       OutlinedButton(
          //         onPressed: widget.onCancel,
          //         style: OutlinedButton.styleFrom(
          //           side: const BorderSide(color: Color(0xFFE5E7EB)),
          //           padding: const EdgeInsets.symmetric(
          //               horizontal: 16, vertical: 10),
          //           shape: RoundedRectangleBorder(
          //             borderRadius: BorderRadius.circular(6),
          //           ),
          //         ),
          //         child: const Text(
          //           'Batal',
          //           style: TextStyle(
          //             color: Color(0xFF4B5675),
          //             fontFamily: 'Inter',
          //             fontWeight: FontWeight.w500,
          //             fontSize: 14,
          //           ),
          //         ),
          //       ),
          //       const SizedBox(width: 12),
          //       ElevatedButton(
          //         onPressed: () {
          //           widget.onProcess(widget
          //               .transactionData); // Panggil dengan data transaksi
          //           widget.onCancel(); // Tutup dialog
          //         },
          //         style: ElevatedButton.styleFrom(
          //           backgroundColor: const Color(0xFF1379F0),
          //           padding: const EdgeInsets.symmetric(
          //               horizontal: 16, vertical: 10),
          //           shape: RoundedRectangleBorder(
          //             borderRadius: BorderRadius.circular(6),
          //           ),
          //         ),
          //         child: const Text(
          //           'Proses',
          //           style: TextStyle(
          //               color: Colors.white,
          //               fontFamily: 'Inter',
          //               fontWeight: FontWeight.w500,
          //               fontSize: 14),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildReceiptOptions() {
    return Column(
      children: [
        const Text(
          'Pilih opsi struk:',
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
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
              onTap: () => ReceiptService.printReceipt(widget.transactionData),
            ),
            _buildReceiptOptionButton(
              icon: Icons.save_alt,
              label: 'Simpan PDF',
              onTap: () => ReceiptService.saveReceiptPdf(
                  widget.transactionData, context),
            ),
            _buildReceiptOptionButton(
              icon: Icons.share,
              label: 'Share ke WA',
              onTap: () => ReceiptService.shareReceipt(
                widget.transactionData,
                widget.customerPhone,
              ),
            ),
          ],
        ),
      ],
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

  Widget _buildReceiptActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: widget.onCancel,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
    );
  }
}
