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
  final Map<int, List<MasterData>> _bundleItemsByCategoryId = {};
  List<_BundleComponentEntry> _bundleComponents = [];
  bool _isLoadingCategories = true;
  bool _isLoadingBundleData = false;
  int? _selectedCategoryId;
  bool _isManualPriceOverride = false;

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
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryRepository.getAllCategories();

      if (mounted) {
        setState(() {
          _categories = categories;
        });

        await _loadInitialBundleComponents();
        if (_isSelectedCategoryBundle() && _bundleComponents.isEmpty) {
          _addBundleComponent();
        }
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

    final loadedEntries = <_BundleComponentEntry>[];
    for (final item in items) {
      final componentType = item.componentType.toLowerCase();
      final category = _findCategoryByCode(componentType);
      if (category?.id == null) {
        continue;
      }

      final categoryItems = await _getItemsForCategory(category!.id!);
      loadedEntries.add(
        _BundleComponentEntry(
          categoryId: category.id,
          categoryCode: category.code,
          categoryName: category.name,
          selectedItemId: item.componentMasterDataId,
          items: categoryItems,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _bundleComponents = loadedEntries.isEmpty
            ? <_BundleComponentEntry>[_BundleComponentEntry()]
            : loadedEntries;
      });
    }

    _autoCalculateBundlePrice();

    if (mounted) {
      setState(() {
        _isLoadingBundleData = false;
      });
    }
  }

  Category? _findCategoryByCode(String code) {
    for (final category in _categories) {
      if (category.code.toLowerCase() == code.toLowerCase()) {
        return category;
      }
    }
    return null;
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

  Future<List<MasterData>> _getItemsForCategory(int categoryId) async {
    final cached = _bundleItemsByCategoryId[categoryId];
    if (cached != null) {
      return cached;
    }

    final items = await _masterDataRepository.getMasterDataByCategoryId(
      categoryId,
    );
    _bundleItemsByCategoryId[categoryId] = items;
    return items;
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
    DateTime? lastTapAt;
    int? lastTappedItemId;

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
                constraints:
                    const BoxConstraints(maxWidth: 460, maxHeight: 520),
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
                                        final now = DateTime.now();
                                        final isDoubleClick =
                                            lastTappedItemId == item.id &&
                                                lastTapAt != null &&
                                                now
                                                        .difference(lastTapAt!)
                                                        .inMilliseconds <
                                                    300;

                                        setDialogState(() {
                                          localSelectedId = item.id;
                                        });

                                        if (isDoubleClick) {
                                          Navigator.of(dialogContext)
                                              .pop(item.id);
                                          return;
                                        }

                                        lastTapAt = now;
                                        lastTappedItemId = item.id;
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

    var total = 0;
    for (final entry in _bundleComponents) {
      final selected = _findMasterDataById(entry.items, entry.selectedItemId);
      total += selected?.price ?? 0;
    }

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
    DateTime? lastTapAt;
    int? lastTappedCategoryId;

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
                                        final now = DateTime.now();
                                        final isDoubleClick =
                                            lastTappedCategoryId ==
                                                    category.id &&
                                                lastTapAt != null &&
                                                now
                                                        .difference(lastTapAt!)
                                                        .inMilliseconds <
                                                    300;

                                        setDialogState(() {
                                          selectedId = category.id;
                                        });

                                        if (isDoubleClick) {
                                          Navigator.of(dialogContext)
                                              .pop(category.id);
                                          return;
                                        }

                                        lastTapAt = now;
                                        lastTappedCategoryId = category.id;
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
      final isBundleCategory = _categories.any(
        (category) => category.id == pickedId && category.isBundle,
      );

      setState(() {
        _selectedCategoryId = pickedId;
        _selectedError = null;

        if (!isBundleCategory) {
          _bundleComponents = [];
          _isManualPriceOverride = false;
        } else {
          _bundleComponents = [_BundleComponentEntry()];
          _isManualPriceOverride = false;
          _autoCalculateBundlePrice();
        }
      });
    }
  }

  List<Category> _availableBundleSourceCategories({int? currentCategoryId}) {
    final usedIds = _bundleComponents
        .where((entry) =>
            entry.categoryId != null && entry.categoryId != currentCategoryId)
        .map((entry) => entry.categoryId!)
        .toSet();

    return _categories.where((category) {
      if (category.isBundle) return false;
      if (category.id == _selectedCategoryId) return false;
      if (usedIds.contains(category.id)) return false;
      return true;
    }).toList();
  }

  Future<int?> _openBundleSourceCategoryDialog({
    required int? selectedCategoryId,
  }) async {
    final options = _availableBundleSourceCategories(
      currentCategoryId: selectedCategoryId,
    );
    if (options.isEmpty && selectedCategoryId == null) {
      return null;
    }

    int? localSelectedId = selectedCategoryId;
    String query = '';
    DateTime? lastTapAt;
    int? lastTappedCategoryId;

    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final normalizedQuery = query.trim().toLowerCase();
            final filtered = options.where((category) {
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
                        'Pilih Kategori Komponen',
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
                                    final active =
                                        localSelectedId == category.id;
                                    return InkWell(
                                      onTap: () {
                                        final now = DateTime.now();
                                        final isDoubleClick =
                                            lastTappedCategoryId ==
                                                    category.id &&
                                                lastTapAt != null &&
                                                now
                                                        .difference(lastTapAt!)
                                                        .inMilliseconds <
                                                    300;

                                        setDialogState(() {
                                          localSelectedId = category.id;
                                        });

                                        if (isDoubleClick) {
                                          Navigator.of(dialogContext)
                                              .pop(category.id);
                                          return;
                                        }

                                        lastTapAt = now;
                                        lastTappedCategoryId = category.id;
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

  void _addBundleComponent() {
    setState(() {
      _bundleComponents = [..._bundleComponents, _BundleComponentEntry()];
    });
  }

  void _removeBundleComponent(int index) {
    setState(() {
      _bundleComponents = [
        for (var i = 0; i < _bundleComponents.length; i++)
          if (i != index) _bundleComponents[i],
      ];
      if (_bundleComponents.isEmpty && _isSelectedCategoryBundle()) {
        _bundleComponents = [_BundleComponentEntry()];
      }
    });
    _autoCalculateBundlePrice();
  }

  Future<void> _selectBundleSourceCategory(int index) async {
    final current = _bundleComponents[index];
    final pickedCategoryId = await _openBundleSourceCategoryDialog(
      selectedCategoryId: current.categoryId,
    );
    if (pickedCategoryId == null) {
      return;
    }

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

    setState(() {
      _bundleComponents[index] = current.copyWith(
        categoryId: category!.id,
        categoryCode: category.code,
        categoryName: category.name,
        selectedItemId: null,
        items: items,
        categoryError: null,
        itemError: null,
      );
    });
    _autoCalculateBundlePrice();
  }

  Future<void> _selectBundleItem(int index) async {
    final current = _bundleComponents[index];
    if (current.categoryId == null || current.items.isEmpty) {
      return;
    }

    final pickedId = await _openMasterDataSearchDialog(
      title: 'Pilih Item',
      items: current.items,
      selectedId: current.selectedItemId,
    );

    if (pickedId != null && mounted) {
      setState(() {
        _bundleComponents[index] = current.copyWith(
          selectedItemId: pickedId,
          itemError: null,
        );
      });
      _autoCalculateBundlePrice();
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

    if (_isSelectedCategoryBundle()) {
      if (_bundleComponents.isEmpty) {
        setState(() {
          _bundleComponents = [
            _BundleComponentEntry(itemError: 'Item wajib dipilih')
          ];
        });
        return;
      }

      var hasError = false;
      final validatedEntries = <_BundleComponentEntry>[];
      for (final entry in _bundleComponents) {
        final categoryError =
            entry.categoryId == null ? 'Kategori wajib dipilih' : null;
        final itemError =
            entry.selectedItemId == null ? 'Item wajib dipilih' : null;
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
    if (_isSelectedCategoryBundle()) {
      for (final entry in _bundleComponents) {
        if (entry.selectedItemId != null && entry.categoryCode.isNotEmpty) {
          bundleItems.add(
            {
              'component_master_data_id': entry.selectedItemId,
              'component_type': entry.categoryCode,
              'qty': 1,
            },
          );
        }
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
        for (var index = 0; index < _bundleComponents.length; index++) ...[
          _buildBundleComponentRepeater(index),
          if (index != _bundleComponents.length - 1) const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _availableBundleSourceCategories().isEmpty
              ? null
              : _addBundleComponent,
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

  Widget _buildBundleComponentRepeater(int index) {
    final entry = _bundleComponents[index];
    final itemValue =
        _selectedMasterDataName(entry.items, entry.selectedItemId);
    final categoryPicker = _buildMasterDataPicker(
      label: 'Kategori',
      value: entry.categoryName,
      errorText: entry.categoryError,
      onTap: () => _selectBundleSourceCategory(index),
      emptyLabel: 'Pilih kategori (bisa dicari)',
    );
    final itemPicker = _buildMasterDataPicker(
      label: 'Item',
      value: itemValue,
      errorText: entry.itemError,
      onTap: entry.categoryId == null ? () {} : () => _selectBundleItem(index),
      emptyLabel: entry.categoryId == null
          ? 'Pilih kategori terlebih dahulu'
          : 'Pilih item',
      enabled: entry.categoryId != null,
      onClear: entry.selectedItemId == null
          ? null
          : () {
              setState(() {
                _bundleComponents[index] = entry.copyWith(
                  selectedItemId: null,
                  itemError: null,
                );
              });
              _autoCalculateBundlePrice();
            },
    );

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
              if (_bundleComponents.length > 1)
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

  Widget _buildMasterDataPicker({
    required String label,
    required String value,
    required VoidCallback onTap,
    VoidCallback? onClear,
    String? errorText,
    String emptyLabel = 'Pilih item',
    bool enabled = true,
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
              onTap: enabled ? onTap : null,
              child: Ink(
                decoration: BoxDecoration(
                  color: enabled
                      ? CustomColors.inputColor
                      : CustomColors.borderInputColor,
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
                          value.isEmpty ? emptyLabel : value,
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

class _BundleComponentEntry {
  final int? categoryId;
  final String categoryCode;
  final String categoryName;
  final int? selectedItemId;
  final List<MasterData> items;
  final String? categoryError;
  final String? itemError;

  const _BundleComponentEntry({
    this.categoryId,
    this.categoryCode = '',
    this.categoryName = '',
    this.selectedItemId,
    this.items = const [],
    this.categoryError,
    this.itemError,
  });

  _BundleComponentEntry copyWith({
    int? categoryId,
    String? categoryCode,
    String? categoryName,
    int? selectedItemId,
    List<MasterData>? items,
    String? categoryError,
    String? itemError,
  }) {
    return _BundleComponentEntry(
      categoryId: categoryId ?? this.categoryId,
      categoryCode: categoryCode ?? this.categoryCode,
      categoryName: categoryName ?? this.categoryName,
      selectedItemId: selectedItemId,
      items: items ?? this.items,
      categoryError: categoryError,
      itemError: itemError,
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
