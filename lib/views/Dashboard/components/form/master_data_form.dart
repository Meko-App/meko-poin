import 'package:flutter/material.dart';
import 'package:meko_poin/models/category.dart';
import 'package:meko_poin/models/master_data.dart';
import 'package:meko_poin/services/bundle_repository.dart';
import 'package:meko_poin/services/category_repository.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/master_data_repository.dart';
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
  final CategoryRepository _categoryRepository =
      CategoryRepository(DatabaseHelper.instance);
    final MasterDataRepository _masterDataRepository =
      MasterDataRepository(DatabaseHelper.instance);
    final BundleRepository _bundleRepository =
      BundleRepository(DatabaseHelper.instance);
  List<Category> _categories = [];
    List<MasterData> _productItems = [];
    List<MasterData> _paperItems = [];
    List<MasterData> _packagingItems = [];
  bool _isLoadingCategories = true;
    bool _isLoadingBundleData = false;
  int? _selectedCategoryId;
    int? _selectedBundleProductId;
    int? _selectedBundlePaperId;
    int? _selectedBundlePackagingId;
    bool _isManualPriceOverride = false;

  String? _nameError;
  String? _priceError;
  String? _selectedError;
    String? _bundleProductError;

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
      _selectedCategoryId = widget.initialData!['category_id'] as int?;
    } else {
      _selectedCategoryId = null;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryRepository.getAllCategories();
      final productItems =
          await _masterDataRepository.getMasterDataByCategoryCode('product');
      final paperItems =
          await _masterDataRepository.getMasterDataByCategoryCode('paper');
      final packagingItems =
          await _masterDataRepository.getMasterDataByCategoryCode('packaging');

      if (mounted) {
        setState(() {
          _categories = categories;
          _productItems = productItems;
          _paperItems = paperItems;
          _packagingItems = packagingItems;
        });

        await _loadInitialBundleComponents();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  bool _isSelectedCategoryBundle() {
    if (_selectedCategoryId == null) {
      return false;
    }

    for (final category in _categories) {
      if (category.id == _selectedCategoryId) {
        return category.isBundle;
      }
    }

    return false;
  }

  Future<void> _loadInitialBundleComponents() async {
    if (widget.initialData == null) {
      return;
    }

    if (!_isSelectedCategoryBundle()) {
      return;
    }

    final id = widget.initialData!['id'] as int?;
    if (id == null) {
      return;
    }

    setState(() {
      _isLoadingBundleData = true;
    });

    final items = await _bundleRepository.getBundleItems(id);

    for (final item in items) {
      switch (item.componentType.toLowerCase()) {
        case 'product':
          _selectedBundleProductId = item.componentMasterDataId;
          break;
        case 'paper':
          _selectedBundlePaperId = item.componentMasterDataId;
          break;
        case 'packaging':
          _selectedBundlePackagingId = item.componentMasterDataId;
          break;
      }
    }

    _autoCalculateBundlePrice();

    if (mounted) {
      setState(() {
        _isLoadingBundleData = false;
      });
    }
  }

  MasterData? _findMasterDataById(List<MasterData> items, int? id) {
    if (id == null) {
      return null;
    }

    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  String _selectedMasterDataName(List<MasterData> items, int? id) {
    final selected = _findMasterDataById(items, id);
    return selected?.name ?? '';
  }

  Future<int?> _openMasterDataSearchDialog({
    required String title,
    required List<MasterData> items,
    required int? selectedId,
  }) async {
    if (items.isEmpty) {
      return null;
    }

    int? localSelectedId = selectedId;
    String query = '';

    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final normalizedQuery = query.trim().toLowerCase();
            final filtered = items.where((item) {
              if (normalizedQuery.isEmpty) {
                return true;
              }

              return item.name.toLowerCase().contains(normalizedQuery);
            }).toList();

            return Dialog(
              backgroundColor: CustomColors.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: CustomColors.borderCardColor),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460, maxHeight: 520),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 36,
                        child: TextField(
                          onChanged: (value) {
                            setDialogState(() {
                              query = value;
                            });
                          },
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Cari item...',
                            hintStyle: const TextStyle(
                              color: CustomColors.fontSubColor,
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: const Icon(Icons.search,
                                size: 18, color: CustomColors.fontSubColor),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            filled: true,
                            fillColor: CustomColors.inputColor,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: CustomColors.borderInputColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1379F0)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: CustomColors.inputColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: CustomColors.borderInputColor,
                            ),
                          ),
                          child: filtered.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Item tidak ditemukan',
                                    style: TextStyle(
                                      color: CustomColors.fontSubColor,
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 1,
                                    color: CustomColors.borderCardColor,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = filtered[index];
                                    final active = localSelectedId == item.id;
                                    return InkWell(
                                      onTap: () {
                                        setDialogState(() {
                                          localSelectedId = item.id;
                                        });
                                      },
                                      child: Container(
                                        color: active
                                            ? const Color(0xFF0A1726)
                                            : Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Inter',
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                            if (active)
                                              const Icon(Icons.check,
                                                  size: 16,
                                                  color: Color(0xFF1379F0)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: localSelectedId == null
                                ? null
                                : () => Navigator.of(dialogContext)
                                    .pop(localSelectedId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1379F0),
                            ),
                            child: const Text(
                              'Pilih',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _autoCalculateBundlePrice() {
    if (_isManualPriceOverride) {
      return;
    }

    final product = _findMasterDataById(_productItems, _selectedBundleProductId);
    final paper = _findMasterDataById(_paperItems, _selectedBundlePaperId);

    final productPrice = product?.price ?? 0;
    final paperPrice = paper?.price ?? 0;
    final total = productPrice + paperPrice;

    _priceController.text = _formatWithThousandSeparator(total);
  }

  String _selectedCategoryName() {
    if (_selectedCategoryId == null) {
      return '';
    }

    for (final category in _categories) {
      if (category.id == _selectedCategoryId) {
        return category.name;
      }
    }

    return '';
  }

  Future<void> _openCategorySearchDialog() async {
    if (_categories.isEmpty) {
      return;
    }

    int? selectedId = _selectedCategoryId;
    String query = '';

    final pickedId = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final normalizedQuery = query.trim().toLowerCase();
            final filtered = _categories.where((category) {
              if (normalizedQuery.isEmpty) {
                return true;
              }
              return category.name.toLowerCase().contains(normalizedQuery) ||
                  category.code.toLowerCase().contains(normalizedQuery);
            }).toList();

            return Dialog(
              backgroundColor: CustomColors.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: CustomColors.borderCardColor),
              ),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 460, maxHeight: 520),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Kategori',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 36,
                        child: TextField(
                          onChanged: (value) {
                            setDialogState(() {
                              query = value;
                            });
                          },
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Cari kategori atau kode...',
                            hintStyle: const TextStyle(
                              color: CustomColors.fontSubColor,
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: const Icon(Icons.search,
                                size: 18, color: CustomColors.fontSubColor),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            filled: true,
                            fillColor: CustomColors.inputColor,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: CustomColors.borderInputColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1379F0)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: CustomColors.inputColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: CustomColors.borderInputColor,
                            ),
                          ),
                          child: filtered.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Kategori tidak ditemukan',
                                    style: TextStyle(
                                      color: CustomColors.fontSubColor,
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 1,
                                    color: CustomColors.borderCardColor,
                                  ),
                                  itemBuilder: (context, index) {
                                    final category = filtered[index];
                                    final active = selectedId == category.id;
                                    return InkWell(
                                      onTap: () {
                                        setDialogState(() {
                                          selectedId = category.id;
                                        });
                                      },
                                      child: Container(
                                        color: active
                                            ? const Color(0xFF0A1726)
                                            : Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                category.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Inter',
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                            if (active)
                                              const Icon(Icons.check,
                                                  size: 16,
                                                  color: Color(0xFF1379F0)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: selectedId == null
                                ? null
                                : () =>
                                    Navigator.of(dialogContext).pop(selectedId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1379F0),
                            ),
                            child: const Text(
                              'Pilih',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (pickedId != null && mounted) {
      setState(() {
        _selectedCategoryId = pickedId;
        _selectedError = null;

        if (!_isSelectedCategoryBundle()) {
          _selectedBundleProductId = null;
          _selectedBundlePaperId = null;
          _selectedBundlePackagingId = null;
          _bundleProductError = null;
          _isManualPriceOverride = false;
        } else {
          _autoCalculateBundlePrice();
        }
      });
    }
  }

  void _saveProduct() {
    // Validasi name
    final nameError = Validators.validateName(_nameController.text);
    setState(() {
      _nameError = nameError;
    });

    // Validasi kategori
    if (_selectedCategoryId == null) {
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

    if (nameError != null ||
        priceError != null ||
        _selectedCategoryId == null) {
      return;
    }

    if (_isSelectedCategoryBundle() && _selectedBundleProductId == null) {
      setState(() {
        _bundleProductError = 'Produk wajib dipilih untuk bundle';
      });
      return;
    }

    final selectedCategory =
        _categories.where((category) => category.id == _selectedCategoryId);
    if (selectedCategory.isEmpty) {
      setState(() {
        _selectedError = 'Kategori tidak ditemukan';
      });
      return;
    }

    final bundleItems = <Map<String, dynamic>>[];
    if (_isSelectedCategoryBundle()) {
      if (_selectedBundleProductId != null) {
        bundleItems.add(
          {
            'component_master_data_id': _selectedBundleProductId,
            'component_type': 'product',
            'qty': 1,
          },
        );
      }
      if (_selectedBundlePaperId != null) {
        bundleItems.add(
          {
            'component_master_data_id': _selectedBundlePaperId,
            'component_type': 'paper',
            'qty': 1,
          },
        );
      }
      if (_selectedBundlePackagingId != null) {
        bundleItems.add(
          {
            'component_master_data_id': _selectedBundlePackagingId,
            'component_type': 'packaging',
            'qty': 1,
          },
        );
      }
    }

    final Map<String, dynamic> productData = {
      'name': _nameController.text,
      'category_id': _selectedCategoryId,
      'category_name': selectedCategory.first.name,
      'price': _priceController.text.isEmpty
          ? null
          : int.tryParse(_priceController.text.replaceAll('.', '')),
      'bundle_items': bundleItems,
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

                  if (_isSelectedCategoryBundle()) ...[
                    const SizedBox(height: 16),
                    _buildFormLabel('Komponen Bundle'),
                    const SizedBox(height: 8),
                    if (_isLoadingBundleData)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      _buildBundleComponentSection(),
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
    if (_isLoadingCategories) {
      return const SizedBox(
        height: 34,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _openCategorySearchDialog,
              child: Ink(
                decoration: BoxDecoration(
                  color: CustomColors.inputColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedError != null
                        ? Colors.red
                        : CustomColors.borderInputColor,
                    width: 1.0,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedCategoryName().isEmpty
                              ? 'Pilih kategori (bisa dicari)'
                              : _selectedCategoryName(),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: _selectedCategoryName().isEmpty
                                ? CustomColors.fontSubColor
                                : Colors.white,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.search,
                        size: 18,
                        color: CustomColors.fontSubColor,
                      ),
                    ],
                  ),
                ),
              ),
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
                    if (_isSelectedCategoryBundle()) {
                      _isManualPriceOverride = true;
                    }

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

  Widget _buildBundleComponentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMasterDataPicker(
          label: 'Produk (wajib)',
          value: _selectedMasterDataName(_productItems, _selectedBundleProductId),
          errorText: _bundleProductError,
          onTap: () async {
            final pickedId = await _openMasterDataSearchDialog(
              title: 'Pilih Produk',
              items: _productItems,
              selectedId: _selectedBundleProductId,
            );

            if (pickedId != null && mounted) {
              setState(() {
                _selectedBundleProductId = pickedId;
                _bundleProductError = null;
              });
              _autoCalculateBundlePrice();
            }
          },
        ),
        const SizedBox(height: 8),
        _buildMasterDataPicker(
          label: 'Paper (opsional)',
          value: _selectedMasterDataName(_paperItems, _selectedBundlePaperId),
          onTap: () async {
            final pickedId = await _openMasterDataSearchDialog(
              title: 'Pilih Paper',
              items: _paperItems,
              selectedId: _selectedBundlePaperId,
            );

            if (mounted) {
              setState(() {
                _selectedBundlePaperId = pickedId;
              });
              _autoCalculateBundlePrice();
            }
          },
          onClear: _selectedBundlePaperId == null
              ? null
              : () {
                  setState(() {
                    _selectedBundlePaperId = null;
                  });
                  _autoCalculateBundlePrice();
                },
        ),
        const SizedBox(height: 8),
        _buildMasterDataPicker(
          label: 'Packaging (opsional)',
          value: _selectedMasterDataName(
              _packagingItems, _selectedBundlePackagingId),
          onTap: () async {
            final pickedId = await _openMasterDataSearchDialog(
              title: 'Pilih Packaging',
              items: _packagingItems,
              selectedId: _selectedBundlePackagingId,
            );

            if (mounted) {
              setState(() {
                _selectedBundlePackagingId = pickedId;
              });
            }
          },
          onClear: _selectedBundlePackagingId == null
              ? null
              : () {
                  setState(() {
                    _selectedBundlePackagingId = null;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildMasterDataPicker({
    required String label,
    required String value,
    required VoidCallback onTap,
    VoidCallback? onClear,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CustomColors.fontSubColor,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 34,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              child: Ink(
                decoration: BoxDecoration(
                  color: CustomColors.inputColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: errorText != null
                        ? Colors.red
                        : CustomColors.borderInputColor,
                    width: 1.0,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          value.isEmpty ? 'Pilih item' : value,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: value.isEmpty
                                ? CustomColors.fontSubColor
                                : Colors.white,
                          ),
                        ),
                      ),
                      if (onClear != null)
                        InkWell(
                          onTap: onClear,
                          child: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.clear,
                              size: 16,
                              color: CustomColors.fontSubColor,
                            ),
                          ),
                        ),
                      const Icon(
                        Icons.search,
                        size: 18,
                        color: CustomColors.fontSubColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              errorText,
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
