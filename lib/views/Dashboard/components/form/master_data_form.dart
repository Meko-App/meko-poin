import 'package:flutter/material.dart';
import 'package:meko_poin/models/category.dart';
import 'package:meko_poin/services/bundle_repository.dart';
import 'package:meko_poin/services/category_repository.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/inventory_repository.dart';
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
  final FocusNode _nameFocusNode = FocusNode();
  final CategoryRepository _categoryRepository =
      CategoryRepository(DatabaseHelper.instance);
  final BundleRepository _bundleRepository =
      BundleRepository(DatabaseHelper.instance);
  final InventoryRepository _inventoryRepository =
      InventoryRepository(DatabaseHelper.instance);
  List<Category> _categories = [];
  final Map<int, List<_InventoryOption>> _bundleItemsByCategoryId = {};
  List<_BundleComponentEntry> _bundleComponents = [];
  bool _isLoadingCategories = true;
  bool _isLoadingBundleData = false;
  final FocusNode _categoryFocusNode = FocusNode();
  final TextEditingController _categoryQueryController =
      TextEditingController();
  bool _categoryFocused = false;
  int? _selectedCategoryId;

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
      _selectedCategoryId = widget.initialData!['category_id'] as int?;
    } else {
      _selectedCategoryId = null;
    }
    _categoryFocusNode.addListener(() {
      if (!mounted) return;
      if (_categoryFocusNode.hasFocus) {
        final selectedName = _selectedCategoryName();
        if (selectedName.isNotEmpty &&
            _categoryQueryController.text == selectedName) {
          _categoryQueryController.clear();
        }
      } else {
        final selectedName = _selectedCategoryName();
        _categoryQueryController.text = selectedName;
      }
      setState(() {
        _categoryFocused = _categoryFocusNode.hasFocus;
      });
    });
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryRepository.getAllCategories();

      if (mounted) {
        setState(() {
          _categories = categories;
        });

        if (_selectedCategoryId != null) {
          final selectedName = _selectedCategoryName();
          if (selectedName.isNotEmpty) {
            _categoryQueryController.text = selectedName;
          }
        }

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
    _nameFocusNode.dispose();
    _categoryFocusNode.dispose();
    _categoryQueryController.dispose();
    for (final entry in _bundleComponents) {
      entry.categoryQueryController.dispose();
      entry.categoryFocusNode.dispose();
      entry.itemQueryController.dispose();
      entry.itemFocusNode.dispose();
    }
    super.dispose();
  }

  bool _hasBundleComponents() {
    return _bundleComponents.any((entry) =>
        entry.categoryId != null || entry.selectedInventoryId != null);
  }

  Future<void> _loadInitialBundleComponents() async {
    if (widget.initialData == null) {
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

    final loadedEntries = <_BundleComponentEntry>[];
    for (final item in items) {
      final componentType = item.componentType.toLowerCase();
      final category = _findCategoryByName(componentType);
      if (category?.id == null) {
        continue;
      }

      final categoryItems = await _getItemsForCategory(category!.id!);
      final loaded = _BundleComponentEntry(
        categoryId: category.id,
        categoryName: category.name,
        selectedInventoryId: item.componentInventoryId,
        items: categoryItems,
      );
      _attachBundleCategoryFocus(loaded);
      _attachBundleItemFocus(loaded);
      loaded.categoryQueryController.text = category.name;
      loaded.itemQueryController.text =
          _selectedInventoryName(categoryItems, item.componentInventoryId);
      loadedEntries.add(loaded);
    }

    if (mounted) {
      setState(() {
        _bundleComponents = loadedEntries;
      });
    }

    if (mounted) {
      setState(() {
        _isLoadingBundleData = false;
      });
    }
  }

  Category? _findCategoryByName(String name) {
    for (final category in _categories) {
      if (category.name.toLowerCase() == name.toLowerCase()) {
        return category;
      }
    }
    return null;
  }

  _InventoryOption? _findInventoryOptionById(
      List<_InventoryOption> items, int? id) {
    if (id == null) {
      return null;
    }

    for (final item in items) {
      if (item.inventoryId == id) {
        return item;
      }
    }

    return null;
  }

  String _selectedInventoryName(List<_InventoryOption> items, int? id) {
    final selected = _findInventoryOptionById(items, id);
    return selected?.name ?? '';
  }

  Future<List<_InventoryOption>> _getItemsForCategory(int categoryId) async {
    final cached = _bundleItemsByCategoryId[categoryId];
    if (cached != null) {
      return cached;
    }

    final items =
        await _inventoryRepository.getInventoryOptionsByCategoryId(categoryId);
    final options = items.map(_InventoryOption.fromMap).toList();
    _bundleItemsByCategoryId[categoryId] = options;
    return options;
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

  List<Category> _categorySuggestions() {
    final query = _categoryQueryController.text.trim().toLowerCase();
    final filtered = _categories.where((category) {
      if (query.isEmpty) {
        return true;
      }
      return category.name.toLowerCase().contains(query);
    }).toList();

    if (query.isEmpty && filtered.length > 10) {
      return filtered.take(10).toList();
    }

    return filtered;
  }

  Future<void> _addNewCategoryFromDropdown() async {
    _categoryFocusNode.unfocus();
    final initialName = _categoryQueryController.text.trim();
    final newCategoryId = await _openAddCategoryDialog(initialName: initialName);
    if (newCategoryId != null && mounted) {
      await _loadCategories();
      _applyCategorySelection(newCategoryId);
    }
  }

  void _applyCategorySelection(int pickedId) {
    final category = _categories.where(
      (item) => item.id == pickedId,
    );

    _categoryQueryController.text = category.isNotEmpty
        ? category.first.name
        : _categoryQueryController.text;

    setState(() {
      _selectedCategoryId = pickedId;
      _selectedError = null;
    });
  }

  Future<int?> _openAddCategoryDialog({String initialName = ''}) async {
    final nameController = TextEditingController(text: initialName);

    final createdId = await showDialog<int?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: CustomColors.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: CustomColors.borderCardColor),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tambah Kategori Baru',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nama Kategori',
                        style: TextStyle(
                          fontSize: 12,
                          color: CustomColors.fontSubColor,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Kertas',
                          hintStyle: TextStyle(
                            color: CustomColors.fontSubColor,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: CustomColors.inputColor,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: CustomColors.borderInputColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF1379F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: Text(
                              'Batal',
                              style:
                                  TextStyle(color: CustomColors.fontSubColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final name = nameController.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Nama kategori wajib diisi')),
                                );
                                return;
                              }

                              try {
                                final id = await _categoryRepository
                                    .insertCategory(
                                  Category(
                                    name: name,
                                  ),
                                );
                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop(id);
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Gagal menambah kategori: $e')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1379F0),
                            ),
                            child: const Text(
                              'Tambah',
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

    nameController.dispose();
    return createdId;
  }

  List<Category> get _availableBundleSourceCategories => _categories;

  void _addBundleComponent() {
    final entry = _BundleComponentEntry();
    _attachBundleCategoryFocus(entry);
    _attachBundleItemFocus(entry);
    setState(() {
      _bundleComponents = [..._bundleComponents, entry];
    });
  }

  void _attachBundleCategoryFocus(_BundleComponentEntry entry) {
    entry.categoryFocusNode.addListener(() {
      if (!mounted) return;
      final focused = entry.categoryFocusNode.hasFocus;

      _BundleComponentEntry? liveEntry;
      for (final e in _bundleComponents) {
        if (identical(e.categoryFocusNode, entry.categoryFocusNode)) {
          liveEntry = e;
          break;
        }
      }
      if (liveEntry == null) {
        return;
      }

      if (focused) {
        if (liveEntry.categoryName.isNotEmpty &&
            liveEntry.categoryQueryController.text == liveEntry.categoryName) {
          liveEntry.categoryQueryController.clear();
        }
      } else {
        liveEntry.categoryQueryController.text = liveEntry.categoryName;
      }
      setState(() {
        _bundleComponents = [
          for (final e in _bundleComponents)
            if (identical(e.categoryFocusNode, entry.categoryFocusNode))
              e.copyWith(categoryFocused: focused)
            else
              e,
        ];
      });
    });
  }

  void _attachBundleItemFocus(_BundleComponentEntry entry) {
    entry.itemFocusNode.addListener(() {
      if (!mounted) return;
      final focused = entry.itemFocusNode.hasFocus;

      _BundleComponentEntry? liveEntry;
      for (final e in _bundleComponents) {
        if (identical(e.itemFocusNode, entry.itemFocusNode)) {
          liveEntry = e;
          break;
        }
      }
      if (liveEntry == null) {
        return;
      }

      final selectedName =
          _selectedInventoryName(liveEntry.items, liveEntry.selectedInventoryId);
      if (focused) {
        if (selectedName.isNotEmpty &&
            liveEntry.itemQueryController.text == selectedName) {
          liveEntry.itemQueryController.clear();
        }
      } else {
        liveEntry.itemQueryController.text = selectedName;
      }
      setState(() {
        _bundleComponents = [
          for (final e in _bundleComponents)
            if (identical(e.itemFocusNode, entry.itemFocusNode))
              e.copyWith(itemFocused: focused)
            else
              e,
        ];
      });
    });
  }

  void _removeBundleComponent(int index) {
    _bundleComponents[index].categoryFocusNode.dispose();
    _bundleComponents[index].categoryQueryController.dispose();
    _bundleComponents[index].itemFocusNode.dispose();
    _bundleComponents[index].itemQueryController.dispose();
    setState(() {
      _bundleComponents = [
        for (var i = 0; i < _bundleComponents.length; i++)
          if (i != index) _bundleComponents[i],
      ];
    });
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

    if (_hasBundleComponents()) {
      var hasError = false;
      final validatedEntries = <_BundleComponentEntry>[];
      for (final entry in _bundleComponents) {
        final isEmpty = entry.categoryId == null &&
            entry.selectedInventoryId == null;
        final categoryError = isEmpty
            ? null
            : (entry.categoryId == null ? 'Kategori wajib dipilih' : null);
        final itemError = isEmpty
            ? null
            : (entry.selectedInventoryId == null
                ? 'Item wajib dipilih'
                : null);
        if (categoryError != null || itemError != null) {
          hasError = true;
        }
        validatedEntries.add(
          entry.copyWith(
            categoryError: categoryError,
            itemError: itemError,
          ),
        );
      }

      if (hasError) {
        setState(() {
          _bundleComponents = validatedEntries;
        });
        return;
      }
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
    for (final entry in _bundleComponents) {
      if (entry.selectedInventoryId != null &&
          entry.categoryName.isNotEmpty) {
        bundleItems.add(
          {
            'component_inventory_id': entry.selectedInventoryId,
            'component_type': entry.categoryName,
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
                  // Input Nama Menu
                  _buildFormLabel('Nama Menu'),
                  const SizedBox(height: 8),
                  _buildNameInput(),
                  const SizedBox(height: 16),

                  // Dropdown Kategori Menu
                  _buildFormLabel('Kategori Menu'),
                  const SizedBox(height: 8),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),

                  // Input Harga
                  _buildFormLabel('Harga'),
                  const SizedBox(height: 8),
                  _buildPriceInput(),

                  const SizedBox(height: 16),
                  _buildFormLabel('Daftar Komponen'),
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
      {bool obscureText = false,
      bool enabled = true,
      String? errorText,
      FocusNode? focusNode,
      ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            enabled: enabled,
            onChanged: onChanged,
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

  Widget _buildNameInput() {
    return _buildTextField(_nameController, 'Masukkan nama menu',
        focusNode: _nameFocusNode,
        errorText: _nameError,
        onChanged: (_) {
          if (_nameError != null) {
            setState(() {
              _nameError = null;
            });
          }
        });
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

    final suggestions = _categorySuggestions();
    final categoryQuery = _categoryQueryController.text.trim();
    final trimmedLower = categoryQuery.toLowerCase();
    final hasExactMatch = trimmedLower.isNotEmpty &&
        suggestions.any(
          (category) => category.name.toLowerCase() == trimmedLower,
        );
    final showAddRow = trimmedLower.isNotEmpty && !hasExactMatch;
    final dropdownItems = suggestions.length + (showAddRow ? 1 : 0);

    return TapRegion(
      onTapOutside: (_) {
        _categoryFocusNode.unfocus();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 34,
            child: TextField(
              controller: _categoryQueryController,
              focusNode: _categoryFocusNode,
              onTapOutside: (_) {
                // Jangan tutup dropdown saat menyentuh item dropdown;
                // TapRegion di atas yang menangani klik di luar widget.
              },
              onChanged: (_) {
              setState(() {
                if (_selectedError != null) {
                  _selectedError = null;
                }
              });
            },
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: 'Pilih kategori (bisa dicari)',
              hintStyle: const TextStyle(
                color: CustomColors.fontSubColor,
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(Icons.search,
                  size: 18, color: CustomColors.fontSubColor),
              suffixIcon: Icon(
                _categoryFocused
                    ? Icons.arrow_drop_up
                    : Icons.arrow_drop_down,
                size: 20,
                color: CustomColors.fontSubColor,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: CustomColors.inputColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _selectedError != null
                      ? Colors.red
                      : CustomColors.borderInputColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color:
                      _selectedError != null ? Colors.red : Color(0xFF1379F0),
                ),
              ),
            ),
          ),
        ),
        if (_categoryFocused && dropdownItems > 0) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: CustomColors.inputColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CustomColors.borderInputColor),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: dropdownItems,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: CustomColors.borderCardColor,
                ),
                itemBuilder: (context, index) {
                  if (showAddRow && index == 0) {
                    return InkWell(
                      onTap: _addNewCategoryFromDropdown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.add,
                                size: 16, color: Color(0xFF1379F0)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Tambahkan kategori '$categoryQuery'",
                                style: const TextStyle(
                                  color: Color(0xFF1379F0),
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final category =
                      suggestions[index - (showAddRow ? 1 : 0)];
                  final active = _selectedCategoryId == category.id;
                  return InkWell(
                    onTap: () {
                      if (category.id == null) {
                        return;
                      }
                      _applyCategorySelection(category.id!);
                      _categoryFocusNode.unfocus();
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
                          if (active) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.check,
                                size: 16, color: Color(0xFF1379F0)),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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
      ),
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

  Widget _buildBundleComponentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < _bundleComponents.length; index++) ...[
          _buildBundleComponentRepeater(index),
          if (index != _bundleComponents.length - 1) const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _addBundleComponent,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: CustomColors.borderInputColor),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          icon: const Icon(Icons.add, size: 16),
          label: const Text(
            'Tambah Komponen',
            style: TextStyle(fontFamily: 'Inter', fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildBundleCategoryDropdown(int index) {
    final entry = _bundleComponents[index];
    final suggestions = _bundleCategorySuggestions(index);
    final categoryQuery = entry.categoryQueryController.text.trim();
    final trimmedLower = categoryQuery.toLowerCase();
    final hasExactMatch = trimmedLower.isNotEmpty &&
        suggestions.any(
          (category) => category.name.toLowerCase() == trimmedLower,
        );
    final showAddRow = trimmedLower.isNotEmpty && !hasExactMatch;
    final dropdownItems = suggestions.length + (showAddRow ? 1 : 0);

    return TapRegion(
      onTapOutside: (_) {
        entry.categoryFocusNode.unfocus();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori Inventori',
            style: const TextStyle(
              fontSize: 12,
              color: CustomColors.fontSubColor,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: TextField(
              controller: entry.categoryQueryController,
              focusNode: entry.categoryFocusNode,
              onTapOutside: (_) {},
              onChanged: (_) {
                setState(() {
                  _bundleComponents[index] = entry.copyWith(
                    categoryError: null,
                  );
                });
              },
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: 'Pilih kategori (bisa dicari)',
                hintStyle: const TextStyle(
                  color: CustomColors.fontSubColor,
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(Icons.search,
                    size: 18, color: CustomColors.fontSubColor),
                suffixIcon: Icon(
                  entry.categoryFocused
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                  size: 20,
                  color: CustomColors.fontSubColor,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: CustomColors.inputColor,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: entry.categoryError != null
                        ? Colors.red
                        : CustomColors.borderInputColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: entry.categoryError != null
                        ? Colors.red
                        : Color(0xFF1379F0),
                  ),
                ),
              ),
            ),
          ),
          if (entry.categoryFocused && dropdownItems > 0) ...[
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: CustomColors.inputColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CustomColors.borderInputColor),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: dropdownItems,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: CustomColors.borderCardColor,
                  ),
                  itemBuilder: (context, itemIndex) {
                    if (showAddRow && itemIndex == 0) {
                      return InkWell(
                        onTap: () =>
                            _createBundleCategoryFromDropdown(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.add,
                                  size: 16, color: Color(0xFF1379F0)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Tambahkan kategori '$categoryQuery'",
                                  style: const TextStyle(
                                    color: Color(0xFF1379F0),
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final category =
                        suggestions[itemIndex - (showAddRow ? 1 : 0)];
                    final active = entry.categoryId == category.id;
                    return InkWell(
                      onTap: () {
                        if (category.id == null) {
                          return;
                        }
                        entry.categoryFocusNode.unfocus();
                        _applyBundleCategorySelection(index, category.id!);
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
                            if (active) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.check,
                                  size: 16, color: Color(0xFF1379F0)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          if (entry.categoryError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                entry.categoryError!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Category> _bundleCategorySuggestions(int index) {
    final entry = _bundleComponents[index];
    final query = entry.categoryQueryController.text.trim().toLowerCase();
    final available = _availableBundleSourceCategories;

    final filtered = available.where((category) {
      if (query.isEmpty) {
        return true;
      }
      return category.name.toLowerCase().contains(query);
    }).toList();

    if (query.isEmpty && filtered.length > 10) {
      return filtered.take(10).toList();
    }

    return filtered;
  }

  Widget _buildBundleItemDropdown(int index) {
    final entry = _bundleComponents[index];
    final suggestions = _bundleItemSuggestions(index);
    final selectedName =
        _selectedInventoryName(entry.items, entry.selectedInventoryId);

    if (entry.categoryId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Item Inventori',
            style: TextStyle(
              fontSize: 12,
              color: CustomColors.fontSubColor,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: Container(
              decoration: BoxDecoration(
                color: CustomColors.borderInputColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CustomColors.borderInputColor),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.search,
                      size: 18, color: CustomColors.fontSubColor),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Pilih kategori terlebih dahulu',
                      style: TextStyle(
                        color: CustomColors.fontSubColor,
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  if (entry.itemError != null)
                    const Icon(Icons.error,
                        size: 16, color: Colors.red),
                ],
              ),
            ),
          ),
          if (entry.itemError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                entry.itemError!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      );
    }

    final dropdownItems = suggestions.length;

    return TapRegion(
      onTapOutside: (_) {
        entry.itemFocusNode.unfocus();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Item Inventori',
            style: TextStyle(
              fontSize: 12,
              color: CustomColors.fontSubColor,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: TextField(
              controller: entry.itemQueryController,
              focusNode: entry.itemFocusNode,
              onTapOutside: (_) {},
              onChanged: (_) {
                setState(() {
                  _bundleComponents[index] = entry.copyWith(
                    itemError: null,
                  );
                });
              },
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: entry.itemFocused
                    ? 'Cari item...'
                    : (selectedName.isEmpty ? 'Pilih item' : null),
                hintStyle: const TextStyle(
                  color: CustomColors.fontSubColor,
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(Icons.search,
                    size: 18, color: CustomColors.fontSubColor),
                suffixIcon: selectedName.isNotEmpty && !entry.itemFocused
                    ? InkWell(
                        onTap: () {
                          setState(() {
                            _bundleComponents[index] = entry.copyWith(
                              selectedInventoryId: null,
                              clearSelectedInventoryId: true,
                              itemError: null,
                            );
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.clear,
                              size: 16, color: CustomColors.fontSubColor),
                        ),
                      )
                    : Icon(
                        entry.itemFocused
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        size: 20,
                        color: CustomColors.fontSubColor,
                      ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: CustomColors.inputColor,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: entry.itemError != null
                        ? Colors.red
                        : CustomColors.borderInputColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: entry.itemError != null
                        ? Colors.red
                        : const Color(0xFF1379F0),
                  ),
                ),
              ),
            ),
          ),
          if (entry.itemFocused && dropdownItems > 0) ...[
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: CustomColors.inputColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CustomColors.borderInputColor),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: dropdownItems,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: CustomColors.borderCardColor,
                  ),
                  itemBuilder: (context, itemIndex) {
                    final item = suggestions[itemIndex];
                    final active =
                        entry.selectedInventoryId == item.inventoryId;
                    return InkWell(
                      onTap: () {
                        entry.itemFocusNode.unfocus();
                        _applyBundleItemSelection(index, item.inventoryId);
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
                            if (active) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.check,
                                  size: 16, color: Color(0xFF1379F0)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          if (entry.itemError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                entry.itemError!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_InventoryOption> _bundleItemSuggestions(int index) {
    final entry = _bundleComponents[index];
    if (entry.categoryId == null) {
      return const [];
    }

    final query = entry.itemQueryController.text.trim().toLowerCase();
    final filtered = entry.items.where((item) {
      if (query.isEmpty) {
        return true;
      }
      return item.name.toLowerCase().contains(query);
    }).toList();

    if (query.isEmpty && filtered.length > 10) {
      return filtered.take(10).toList();
    }

    return filtered;
  }

  void _applyBundleItemSelection(int index, int pickedInventoryId) {
    final liveEntry = _bundleComponents[index];
    final name =
        _selectedInventoryName(liveEntry.items, pickedInventoryId);
    liveEntry.itemFocusNode.unfocus();
    liveEntry.itemQueryController.text = name;
    setState(() {
      _bundleComponents[index] = liveEntry.copyWith(
        selectedInventoryId: pickedInventoryId,
        itemError: null,
        itemFocused: false,
      );
    });
  }

  Future<void> _createBundleCategoryFromDropdown(int index) async {
    final entry = _bundleComponents[index];
    entry.categoryFocusNode.unfocus();
    final initialName = entry.categoryQueryController.text.trim();
    final newCategoryId = await _openAddCategoryDialog(initialName: initialName);
    if (newCategoryId != null && mounted) {
      final categories = await _categoryRepository.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
      await _applyBundleCategorySelection(index, newCategoryId);
    }
  }

  Future<void> _applyBundleCategorySelection(int index, int pickedCategoryId) async {
    Category? category;
    for (final item in _categories) {
      if (item.id == pickedCategoryId) {
        category = item;
        break;
      }
    }
    if (category == null) {
      return;
    }

    final items = await _getItemsForCategory(pickedCategoryId);
    if (!mounted) {
      return;
    }

    final liveEntry = _bundleComponents[index];
    liveEntry.categoryFocusNode.unfocus();
    liveEntry.categoryQueryController.text = category.name;
    liveEntry.itemQueryController.clear();
    setState(() {
      _bundleComponents[index] = liveEntry.copyWith(
        categoryId: category!.id,
        categoryName: category.name,
        selectedInventoryId: null,
        clearSelectedInventoryId: true,
        items: items,
        categoryError: null,
        itemError: null,
        categoryFocused: false,
      );
    });
  }

  Widget _buildBundleComponentRepeater(int index) {
    final categoryPicker = _buildBundleCategoryDropdown(index);
    final itemPicker = _buildBundleItemDropdown(index);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CustomColors.inputColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CustomColors.borderInputColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Komponen ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _removeBundleComponent(index),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline,
                      color: CustomColors.fontSubColor,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    categoryPicker,
                    const SizedBox(height: 8),
                    itemPicker,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: categoryPicker),
                  const SizedBox(width: 10),
                  Expanded(child: itemPicker),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BundleComponentEntry {
  final int? categoryId;
  final String categoryName;
  final int? selectedInventoryId;
  final List<_InventoryOption> items;
  final String? categoryError;
  final String? itemError;
  final FocusNode categoryFocusNode;
  final TextEditingController categoryQueryController;
  final bool categoryFocused;
  final FocusNode itemFocusNode;
  final TextEditingController itemQueryController;
  final bool itemFocused;

  _BundleComponentEntry({
    this.categoryId,
    this.categoryName = '',
    this.selectedInventoryId,
    this.items = const [],
    this.categoryError,
    this.itemError,
    FocusNode? categoryFocusNode,
    TextEditingController? categoryQueryController,
    this.categoryFocused = false,
    FocusNode? itemFocusNode,
    TextEditingController? itemQueryController,
    this.itemFocused = false,
  })  : categoryFocusNode = categoryFocusNode ?? FocusNode(),
        categoryQueryController =
            categoryQueryController ?? TextEditingController(),
        itemFocusNode = itemFocusNode ?? FocusNode(),
        itemQueryController =
            itemQueryController ?? TextEditingController();

  _BundleComponentEntry copyWith({
    int? categoryId,
    String? categoryName,
    int? selectedInventoryId,
    bool clearSelectedInventoryId = false,
    List<_InventoryOption>? items,
    String? categoryError,
    String? itemError,
    FocusNode? categoryFocusNode,
    TextEditingController? categoryQueryController,
    bool? categoryFocused,
    FocusNode? itemFocusNode,
    TextEditingController? itemQueryController,
    bool? itemFocused,
  }) {
    return _BundleComponentEntry(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      selectedInventoryId: clearSelectedInventoryId
          ? null
          : (selectedInventoryId ?? this.selectedInventoryId),
      items: items ?? this.items,
      categoryError: categoryError,
      itemError: itemError,
      categoryFocusNode: categoryFocusNode ?? this.categoryFocusNode,
      categoryQueryController:
          categoryQueryController ?? this.categoryQueryController,
      categoryFocused: categoryFocused ?? this.categoryFocused,
      itemFocusNode: itemFocusNode ?? this.itemFocusNode,
      itemQueryController: itemQueryController ?? this.itemQueryController,
      itemFocused: itemFocused ?? this.itemFocused,
    );
  }
}

class _InventoryOption {
  final int inventoryId;
  final int? masterDataId;
  final int stock;
  final String name;

  const _InventoryOption({
    required this.inventoryId,
    this.masterDataId,
    this.stock = 0,
    required this.name,
  });

  factory _InventoryOption.fromMap(Map<String, dynamic> map) {
    return _InventoryOption(
      inventoryId: map['inventory_id'] as int,
      masterDataId: map['master_data_id'] as int?,
      stock: (map['stock'] as int?) ?? 0,
      name: (map['name'] ?? '') as String,
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
