import 'package:flutter/material.dart';
import 'package:meko_poin/models/bundle_item.dart';
import 'package:meko_poin/services/master_data_repository.dart';
import 'package:meko_poin/services/bundle_repository.dart';
import 'package:meko_poin/services/category_repository.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:meko_poin/views/Dashboard/components/table/master_data_table/master_data_table.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/content_state.dart';
import 'package:meko_poin/views/Dashboard/components/form/master_data_form.dart';
import 'package:meko_poin/models/master_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MasterdataContent extends StatefulWidget {
  final Function(ContentState) onStateChanged;
  final MasterDataRepository masterDataRepository;

  const MasterdataContent(
      {super.key,
      required this.onStateChanged,
      required this.masterDataRepository});

  @override
  State<MasterdataContent> createState() => _MasterdataContentState();
}

class _MasterdataContentState extends State<MasterdataContent> {
  ContentState _currentState = ContentState.table;
  Map<String, dynamic>? _dataToEdit;
  late final MasterDataRepository masterDataRepository;
  late final BundleRepository _bundleRepository;
  final CategoryRepository _categoryRepository =
      CategoryRepository(DatabaseHelper.instance);

  @override
  void initState() {
    super.initState();
    masterDataRepository = widget.masterDataRepository;
    _bundleRepository = BundleRepository(DatabaseHelper.instance);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStateChanged(_currentState);
    });
  }

  void _showForm({MasterData? data}) {
    setState(() {
      _currentState = ContentState.form;
      _dataToEdit = data != null
          ? {
              'id': data.id,
              'name': data.name,
              'category_id': data.categoryId,
              'category_name': data.category,
              'price': data.price,
              'id_user': data.userId,
            }
          : null;
      widget.onStateChanged(_currentState);
    });
  }

  void _showTable() {
    setState(() {
      _currentState = ContentState.table;
      _dataToEdit = null;
      widget.onStateChanged(_currentState);
    });
  }

  Future<void> _handleDataFormSubmit(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    try {
      final categories = await _categoryRepository.getAllCategories();
      final selectedCategory = categories.where(
        (category) => category.id == data['category_id'],
      );

      if (selectedCategory.isEmpty) {
        throw Exception('Kategori tidak ditemukan');
      }

      final name = (data['name'] ?? '').toString().trim();
      final isNameUsed = await masterDataRepository.isNameAlreadyUsed(
        name,
        categoryId: data['category_id'] as int?,
        excludeId: _dataToEdit?['id'] as int?,
      );

      if (isNameUsed) {
        throw Exception('Nama menu sudah digunakan pada kategori ini');
      }

      final priceString = data['price']?.toString() ?? '';
      final cleanedPrice = priceString.replaceAll(RegExp(r'[^0-9]'), '');
      final priceValue = cleanedPrice.isEmpty ? 0 : int.parse(cleanedPrice);
      final bundleItemsRaw =
          (data['bundle_items'] as List<Map<String, dynamic>>?) ?? [];

      Future<void> saveBundleItems(int masterDataId) async {
        final bundleItems = bundleItemsRaw
            .where((item) => (item['component_inventory_id'] as int?) != null)
            .map(
              (item) => BundleItem(
                bundleId: masterDataId,
                componentInventoryId: item['component_inventory_id'] as int,
                componentType: (item['component_type'] as String).toLowerCase(),
                qty: (item['qty'] as int?) ?? 1,
              ),
            )
            .toList();

        if (bundleItems.isEmpty) {
          await _bundleRepository.deleteBundleItems(masterDataId);
          return;
        }

        await _bundleRepository.replaceBundleItems(masterDataId, bundleItems);
      }

      if (_dataToEdit == null) {
        final newData = MasterData(
          id: null,
          name: name,
          categoryId: data['category_id'],
          category: data['category_name'] ?? '',
          price: priceValue,
          userId: userId,
        );
        final createdId = await masterDataRepository.insertMasterData(newData);
        await saveBundleItems(createdId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu baru berhasil ditambahkan')),
          );
        }
      } else {
        // Edit existing data
        final updatedData = MasterData(
          id: _dataToEdit!['id'],
          name: name,
          categoryId: data['category_id'],
          category: data['category_name'] ?? '',
          price: priceValue,
          userId: _dataToEdit!['id_user'],
        );
        await masterDataRepository.updateMasterData(updatedData);
        await saveBundleItems(_dataToEdit!['id'] as int);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu berhasil diperbarui')),
          );
        }
      }
      _showTable();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double currentMaxHeight = _currentState == ContentState.table
        ? MediaQuery.of(context).size.height * 0.77
        : double.infinity;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_currentState == ContentState.form)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _showTable,
                  color: Colors.grey.shade700,
                ),
              if (_currentState == ContentState.form) const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentState == ContentState.table
                        ? "Menu"
                        : (_dataToEdit != null
                            ? "Edit Menu"
                            : "Buat Menu Baru"),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Kelola menu dan daftar komponennya",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: CustomColors.fontSubColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: currentMaxHeight,
            ),
            child: _currentState == ContentState.table
                ? MasterDataTable(
                    onAddNew: _showForm,
                    masterDataRepository: masterDataRepository,
                    onEditMasterData: (data) => _showForm(data: data),
                    onDeleteMasterData: (data) async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: Colors.grey[900],
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header dengan ikon dan judul
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.amber,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Konfirmasi Penghapusan',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Divider(
                                      height: 1,
                                      color: Colors.grey[700],
                                    ),
                                    const SizedBox(height: 10),
                                    // Content text
                                    Text(
                                      'Hapus menu ${data.category} ${data.name} ini?',
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Tindakan ini tidak dapat dibatalkan.',
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Divider
                                    Divider(
                                      height: 1,
                                      color: Colors.grey[700],
                                    ),
                                    const SizedBox(height: 16),
                                    // Footer Buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.grey[400],
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                          ),
                                          child: const Text('Batal'),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red[300],
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                          ),
                                          child: const Text('Hapus'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );

                      if (confirmed == true) {
                        try {
                          final canDelete = await masterDataRepository
                              .canDeleteMasterData(data.id!);
                          if (!canDelete) {
                            throw Exception(
                                'Data digunakan pada transaksi atau bundle aktif');
                          }

                          await masterDataRepository
                              .softDeleteMasterData(data.id!);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Data berhasil dihapus')),
                            );
                          }
                          _showTable();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Gagal menghapus data: $e')),
                            );
                          }
                        }
                      }
                    },
                  )
                : MasterDataForm(
                    onCancel: _showTable,
                    initialData: _dataToEdit,
                    onSubmit: _handleDataFormSubmit,
                  ),
          ),
        ],
      ),
    );
  }
}
