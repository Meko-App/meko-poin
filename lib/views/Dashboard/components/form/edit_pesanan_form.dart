import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meko_poin/models/master_data.dart';
import 'package:meko_poin/services/bundle_repository.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/master_data_repository.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditPesananForm extends StatefulWidget {
  final int transactionId;
  final TransactionRepository transactionRepository;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  const EditPesananForm({
    super.key,
    required this.transactionId,
    required this.transactionRepository,
    required this.onCancel,
    required this.onSaved,
  });

  @override
  State<EditPesananForm> createState() => _EditPesananFormState();
}

class _CartEntry {
  final int masterDataId;
  final String name;
  final String category;
  final int price;
  int qty;
  final String? bundleSnapshot;

  _CartEntry({
    required this.masterDataId,
    required this.name,
    required this.category,
    required this.price,
    required this.qty,
    this.bundleSnapshot,
  });

  int get totalPrice => price * qty;
}

class _EditPesananFormState extends State<EditPesananForm> {
  final MasterDataRepository _masterDataRepo =
      MasterDataRepository(DatabaseHelper.instance);
  final BundleRepository _bundleRepository =
      BundleRepository(DatabaseHelper.instance);

  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  List<_CartEntry> _cart = [];
  List<MasterData> _masterDataItems = [];
  List<String> _categories = [];
  String? _selectedCategory;
  String? _selectedItem;

  bool _isLoading = true;
  bool _isSaving = false;
  int _totalPrice = 0;
  int _finalPrice = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items =
          await widget.transactionRepository.getTransactionItems(widget.transactionId);
      final cart = <_CartEntry>[];

      for (final item in items) {
        final details = await widget.transactionRepository
            .getItemDetails(item.masterDataId);
        final unitPrice = item.qty == 0
            ? item.totalPrice
            : item.totalPrice ~/ item.qty;
        cart.add(_CartEntry(
          masterDataId: item.masterDataId,
          name: (details['name'] as String?) ?? 'Item #${item.masterDataId}',
          category: (details['category'] as String?) ?? 'Produk',
          price: unitPrice,
          qty: item.qty,
          bundleSnapshot: item.bundleSnapshot,
        ));
      }

      final masterData = await _masterDataRepo.getAllMasterDataForSelectCategory();
      final categories = masterData
          .map((m) => m.category)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (!mounted) return;

