import 'package:flutter/material.dart';
import 'package:meko_poin/models/category.dart';
import 'package:meko_poin/services/category_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/content_state.dart';

class CategoryContent extends StatefulWidget {
  final Function(ContentState) onStateChanged;
  final CategoryRepository categoryRepository;

  const CategoryContent({
    super.key,
    required this.onStateChanged,
    required this.categoryRepository,
  });

  @override
  State<CategoryContent> createState() => _CategoryContentState();
}

class _CategoryContentState extends State<CategoryContent> {
  ContentState _currentState = ContentState.table;
  bool _isLoading = true;
  List<Category> _categories = [];
  Category? _editingCategory;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _isBundle = false;
  bool _isCountable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStateChanged(_currentState);
    });
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final data = await widget.categoryRepository.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat kategori: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openForm([Category? category]) {
    setState(() {
      _currentState = ContentState.form;
      _editingCategory = category;
      _nameController.text = category?.name ?? '';
      _codeController.text = category?.code ?? '';
      _isBundle = category?.isBundle ?? false;
      _isCountable = category?.isCountable ?? false;
      widget.onStateChanged(_currentState);
    });
  }

  void _backToTable() {
    setState(() {
      _currentState = ContentState.table;
      _editingCategory = null;
      _nameController.clear();
      _codeController.clear();
      _isBundle = false;
      _isCountable = false;
      widget.onStateChanged(_currentState);
    });
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toLowerCase();

    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan kode kategori wajib diisi')),
      );
      return;
    }

    try {
      if (_editingCategory == null) {
        await widget.categoryRepository.insertCategory(
          Category(
            name: name,
            code: code,
            isBundle: _isBundle,
            isCountable: _isCountable,
          ),
        );
      } else {
        await widget.categoryRepository.updateCategory(
          Category(
            id: _editingCategory!.id,
            name: name,
            code: code,
            isBundle: _isBundle,
            isCountable: _isCountable,
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingCategory == null
                ? 'Kategori berhasil ditambahkan'
                : 'Kategori berhasil diperbarui'),
          ),
        );
      }

      _backToTable();
      await _loadCategories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan kategori: $e')),
        );
      }
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CustomColors.cardColor,
        title:
            const Text('Hapus Kategori', style: TextStyle(color: Colors.white)),
        content: Text(
          'Kategori akan dihapus dan master data terkait dipindahkan ke kategori default.',
          style: TextStyle(color: CustomColors.fontSubColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await widget.categoryRepository.softDeleteAndReassignMasterData(
        categoryId: category.id!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori berhasil dihapus')),
        );
      }
      await _loadCategories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus kategori: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_currentState == ContentState.form)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.grey.shade700,
                  onPressed: _backToTable,
                ),
              if (_currentState == ContentState.form) const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentState == ContentState.table
                        ? 'Kategori'
                        : (_editingCategory == null
                            ? 'Tambah Kategori'
                            : 'Edit Kategori'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola kategori dan aturan stok item',
                    style: const TextStyle(
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
          _currentState == ContentState.table ? _buildTable() : _buildForm(),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CustomColors.borderCardColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daftar Kategori',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    )),
                ElevatedButton(
                  onPressed: () => _openForm(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1379F0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Tambah Kategori',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )
          else if (_categories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Belum ada kategori',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: CustomColors.borderCardColor,
              ),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return ListTile(
                  title: Text(category.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    'code: ${category.code} | bundle: ${category.isBundle ? 'Ya' : 'Tidak'} | countable: ${category.isCountable ? 'Ya' : 'Tidak'}',
                    style: const TextStyle(
                        color: CustomColors.fontSubColor,
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w400),
                  ),
                  trailing: PopupMenuButton<String>(
                    color: CustomColors.cardColor,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openForm(category);
                      }
                      if (value == 'delete') {
                        _deleteCategory(category);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit', style: TextStyle(color: Colors.white)),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CustomColors.borderCardColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Nama Kategori'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Masukkan nama kategori'),
          ),
          const SizedBox(height: 16),
          _buildLabel('Kode Kategori'),
          const SizedBox(height: 8),
          TextField(
            controller: _codeController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Contoh: paper'),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            value: _isBundle,
            onChanged: (value) => setState(() => _isBundle = value),
            title:
                const Text('Is Bundle', style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: Text(
              'Khusus untuk bundle atau paketan',
              style: TextStyle(color: CustomColors.fontSubColor),
            ),
            activeColor: const Color(0xFF1379F0),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _isCountable,
            onChanged: (value) => setState(() => _isCountable = value),
            title: const Text('Is Countable',
                style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: Text(
              'Menentukan item ini wajib cek dan update stok atau tidak',
              style: TextStyle(color: CustomColors.fontSubColor),
            ),
            activeColor: const Color(0xFF1379F0),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _backToTable,
                style: TextButton.styleFrom(
                  foregroundColor: CustomColors.fontSubColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1379F0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  _editingCategory == null ? 'Buat Baru' : 'Simpan',
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 13,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        color: CustomColors.fontSubColor,
      ),
      filled: true,
      fillColor: CustomColors.inputColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: CustomColors.borderInputColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: CustomColors.borderInputColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1379F0)),
      ),
    );
  }
}
