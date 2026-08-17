import 'package:flutter/material.dart';
import 'package:meko_poin/models/keuangan_kategori.dart';
import 'package:meko_poin/services/kas_repository.dart';
import 'package:meko_poin/services/keuangan_kategori_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:meko_poin/utils/validators.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KasForm extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(Map<String, dynamic>) onSubmit;
  final Map<String, dynamic>? initialData;
  final int? user;
  final KasRepository kasRepository;
  final KeuanganKategoriRepository kategoriRepository;

  const KasForm({
    super.key,
    required this.onCancel,
    required this.onSubmit,
    required this.kasRepository,
    required this.kategoriRepository,
    this.initialData,
    this.user,
  });

  @override
  State<KasForm> createState() => _KasFormState();
}

class _KasFormState extends State<KasForm> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String? _selectedType;
  String? _selectedFrom;
  String? _selectedTo;
  int? _selectedCategoryId;
  DateTime? _selectedDate;
  List<KeuanganKategori> _categories = [];
  List<String> _descriptionSuggestions = [];

  String? _amountError;
  String? _descriptionError;
  String? _typeError;
  String? _dateError;
  String? _fromToError;
  String? _transferBalanceError;

  bool get _isOperator => widget.user == 2;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.initialData != null) {
      _amountController.text =
          _formatWithThousandSeparator(widget.initialData!['amount'] ?? '');
      _descriptionController.text = widget.initialData!['description'] ?? '';
      _selectedType = widget.initialData!['type'] ?? '';
      _selectedCategoryId = widget.initialData!['category_id'];

      if (widget.initialData!['cash_date'] != null) {
        _selectedDate = DateTime.parse(widget.initialData!['cash_date']);
        _dateController.text = _formatDate(_selectedDate!);
      }

      // Form edit tidak pernah untuk transfer (transfer dua baris tidak diedit).
      if (_selectedType == 'transfer') {
        _selectedType = 'income';
      }
    } else {
      _selectedDate = DateTime.now();
      _dateController.text = _formatDate(_selectedDate!);
      if (_isOperator) {
        // Operator hanya bisa transfer dari tunai (Cash) ke saldo.
        _selectedType = 'transfer';
        _selectedFrom = 'cash';
        _selectedTo = 'saldo';
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories =
          await widget.kategoriRepository.getAllKeuanganKategori();
      setState(() => _categories = categories);
    } catch (e) {
      debugPrint('Error loading keuangan kategori: $e');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.dark(
              primary: Color(
                  0xFF1379F0), // Sesuai dengan warna biru di focusedBorder
              onPrimary: Colors.white,
              surface: Color(0xFF2D2D2D), // Warna background gelap
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Color(0xFF2D2D2D),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF1379F0),
              ),
            ),
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white),
            ),
            dividerColor: Colors.grey[700],
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
        _dateError = null;
      });
    }
  }

  Future<void> _onDescriptionChanged(String value) async {
    if (value.trim().isEmpty) {
      setState(() => _descriptionSuggestions = []);
      return;
    }
    final suggestions =
        await widget.kasRepository.getKasDescriptionSuggestions(value);
    if (mounted && _descriptionController.text == value) {
      setState(() => _descriptionSuggestions = suggestions);
    }
  }

  Future<void> _addNewCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: CustomColors.cardColor,
        title: const Text('Tambah Kategori Keuangan',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nama kategori',
            hintStyle: const TextStyle(color: CustomColors.fontSubColor),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: CustomColors.borderInputColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF1379F0)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal',
                style: TextStyle(color: CustomColors.fontSubColor)),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1379F0),
            ),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && mounted) {
      final id = await widget.kategoriRepository.insertKeuanganKategori(name);
      await _loadCategories();
      if (mounted) {
        setState(() => _selectedCategoryId = id);
      }
    }
  }

  void _saveKas() async {
    // Validasi amount
    final amountError =
        Validators.validatePrice(_amountController.text.replaceAll('.', ''));
    setState(() {
      _amountError = amountError;
    });

    // Validasi description
    final descriptionError =
        Validators.validateRequired(_descriptionController.text, 'Keterangan');
    setState(() {
      _descriptionError = descriptionError;
    });

    // Validasi type
    if (_selectedType == null) {
      setState(() {
        _typeError = 'Jenis transaksi wajib dipilih';
      });
    } else {
      setState(() {
        _typeError = null;
      });
    }

    // Validasi date
    if (_selectedDate == null) {
      setState(() {
        _dateError = 'Tanggal wajib diisi';
      });
    } else {
      setState(() {
        _dateError = null;
      });
    }

    // Validasi dari/ke untuk transfer
    String? transferError;
    if (_selectedType == 'transfer') {
      if (_selectedFrom == null || _selectedTo == null) {
        transferError = 'Dari dan Ke wajib dipilih';
      } else if (_selectedFrom == _selectedTo) {
        transferError = 'Dari dan Ke tidak boleh sama';
      }
    }
    setState(() => _fromToError = transferError);

    // Validasi saldo variabel asal untuk transfer
    String? transferBalanceError;
    if (_selectedType == 'transfer' &&
        _selectedFrom != null &&
        amountError == null) {
      final amount =
          int.parse(_amountController.text.replaceAll('.', ''));
      final available = _selectedFrom == 'cash'
          ? await widget.kasRepository.getTotalCash()
          : await widget.kasRepository.getTotalSaldoVariable();
      if (available < amount) {
        transferBalanceError =
            'Saldo ${_selectedFrom == 'cash' ? 'Cash' : 'Saldo'} tidak mencukupi';
      }
    }
    setState(() => _transferBalanceError = transferBalanceError);

    if (amountError != null ||
        descriptionError != null ||
        _selectedType == null ||
        _selectedDate == null ||
        transferError != null ||
        transferBalanceError != null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;

    final Map<String, dynamic> kasData = {
      'amount': int.parse(_amountController.text.replaceAll('.', '')),
      'description': _descriptionController.text,
      'type': _selectedType,
      'cash_date': _selectedDate!.toIso8601String().split('T')[0],
      'category_id': _selectedCategoryId,
      'created_by': userId,
      if (_selectedType == 'transfer') 'from_variable': _selectedFrom,
      if (_selectedType == 'transfer') 'to_variable': _selectedTo,
    };

    widget.onSubmit(kasData);
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
                  // Dropdown Jenis Transaksi
                  _buildFormLabel('Jenis Transaksi'),
                  const SizedBox(height: 8),
                  _buildTypeDropdown(),
                  const SizedBox(height: 16),

                  if (_selectedType == 'transfer') ...[
                    // Dropdown Dari
                    _buildFormLabel('Dari'),
                    const SizedBox(height: 8),
                    _buildFromDropdown(),
                    const SizedBox(height: 16),

                    // Dropdown Ke
                    _buildFormLabel('Ke'),
                    const SizedBox(height: 8),
                    _buildToDropdown(),
                    if (_fromToError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          _fromToError!,
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    if (_transferBalanceError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          _transferBalanceError!,
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],

                  // Input Tanggal
                  _buildFormLabel('Tanggal'),
                  const SizedBox(height: 8),
                  _buildDateInput(context),
                  const SizedBox(height: 16),

                  // Input Nominal
                  _buildFormLabel('Nominal'),
                  const SizedBox(height: 8),
                  _buildAmountInput(),
                  const SizedBox(height: 16),

                  // Input Keterangan
                  _buildFormLabel('Keterangan'),
                  const SizedBox(height: 8),
                  _buildDescriptionInput(),

                  if (_selectedType != 'transfer') ...[
                    const SizedBox(height: 16),
                    // Kategori Keuangan (Optional)
                    _buildFormLabel('Kategori Keuangan (Opsional)'),
                    const SizedBox(height: 8),
                    _buildCategoryDropdown(),
                  ],
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
                  onPressed: _saveKas,
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

  Widget _buildTypeDropdown() {
    final List<String> options = _isOperator
        ? ['transfer']
        : ['income', 'outcome', 'transfer'];
    final Map<String, String> labels = {
      'income': 'Pemasukan',
      'outcome': 'Pengeluaran',
      'transfer': 'Transfer',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: _typeError != null
                        ? Colors.red
                        : CustomColors.borderInputColor,
                    width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: _typeError != null ? Colors.red : Color(0xFF1379F0),
                    width: 1.0),
              ),
              filled: true,
              fillColor: CustomColors.inputColor,
            ),
            hint: const Text(
              'Pilih jenis transaksi',
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
            items: options
                .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      labels[value] ?? value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  );
                })
                .toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedType = newValue;
                _typeError = null;
                _fromToError = null;
                _transferBalanceError = null;
                if (newValue == 'transfer') {
                  if (_isOperator) {
                    _selectedFrom = 'cash';
                    _selectedTo = 'saldo';
                  } else {
                    _selectedFrom = null;
                    _selectedTo = null;
                  }
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
        if (_typeError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              _typeError!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFromDropdown() {
    final List<String> options = ['cash', 'saldo'];
    final Map<String, String> labels = {'cash': 'Cash', 'saldo': 'Saldo'};

    return SizedBox(
      height: 34,
      child: DropdownButtonFormField<String>(
        value: _selectedFrom,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color: _fromToError != null
                    ? Colors.red
                    : CustomColors.borderInputColor,
                width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color:
                    _fromToError != null ? Colors.red : Color(0xFF1379F0),
                width: 1.0),
          ),
          filled: true,
          fillColor: CustomColors.inputColor,
        ),
        hint: const Text(
          'Pilih variabel asal',
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
        items: options.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              labels[value] ?? value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          );
        }).toList(),
        onChanged: _isOperator
            ? null
            : (String? newValue) {
                setState(() {
                  _selectedFrom = newValue;
                  _selectedTo =
                      newValue == 'cash' ? 'saldo' : 'cash';
                  _fromToError = null;
                  _transferBalanceError = null;
                });
              },
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildToDropdown() {
    // Aturan dependensi: Ke = kebalikan dari Dari.
    final List<String> options =
        _selectedFrom == null ? <String>[] : [_selectedFrom == 'cash' ? 'saldo' : 'cash'];
    final Map<String, String> labels = {'cash': 'Cash', 'saldo': 'Saldo'};

    return SizedBox(
      height: 34,
      child: DropdownButtonFormField<String>(
        value: _selectedTo,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color: _fromToError != null
                    ? Colors.red
                    : CustomColors.borderInputColor,
                width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color:
                    _fromToError != null ? Colors.red : Color(0xFF1379F0),
                width: 1.0),
          ),
          filled: true,
          fillColor: CustomColors.inputColor,
        ),
        hint: const Text(
          'Pilih variabel tujuan',
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
        items: options.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              labels[value] ?? value,
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
            _selectedTo = newValue;
            _fromToError = null;
            _transferBalanceError = null;
          });
        },
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int?>(
              value: _selectedCategoryId,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: CustomColors.borderInputColor, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: Color(0xFF1379F0), width: 1.0),
                ),
                filled: true,
                fillColor: CustomColors.inputColor,
              ),
              hint: const Text(
                'Pilih kategori (opsional)',
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
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    'Tanpa Kategori',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: CustomColors.fontSubColor,
                    ),
                  ),
                ),
                ..._categories.map<DropdownMenuItem<int?>>((cat) {
                  return DropdownMenuItem<int?>(
                    value: cat.id,
                    child: Text(
                      cat.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  );
                }).toList(),
              ],
              onChanged: (newValue) {
                setState(() => _selectedCategoryId = newValue);
              },
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _addNewCategory,
            icon: const Icon(Icons.add_circle_outline,
                size: 20, color: Color(0xFF1379F0)),
            tooltip: 'Tambah kategori baru',
          ),
        ],
      ),
    );
  }

  Widget _buildDateInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: TextField(
            controller: _dateController,
            readOnly: true,
            onTap: () => _selectDate(context),
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Pilih tanggal',
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
                    color: _dateError != null
                        ? Colors.red
                        : CustomColors.borderInputColor,
                    width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: _dateError != null ? Colors.red : Color(0xFF1379F0),
                    width: 1.0),
              ),
              filled: true,
              fillColor: CustomColors.inputColor,
              suffixIcon: Icon(
                Icons.calendar_today,
                size: 18,
                color: CustomColors.fontSubColor,
              ),
            ),
          ),
        ),
        if (_dateError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              _dateError!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _amountError != null
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
                    color: Color(0xFF1379F0),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Masukkan Nominal',
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
                      _amountController.text = '';
                      _amountController.selection =
                          TextSelection.collapsed(offset: 0);
                      return;
                    }

                    final number = int.parse(digitsOnly);
                    final formatted = _formatWithThousandSeparator(number);

                    _amountController.value = TextEditingValue(
                      text: formatted,
                      selection:
                          TextSelection.collapsed(offset: formatted.length),
                    );

                    setState(() {
                      _amountError = null;
                      _transferBalanceError = null;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        if (_amountError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              _amountError!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDescriptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 80,
          child: TextField(
            controller: _descriptionController,
            maxLines: 3,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Masukkan Keterangan',
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
                    color: _descriptionError != null
                        ? Colors.red
                        : CustomColors.borderInputColor,
                    width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: _descriptionError != null
                        ? Colors.red
                        : Color(0xFF1379F0),
                    width: 1.0),
              ),
              filled: true,
              fillColor: CustomColors.inputColor,
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  _descriptionError = null;
                });
              }
              _onDescriptionChanged(value);
            },
          ),
        ),
        if (_descriptionSuggestions.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: CustomColors.inputColor,
              border: Border.all(color: CustomColors.borderCardColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _descriptionSuggestions
                  .take(5)
                  .map((suggestion) => InkWell(
                        onTap: () {
                          setState(() {
                            _descriptionController.text = suggestion;
                            _descriptionSuggestions = [];
                            _descriptionError = null;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              suggestion,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        if (_descriptionError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              _descriptionError!,
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