      setState(() {
        _cart = cart;
        _masterDataItems = masterData;
        _categories = categories;
        _isLoading = false;
      });
      _recalculate();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data pesanan: $e')),
      );
    }
  }

  List<MasterData> get _filteredItems {
    if (_selectedCategory == null) return [];
    return _masterDataItems
        .where((item) => item.category == _selectedCategory)
        .toList();
  }

  void _recalculate() {
    final total = _cart.fold(0, (sum, e) => sum + e.totalPrice);
    final discount = int.tryParse(_discountController.text.replaceAll('.', '')) ?? 0;
    setState(() {
      _totalPrice = total;
      _finalPrice = total - discount;
    });
  }

  void _increaseQty(int index) {
    setState(() {
      _cart[index].qty += 1;
    });
    _recalculate();
  }

  void _decreaseQty(int index) {
    if (_cart[index].qty <= 1) {
      _removeItem(index);
      return;
    }
    setState(() {
      _cart[index].qty -= 1;
    });
    _recalculate();
  }

  void _removeItem(int index) {
    setState(() {
      _cart.removeAt(index);
    });
    _recalculate();
  }

  Future<void> _addItem() async {
    if (_selectedCategory == null || _selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori dan item terlebih dahulu')),
      );
      return;
    }

    final qty = int.tryParse(_qtyController.text) ?? 1;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }

    MasterData? selected;
    for (final item in _filteredItems) {
      if (item.name == _selectedItem) {
        selected = item;
        break;
      }
    }
    if (selected == null || selected.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item tidak ditemukan')),
      );
      return;
    }

    final md = selected;

    // Cek stok (memperhitungkan qty yang sudah ada di keranjang).
    final stock = await _masterDataRepo.getStockByMasterDataId(md.id!);
    if (stock != null) {
      final existingQty = _cart
          .where((e) => e.masterDataId == md.id)
          .fold(0, (sum, e) => sum + e.qty);
      final available = stock + existingQty;
      if (available < qty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Stok ${md.name} tidak cukup. Stok tersedia: $stock')),
        );
        return;
      }
    }

    // Bangun snapshot untuk bundle.
    String? snapshot;
    final bundleItems =
        await _bundleRepository.getBundleItemsWithMasterData(md.id!);
    if (bundleItems.isNotEmpty) {
      snapshot = jsonEncode(bundleItems
          .map((item) => {
                'component_inventory_id': item['component_inventory_id'],
                'component_master_data_id': item['component_master_data_id'],
                'component_type': item['component_type'],
                'component_name': item['component_name'],
                'component_category_name': item['component_category_name'],
                'qty': item['qty'],
              })
          .toList());
    }

    setState(() {
      final existingIndex = _cart.indexWhere(
          (e) => e.masterDataId == md.id && e.bundleSnapshot == snapshot);
      if (existingIndex >= 0) {
        _cart[existingIndex].qty += qty;
      } else {
        _cart.add(_CartEntry(
          masterDataId: md.id!,
          name: md.name,
          category: md.category,
          price: md.price ?? 0,
          qty: qty,
          bundleSnapshot: snapshot,
        ));
      }
      _selectedItem = null;
      _qtyController.clear();
    });
    _recalculate();
  }

  Future<void> _save() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan tidak boleh kosong')),
      );
      return;
    }
    if (_finalPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diskon melebihi total')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;

    setState(() => _isSaving = true);

    try {
      final items = _cart
          .map((e) => {
                'master_data_id': e.masterDataId,
                'qty': e.qty,
                'total_price': e.totalPrice,
                'bundle_snapshot': e.bundleSnapshot,
              })
          .toList();

      final discount =
          int.tryParse(_discountController.text.replaceAll('.', '')) ?? 0;

      await widget.transactionRepository.updateTransactionPesanan(
        transactionId: widget.transactionId,
        discountPrice: discount,
        finalPrice: _finalPrice,
        items: items,
        actorUserId: userId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil diperbarui')),
      );
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui pesanan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatPrice(int price) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onCancel,
          color: Colors.grey.shade700,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Pesanan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ubah item, jumlah, dan diskon transaksi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: CustomColors.fontSubColor,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAddItemCard(),
                  const SizedBox(height: 16),
                  _buildCartCard(),
                  const SizedBox(height: 16),
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: widget.onCancel,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              color: CustomColors.fontSubColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1379F0),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Simpan',
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
    );
  }

  Widget _buildSectionCard(String title, Widget content) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        border: Border.all(color: CustomColors.borderCardColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          Container(height: 1, color: CustomColors.borderCardColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemCard() {
    return _buildSectionCard(
      'Tambah Item',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Kategori'),
                    const SizedBox(height: 6),
                    _dropdown<String>(
                      value: _selectedCategory,
                      hint: 'Pilih kategori',
                      items: _categories,
                      itemLabel: (v) => v,
                      onChanged: (v) => setState(() {
                        _selectedCategory = v;
                        _selectedItem = null;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Item'),
                    const SizedBox(height: 6),
                    _dropdown<String>(
                      value: _selectedItem,
                      hint: _selectedCategory == null
                          ? 'Pilih kategori dulu'
                          : 'Pilih item',
                      items: _filteredItems.map((e) => e.name).toList(),
                      itemLabel: (v) => v,
                      onChanged: (v) => setState(() => _selectedItem = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Jumlah'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _inputDecoration('1'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _addItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1379F0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text(
                'Tambah',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        border: Border.all(color: CustomColors.borderCardColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Pesanan (${_cart.length})',
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Container(height: 1, color: CustomColors.borderCardColor),
          if (_cart.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Tidak ada item pesanan',
                  style: TextStyle(color: CustomColors.fontSubColor),
                ),
              ),
            )
          else
            ..._cart.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: CustomColors.borderCardColor),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${item.category} • ${_formatPrice(item.price)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: CustomColors.fontSubColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _qtyStepper(index),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 110,
                        child: Text(
                          _formatPrice(item.totalPrice),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeItem(index),
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Color(0xFFED143B)),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Hapus item',
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _qtyStepper(int index) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        border: Border.all(color: CustomColors.borderInputColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _decreaseQty(index),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.remove, size: 16, color: Colors.white),
            ),
          ),
          Container(width: 1, color: CustomColors.borderInputColor),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            child: Text(
              '${_cart[index].qty}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Container(width: 1, color: CustomColors.borderInputColor),
          InkWell(
            onTap: () => _increaseQty(index),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.add, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return _buildSectionCard(
      'Ringkasan',
      Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(color: CustomColors.fontSubColor, fontSize: 13),
              ),
              Text(
                _formatPrice(_totalPrice),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Diskon (Nominal)',
                  style:
                      TextStyle(color: CustomColors.fontSubColor, fontSize: 13),
                ),
              ),
              SizedBox(
                width: 160,
                child: TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('0'),
                  onChanged: (_) => _recalculate(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: CustomColors.borderCardColor),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                _formatPrice(_finalPrice),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: CustomColors.fontSubColor,
        fontFamily: 'Inter',
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: CustomColors.fontSubColor, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: CustomColors.inputColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: CustomColors.borderInputColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1379F0)),
      ),
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      height: 38,
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        hint: Text(
          hint,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: CustomColors.fontSubColor,
            fontSize: 13,
            fontFamily: 'Inter',
          ),
        ),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontFamily: 'Inter',
        ),
        dropdownColor: CustomColors.inputColor,
        icon: const Icon(Icons.keyboard_arrow_down,
            color: CustomColors.fontSubColor),
        iconSize: 20,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: CustomColors.inputColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: CustomColors.borderInputColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1379F0)),
          ),
        ),
        items: items
            .map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Inter'),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}