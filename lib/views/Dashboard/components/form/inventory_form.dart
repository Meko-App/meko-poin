import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meko_poin/utils/validators.dart';

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
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? _selectedItem;
  String? _selectedError;
  String? _stockError;
  String? _notesError;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _stockController.text = widget.initialData!['stock']?.toString() ?? '';
      _notesController.text = widget.initialData!['notes'] ?? '';
      _selectedItem = widget.initialData!['item'] ?? 'Pilih Barang';
    } else {
      _selectedItem = 'Pilih Kategori';
    }
  }

  @override
  void dispose() {
    _stockController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveInventory() {
    // Validasi barang
    if (_selectedItem == 'Pilih Barang') {
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

    final Map<String, dynamic> inventoryData = {
      'item': _selectedItem,
      'stock': int.tryParse(_stockController.text),
      'notes': _notesController.text,
    };

    widget.onSubmit(inventoryData);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
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
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
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
                        color: Color(0xFF4B5675),
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
        color: Color(0xFF111B37),
      ),
    );
  }

  Widget _buildItemDropdown() {
    // Define your items list
    final List<String> items = [
      'Pilih Barang',
      'Produk A',
      'Produk B',
      'Produk C',
      'Produk D'
    ];

    // Ensure _selectedItem is either null or matches one of the items
    if (_selectedItem == null || !items.contains(_selectedItem)) {
      _selectedItem = 'Pilih Barang'; // Set default value
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: DropdownButtonFormField<String>(
            value: _selectedItem,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _selectedError != null
                      ? Colors.red
                      : Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color:
                      _selectedError != null ? Colors.red : Color(0xFF1379F0),
                  width: 1.0,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            dropdownColor: Colors.white,
            elevation: 2,
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            iconSize: 20,
            isExpanded: true,
            items: items.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF111B37),
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedItem = newValue;
                if (_selectedError != null && newValue != 'Pilih Barang') {
                  _selectedError = null;
                }
              });
            },
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF111B37),
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
                    color: Color(0xFF111B37),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Jumlah Stok',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF78829D),
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
                              : Colors.grey.shade300,
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
                    fillColor: Colors.white,
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
                            : Colors.grey.shade300,
                        width: 1.0),
                    right: BorderSide(
                        color: _stockError != null
                            ? Colors.red
                            : Colors.grey.shade300,
                        width: 1.0),
                    bottom: BorderSide(
                        color: _stockError != null
                            ? Colors.red
                            : Colors.grey.shade300,
                        width: 1.0),
                  ),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  color: Colors.grey.shade50,
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
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    // Divider
                    Container(
                      height: 1,
                      color: Colors.grey.shade300,
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
                          color: Colors.grey.shade600,
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
              color: Color(0xFF111B37),
            ),
            decoration: InputDecoration(
              hintText: 'Masukkan Catatan',
              hintStyle: TextStyle(
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                color: Color(0xFF78829D),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color:
                        _notesError != null ? Colors.red : Colors.grey.shade300,
                    width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: _notesError != null ? Colors.red : Color(0xFF1379F0),
                    width: 1.0),
              ),
              filled: true,
              fillColor: Colors.white,
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
