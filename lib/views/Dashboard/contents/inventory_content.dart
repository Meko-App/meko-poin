import 'package:flutter/material.dart';
import 'package:meko_poin/services/inventory_log_repository.dart';
import 'package:meko_poin/services/inventory_repository.dart';
import 'package:meko_poin/views/Dashboard/components/form/inventory_form.dart';
import 'package:meko_poin/views/Dashboard/components/table/inventory_log_table/inventory_log_table.dart';
import 'package:meko_poin/views/Dashboard/components/table/inventory_table/inventory_table.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/content_state.dart';
// import 'package:meko_poin/views/Dashboard/components/form/master_data_form.dart';
import 'package:meko_poin/models/inventory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class InventoryContent extends StatefulWidget {
  final Function(ContentState) onStateChanged;
  final InventoryRepository inventoryRepository;
  final InventoryLogRepository inventoryLogRepository;

  const InventoryContent(
      {super.key,
      required this.onStateChanged,
      required this.inventoryRepository,
      required this.inventoryLogRepository});

  @override
  State<InventoryContent> createState() => _InventoryContentState();
}

class _InventoryContentState extends State<InventoryContent> {
  ContentState _currentState = ContentState.table;
  Map<String, dynamic>? _dataToEdit;
  late final InventoryRepository inventoryRepository;
  late final InventoryLogRepository inventoryLogRepository;
  int? _selectedInventoryIdForLog;

  @override
  void initState() {
    super.initState();
    inventoryRepository = widget.inventoryRepository;
    inventoryLogRepository = widget.inventoryLogRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStateChanged(_currentState);
    });
  }

  void _showForm({Inventory? data}) {
    setState(() {
      _currentState = ContentState.form;
      _dataToEdit = data != null
          ? {
              'id': data.id,
              'id_user': data.userId,
              'name': data.name,
              'category_id': data.categoryId,
              'stock_reject': data.stockReject,
              'stock': data.stock,
              'notes': data.notes,
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

  void _showLog(int inventoryId) {
    setState(() {
      _currentState = ContentState.log;
      _selectedInventoryIdForLog = inventoryId;
      widget.onStateChanged(_currentState);
    });
  }

  Future<void> _handleDataFormSubmit(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    try {
      if (_dataToEdit == null) {
        final newData = Inventory(
            id: null,
            name: (data['name'] ?? '').toString().trim(),
            categoryId: data['category_id'] as int?,
            stock: data['stock'],
            notes: '-',
            userId: userId);
        await inventoryRepository.insertInventory(newData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data baru berhasil ditambahkan')),
          );
        }
      } else {
        // Edit existing data
        final updatedData = Inventory(
            id: _dataToEdit!['id'],
            name: (data['name'] ?? '').toString().trim(),
            categoryId: data['category_id'] as int?,
            stock: data['stock'],
            notes: (_dataToEdit!['notes'] == null ||
                    _dataToEdit!['notes'].toString().isEmpty)
                ? '-'
                : _dataToEdit!['notes'],
            userId: _dataToEdit!['id_user'],
            masterDataId: _dataToEdit!['master_data_id'] as int?);
        await inventoryRepository.updateInventory(updatedData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil diperbarui')),
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
    double currentMaxHeight = _currentState == ContentState.form
        ? double.infinity
        : MediaQuery.of(context).size.height * 0.77;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_currentState == ContentState.form ||
                  _currentState == ContentState.log)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _showTable,
                  color: Colors.grey.shade700,
                ),
              if (_currentState == ContentState.form ||
                  _currentState == ContentState.log)
                const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentState == ContentState.table
                        ? "Inventori"
                        : (_currentState == ContentState.form
                            ? (_dataToEdit != null
                                ? "Edit Data Inventori"
                                : "Tambah Data Inventori")
                            : "Log Aktivitas"),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentState == ContentState.table
                        ? "Data master untuk inventory dan produk"
                        : (_currentState == ContentState.form
                            ? "Form untuk menambah atau mengedit data inventori"
                            : "Aktivitas perubahan stok barang"),
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
                ? InventoryTable(
                    onAddNew: _showForm,
                    inventoryRepository: inventoryRepository,
                    onEditInventory: (data) => _showForm(data: data),
                    onDeleteInventory: (data) async {
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
                                      'Hapus Data inventory ini?',
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
                          // await inventoryRepository.deleteInventory(data.id!);
                          await inventoryRepository
                              .softDeleteInventory(data.id!);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Data Inventory berhasil dihapus')),
                            );
                          }
                          _showTable();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Gagal menghapus Data Inventory: $e')),
                            );
                          }
                        }
                      }
                    },
                    onViewLog: _showLog,
                  )
                : (_currentState == ContentState.form
                    ? InventoryForm(
                        onCancel: _showTable,
                        initialData: _dataToEdit,
                        onSubmit: _handleDataFormSubmit,
                      )
                    : InventoryLogTable(
                        inventoryId: _selectedInventoryIdForLog!,
                        inventoryLogRepository: inventoryLogRepository,
                      )),
          ),
        ],
      ),
    );
  }
}
