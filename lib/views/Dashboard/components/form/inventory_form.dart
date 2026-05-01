import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meko_poin/models/master_data.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/inventory_repository.dart';
import 'package:meko_poin/services/master_data_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class InventoryForm extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(Map<String, dynamic>) onSubmit;
  final Map<String, dynamic>? initialData;

  const InventoryForm({
    super.key,
    required this.onCancel,
    required this.onSubmit,
    this.initialData,
  });

  @override
  State<InventoryForm> createState() => _InventoryFormState();
}

class _InventoryFormState extends State<InventoryForm> {
  late final MasterDataRepository _masterDataRepository;
  late final InventoryRepository _inventoryRepository;
  List<int> _existingInventoryIds = [];

  Future<List<MasterData>> _fetchMasterData() async {
    return await _masterDataRepository.getAllMasterDataForSelect();
  }

  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  int? _selectedItem;
  String? _selectedError;
  String? _stockError;
  String? _notesError;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _stockController.text = widget.initialData!['stock']?.toString() ?? '';
      _notesController.text = widget.initialData!['notes'] ?? '';
      _selectedItem = widget.initialData!['master_data_id'] ?? '';
    } else {
      _selectedItem = null;
    }
    _masterDataRepository = MasterDataRepository(DatabaseHelper.instance);
    _inventoryRepository = InventoryRepository(DatabaseHelper.instance);
    _loadInventoryIds();
  }

  Future<void> _loadInventoryIds() async {
    final ids = await _inventoryRepository.getExistingInventoryIds();
    if (widget.initialData != null &&
        widget.initialData!['master_data_id'] != null) {
      ids.remove(widget.initialData!['master_data_id']);
    }
    setState(() {
      _existingInventoryIds = ids;
    });
  }

  @override
  void dispose() {
    _stockController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveInventory() async {
    // Validasi barang
    if (_selectedItem == null) {
      setState(() {
        _selectedError = 'Barang wajib dipilih';
      });
      return;
    }

    // Validasi stok
    if (_stockController.text.isEmpty) {
      setState(() {
        _stockError = 'Jumlah stok wajib diisi';
      });
      return;
    }

    final int stock = int.tryParse(_stockController.text) ?? 0;

    final Map<String, dynamic> inventoryData = {
      'master_data_id': _selectedItem,
      'stock': stock,
      'notes': _notesController.text,
    };

    widget.onSubmit(inventoryData);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        border: Border.all(color: CustomColors.borderCardColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown Pilih Barang
                  _buildFormLabel('Pilih Barang'),
                  const SizedBox(height: 8),
                  _buildItemDropdown(),
                  const SizedBox(height: 16),

                  // Input Stok
                  _buildFormLabel('Jumlah Stok'),
                  const SizedBox(height: 8),
                  _buildStockInput(),
                  const SizedBox(height: 16),

                  // Input Catatan
                  _buildFormLabel('Catatan (Opsional)'),
                  const SizedBox(height: 8),
                  _buildNotesInput(),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: CustomColors.cardColor,
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
                InkWell(
                  onTap: widget.onCancel,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                  onPressed: _saveInventory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1379F0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    widget.initialData != null ? 'Simpan' : 'Tambah',
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
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

  Widget _buildItemDropdown() {
    return FutureBuilder<List<MasterData>>(
      future: _fetchMasterData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Tampilkan loading indicator
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final masterDataList = snapshot.data ?? [];

        final availableItems = widget.initialData != null
            ? masterDataList.where((masterItem) =>
                !_existingInventoryIds.contains(masterItem.id) ||
                masterItem.id == _selectedItem)
            : masterDataList.where(
                (masterItem) => !_existingInventoryIds.contains(masterItem.id));

        final dropdownItems = availableItems
            .map((item) => DropdownMenuItem<int?>(
                  value: item.id,
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ))
            .toList();

        // Handle initial selection
        final validSelection =
            dropdownItems.any((item) => item.value == _selectedItem)
                ? _selectedItem
                : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 34,
              child: DropdownButtonFormField<int?>(
                value: validSelection,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _selectedError != null
                          ? Colors.red
                          : CustomColors.borderInputColor,
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _selectedError != null
                          ? Colors.red
                          : Color(0xFF1379F0),
                      width: 1.0,
                    ),
                  ),
                  filled: true,
                  fillColor: CustomColors.inputColor,
                ),
                hint: const Text(
                  'Pilih Barang',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: CustomColors.fontSubColor,
                  ),
                ),
                dropdownColor: CustomColors.inputColor,
                elevation: 2,
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: CustomColors.fontSubColor),
                iconSize: 20,
                isExpanded: true,
                items: dropdownItems,
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedItem = newValue;
                    if (_selectedError != null && newValue != null) {
                      _selectedError = null;
                    }
                  });
                },
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
            if (_selectedError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  _selectedError!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStockInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Jumlah Stok',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      color: CustomColors.fontSubColor,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 11, horizontal: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      borderSide: BorderSide(
                          color: _stockError != null
                              ? Colors.red
                              : CustomColors.borderInputColor,
                          width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      borderSide: BorderSide(
                          color: _stockError != null
                              ? Colors.red
                              : Color(0xFF1379F0),
                          width: 1.0),
                    ),
                    filled: true,
                    fillColor: CustomColors.inputColor,
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 34,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: _stockError != null
                            ? Colors.red
                            : CustomColors.borderInputColor,
                        width: 1.0),
                    right: BorderSide(
                        color: _stockError != null
                            ? Colors.red
                            : CustomColors.borderInputColor,
                        width: 1.0),
                    bottom: BorderSide(
                        color: _stockError != null
                            ? Colors.red
                            : CustomColors.borderInputColor,
                        width: 1.0),
                  ),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  color: CustomColors.inputColor,
                ),
                child: Column(
                  children: [
                    // Up button
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          int currentValue =
                              int.tryParse(_stockController.text) ?? 0;
                          setState(() {
                            _stockController.text =
                                (currentValue + 1).toString();
                          });
                        },
                        child: Icon(
                          Icons.keyboard_arrow_up,
                          size: 18,
                          color: CustomColors.fontSubColor,
                        ),
                      ),
                    ),
                    // Divider
                    Container(
                      height: 1,
                      color: CustomColors.borderInputColor,
                    ),
                    // Down button
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          int currentValue =
                              int.tryParse(_stockController.text) ?? 0;
                          if (currentValue > 0) {
                            setState(() {
                              _stockController.text =
                                  (currentValue - 1).toString();
                            });
                          }
                        },
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: CustomColors.fontSubColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_stockError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              _stockError!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 80,
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Masukkan Catatan',
              hintStyle: TextStyle(
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                color: CustomColors.fontSubColor,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: _notesError != null
                        ? Colors.red
                        : CustomColors.borderInputColor,
                    width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: _notesError != null ? Colors.red : Color(0xFF1379F0),
                    width: 1.0),
              ),
              filled: true,
              fillColor: CustomColors.inputColor,
            ),
          ),
        ),
        if (_notesError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              _notesError!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }
}

class DropdownItem {
  final int? id;
  final String name;

  DropdownItem({required this.id, required this.name});
}
