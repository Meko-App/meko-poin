import 'package:flutter/material.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:meko_poin/utils/validators.dart';

class MasterDataForm extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(Map<String, dynamic>) onSubmit;
  final Map<String, dynamic>? initialData;

  const MasterDataForm({
    super.key,
    required this.onCancel,
    required this.onSubmit,
    this.initialData,
  });

  @override
  State<MasterDataForm> createState() => _MasterDataFormState();
}

class _MasterDataFormState extends State<MasterDataForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _selectedCategory;

  String? _nameError;
  String? _priceError;
  String? _selectedError;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _nameController.text = widget.initialData!['name'] ?? '';
      final price = widget.initialData!['price'];
      if (price != null) {
        _priceController.text = _formatWithThousandSeparator(price);
      } else {
        _priceController.text = '';
      }
      _selectedCategory = widget.initialData!['category'] ?? '';
    } else {
      _selectedCategory = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    // Validasi name
    final nameError = Validators.validateName(_nameController.text);
    setState(() {
      _nameError = nameError;
    });

    // Validasi kategori
    if (_selectedCategory == null) {
      setState(() {
        _selectedError = 'Category wajib diisi';
      });
    }

    // Validasi harga
    final priceError =
        Validators.validatePrice(_priceController.text.replaceAll('.', ''));

    setState(() {
      _priceError = priceError;
    });

    if (nameError != null || priceError != null || _selectedCategory == null) {
      return;
    }

    final Map<String, dynamic> productData = {
      'name': _nameController.text,
      'category': _selectedCategory,
      'price': _priceController.text.isEmpty
          ? null
          : int.tryParse(_priceController.text.replaceAll('.', '')),
    };

    widget.onSubmit(productData);
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
                  // Input Nama
                  _buildFormLabel('Nama'),
                  const SizedBox(height: 8),
                  _buildTextField(_nameController, 'Masukkan Nama',
                      errorText: _nameError),
                  const SizedBox(height: 16),

                  // Dropdown Kategori
                  _buildFormLabel('Kategori'),
                  const SizedBox(height: 8),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),

                  // Input Harga
                  _buildFormLabel('Harga'),
                  const SizedBox(height: 8),
                  _buildPriceInput(),
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
                  onPressed: _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1379F0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    widget.initialData != null ? 'Simpan' : 'Buat Baru',
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

  Widget _buildTextField(TextEditingController controller, String hintText,
      {bool obscureText = false, bool enabled = true, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            enabled: enabled,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: hintText,
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
                    color: errorText != null
                        ? Colors.red
                        : CustomColors.borderInputColor,
                    width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: errorText != null ? Colors.red : Color(0xFF1379F0),
                    width: 1.0),
              ),
              filled: true,
              fillColor: enabled
                  ? CustomColors.inputColor
                  : CustomColors.borderInputColor,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              errorText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: _selectedError != null
                        ? Colors.red
                        : CustomColors.borderInputColor,
                    width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color:
                        _selectedError != null ? Colors.red : Color(0xFF1379F0),
                    width: 1.0),
              ),
              filled: true,
              fillColor: CustomColors.inputColor,
            ),
            hint: const Text(
              'Pilih kategori',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: CustomColors.fontSubColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            dropdownColor: CustomColors.inputColor,
            elevation: 2,
            icon: const Icon(Icons.keyboard_arrow_down,
                color: CustomColors.fontSubColor),
            iconSize: 20,
            isExpanded: true,
            items: <String>[
              'Product',
              'Paper',
              'Packaging',
              'Additional',
              'Background'
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedCategory = newValue;
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
  }

  Widget _buildPriceInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 34, // Tinggi eksplisit untuk seluruh kotak input
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _priceError != null
                  ? Colors.red
                  : CustomColors.borderInputColor,
              width: 1.0,
            ),
            color: CustomColors.inputColor,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF0A1726),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(7),
                    bottomLeft: Radius.circular(7),
                  ),
                ),
                child: const Text(
                  'Rp',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1379F0), // Warna biru untuk "Rp"
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan Harga',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      color: CustomColors.fontSubColor,
                    ),
                    contentPadding: EdgeInsets.only(left: 12),
                    isDense: true,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                  onChanged: (value) {
                    String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

                    if (digitsOnly.isEmpty) {
                      _priceController.text = '';
                      _priceController.selection =
                          TextSelection.collapsed(offset: 0);
                      return;
                    }

                    final number = int.parse(digitsOnly);
                    final formatted = _formatWithThousandSeparator(number);

                    _priceController.value = TextEditingValue(
                      text: formatted,
                      selection:
                          TextSelection.collapsed(offset: formatted.length),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (_priceError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              _priceError!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
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
