import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool isReusedPaper;

  _CartEntry({
    required this.masterDataId,
    required this.name,
    required this.category,
    required this.price,
    required this.qty,
    this.bundleSnapshot,
    this.isReusedPaper = false,
  });

  int get totalPrice => price * qty;
}

class _EditPesananFormState extends State<EditPesananForm> {
  final MasterDataRepository _masterDataRepo =
      MasterDataRepository(DatabaseHelper.instance);
  final BundleRepository _bundleRepository =
      BundleRepository(DatabaseHelper.instance);

  final TextEditingController _qtyController = TextEditingController();

  List<_CartEntry> _cart = [];
  List<MasterData> _masterDataItems = [];
  List<String> _categories = [];
  String? _selectedCategory;
  String? _selectedItem;
  bool _useRemainingPaper = false;

  bool _isLoading = true;
  bool _isSaving = false;
  int _finalPrice = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _qtyController.dispose();
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
          isReusedPaper: item.isReusedPaper == 1,
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
    setState(() {
      _finalPrice = total;
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
          isReusedPaper: _useRemainingPaper,
        ));
      }
      _selectedItem = null;
      _qtyController.clear();
      _useRemainingPaper = false;
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
                'is_reused_paper': e.isReusedPaper ? 1 : 0,
              })
          .toList();

      final discount = 0; // Removed discount from edit mode

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
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAddItemCard(),
        const SizedBox(height: 16),
        _buildCartCard(),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

  bool _showReusePaperCheckbox() {
    print('DEBUG: _selectedCategory = $_selectedCategory');
    if (_selectedCategory == null) return false;
    final cat = _selectedCategory!.toLowerCase().trim();
    print('DEBUG: trimmed cat = "$cat"');
    return cat == 'paper' || cat == 'print' || cat.startsWith('bundle') || cat == 'bundling';
  }

  Widget _buildAddItemCard() {
    return _buildSectionCard(
      'Tambah Item',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Kategori'),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: _dropdown<String>(
                        value: _selectedCategory,
                        hint: 'Pilih kategori',
                        items: _categories,
                        itemLabel: (v) => v,
                        onChanged: (v) => setState(() {
                          _selectedCategory = v;
                          _selectedItem = null;
                        }),
                      ),
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
                    SizedBox(
                      width: double.infinity,
                      child: _dropdown<String>(
                        value: _selectedItem,
                        hint: _selectedCategory == null
                            ? 'Pilih kategori dulu'
                            : 'Pilih item',
                        items: _filteredItems.map((e) => e.name).toList(),
                        itemLabel: (v) => v,
                        onChanged: (v) => setState(() => _selectedItem = v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Jumlah'),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _qtyController,
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
                          hintText: '1',
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
                                                _qtyController.text) ??
                                            1;
                                        _qtyController.text =
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
                                                _qtyController.text) ??
                                            1;
                                        if (current > 1) {
                                          _qtyController.text =
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
                  onPressed: _addItem,
                ),
              ),
            ],
          ),
          if (_showReusePaperCheckbox()) ...[
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
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (item.isReusedPaper) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1379F0)
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      border: Border.all(
                                          color: const Color(0xFF1379F0)
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: const Text(
                                      'Pakai Kertas Sisa',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF1379F0),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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