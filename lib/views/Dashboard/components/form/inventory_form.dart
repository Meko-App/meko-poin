import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meko_poin/models/category.dart';
import 'package:meko_poin/services/category_repository.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/inventory_repository.dart';
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
  late final CategoryRepository _categoryRepository;
  late final InventoryRepository _inventoryRepository;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryQueryController =
      TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final FocusNode _categoryFocusNode = FocusNode();

  List<Category> _categories = [];
  bool _isLoadingCategories = true;
  bool _categoryFocused = false;
  int? _selectedCategoryId;
  int? _editingInventoryId;

  String? _nameError;
  String? _categoryError;
  String? _stockError;

  @override
  void initState() {
    super.initState();
    _categoryRepository = CategoryRepository(DatabaseHelper.instance);
    _inventoryRepository = InventoryRepository(DatabaseHelper.instance);

    if (widget.initialData != null) {
      _nameController.text = (widget.initialData!['name'] ?? '') as String;
      _stockController.text =
          (widget.initialData!['stock']?.toString() ?? '');
      _selectedCategoryId = widget.initialData!['category_id'] as int?;
      _editingInventoryId = widget.initialData!['id'] as int?;
    }

    _categoryFocusNode.addListener(() {
      if (!mounted) return;
      setState(() {
        _categoryFocused = _categoryFocusNode.hasFocus;
      });
    });

    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryQueryController.dispose();
    _stockController.dispose();
    _categoryFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await _categoryRepository.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = data;
          _isLoadingCategories = false;
          _syncCategoryQuery();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  void _syncCategoryQuery() {
    if (_selectedCategoryId != null) {
      final selected = _categories
          .where((category) => category.id == _selectedCategoryId);
      if (selected.isNotEmpty) {
        _categoryQueryController.text = selected.first.name;
      }
    }
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

  void _applyCategorySelection(int pickedId) {
    final category = _categories.where((item) => item.id == pickedId);
    _categoryQueryController.text =
        category.isNotEmpty ? category.first.name : '';

    setState(() {
      _selectedCategoryId = pickedId;
      _categoryError = null;
    });
  }

  Future<void> _addNewCategoryFromDropdown() async {
    _categoryFocusNode.unfocus();
    final initialName = _categoryQueryController.text.trim();
    final newCategoryId =
        await _openAddCategoryDialog(initialName: initialName);
    if (newCategoryId != null && mounted) {
      await _loadCategories();
      _applyCategorySelection(newCategoryId);
    }
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
                            borderSide:
                                const BorderSide(color: Color(0xFF1379F0)),
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
                              style: TextStyle(
                                  color: CustomColors.fontSubColor),
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

    return createdId;
  }

  void _saveInventory() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _nameError = 'Nama item wajib diisi';
      });
      return;
    }

    if (_selectedCategoryId == null) {
      setState(() {
        _categoryError = 'Kategori wajib dipilih';
      });
      return;
    }

    if (_stockController.text.isEmpty) {
      setState(() {
        _stockError = 'Jumlah stok wajib diisi';
      });
      return;
    }

    final int stock = int.tryParse(_stockController.text) ?? 0;

    try {
      final isDuplicate = await _inventoryRepository.isNameCategoryUsed(
        name,
        _selectedCategoryId!,
        excludeId: _editingInventoryId,
      );
      if (isDuplicate) {
        if (mounted) {
          setState(() {
            _nameError =
                'Item inventori sudah digunakan pada kategori ini';
          });
        }
        return;
      }

      final Map<String, dynamic> inventoryData = {
        'name': name,
        'category_id': _selectedCategoryId,
        'stock': stock,
      };

      widget.onSubmit(inventoryData);
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
                  _buildNameInput(),
                  const SizedBox(height: 16),

                  // Dropdown Kategori
                  _buildFormLabel('Kategori'),
                  const SizedBox(height: 8),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),

                  // Input Stok
                  _buildFormLabel('Jumlah Stok'),
                  const SizedBox(height: 8),
                  _buildStockInput(),
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

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: TextField(
            controller: _nameController,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Masukkan nama item',
              hintStyle: TextStyle(
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                color: CustomColors.fontSubColor,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: _nameError != null
                        ? Colors.red
                        : CustomColors.borderInputColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: _nameError != null ? Colors.red : Color(0xFF1379F0)),
              ),
              filled: true,
              fillColor: CustomColors.inputColor,
            ),
            onChanged: (_) {
              if (_nameError != null) {
                setState(() {
                  _nameError = null;
                });
              }
            },
          ),
        ),
        if (_nameError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              _nameError!,
              style: const TextStyle(
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
              onTapOutside: (_) {},
              onChanged: (_) {
                setState(() {
                  if (_categoryError != null) {
                    _categoryError = null;
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
                    color: _categoryError != null
                        ? Colors.red
                        : CustomColors.borderInputColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _categoryError != null
                        ? Colors.red
                        : Color(0xFF1379F0),
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                category.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: active
                                      ? const Color(0xFF1379F0)
                                      : Colors.white,
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: active
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (active)
                              const Icon(Icons.check,
                                  size: 16, color: Color(0xFF1379F0)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          if (_categoryError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                _categoryError!,
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
                  onChanged: (_) {
                    if (_stockError != null) {
                      setState(() {
                        _stockError = null;
                      });
                    }
                  },
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
                    Container(
                      height: 1,
                      color: CustomColors.borderInputColor,
                    ),
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