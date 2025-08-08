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
              'master_data_id': data.masterDataId,
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
            stock: data['stock'],
            notes: (data['notes'] == null || data['notes'].toString().isEmpty)
                ? '-'
                : data['notes'],
            userId: userId,
            masterDataId: data['master_data_id']);
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
            stock: data['stock'],
            notes: (data['notes'] == null || data['notes'].toString().isEmpty)
                ? '-'
                : data['notes'],
            userId: _dataToEdit!['id_user'],
            masterDataId: data['master_data_id']);
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
                        builder: (context) => AlertDialog(
                          title: const Text('Konfirmasi'),
                          content: Text('Hapus Data ini?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Hapus'),
                            ),
                          ],
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
