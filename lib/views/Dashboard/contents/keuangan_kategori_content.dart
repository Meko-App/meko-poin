import 'package:flutter/material.dart';
import 'package:meko_poin/models/keuangan_kategori.dart';
import 'package:meko_poin/services/keuangan_kategori_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/content_state.dart';

class KeuanganKategoriContent extends StatefulWidget {
  final Function(ContentState) onStateChanged;
  final KeuanganKategoriRepository kategoriRepository;

  const KeuanganKategoriContent({
    super.key,
    required this.onStateChanged,
    required this.kategoriRepository,
  });

  @override
  State<KeuanganKategoriContent> createState() => _KeuanganKategoriContentState();
}

class _KeuanganKategoriContentState extends State<KeuanganKategoriContent> {
  ContentState _currentState = ContentState.table;
  KeuanganKategori? _editingKategori;
  final TextEditingController _nameController = TextEditingController();
  List<KeuanganKategori> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStateChanged(_currentState);
    });
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await widget.kategoriRepository.getAllKeuanganKategori();
      if (mounted) setState(() => _categories = data);
    } catch (e) {
      debugPrint('Error loading keuangan kategori: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openForm([KeuanganKategori? kategori]) {
    setState(() {
      _currentState = ContentState.form;
      _editingKategori = kategori;
      _nameController.text = kategori?.name ?? '';
      widget.onStateChanged(_currentState);
    });
  }

  void _backToTable() {
    setState(() {
      _currentState = ContentState.table;
      _editingKategori = null;
      _nameController.clear();
      widget.onStateChanged(_currentState);
    });
    _loadData();
  }

  Future<void> _saveKategori() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama kategori wajib diisi')),
      );
      return;
    }

    try {
      if (_editingKategori == null) {
        await widget.kategoriRepository.insertKeuanganKategori(name);
      } else {
        await widget.kategoriRepository.updateKeuanganKategori(
          KeuanganKategori(id: _editingKategori!.id, name: name),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingKategori == null
                ? 'Kategori keuangan berhasil ditambahkan'
                : 'Kategori keuangan berhasil diperbarui'),
          ),
        );
      }
      _backToTable();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan kategori: $e')),
        );
      }
    }
  }

  Future<void> _deleteKategori(KeuanganKategori kategori) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: CustomColors.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.amber, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Konfirmasi Penghapusan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: CustomColors.borderCardColor),
                  const SizedBox(height: 10),
                  Text(
                    'Hapus kategori keuangan ${kategori.name} ini?',
                    style: TextStyle(color: CustomColors.fontSubColor),
                  ),
                  const SizedBox(height: 24),
                  Divider(height: 1, color: CustomColors.borderCardColor),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: CustomColors.fontSubColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red[300],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.kategoriRepository.softDeleteKeuanganKategori(kategori.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori keuangan berhasil dihapus')),
        );
      }
      _loadData();
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
    double currentMaxHeight = _currentState == ContentState.form
        ? double.infinity
        : MediaQuery.of(context).size.height * 0.77;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            ? 'Kategori Keuangan'
                            : (_editingKategori == null
                                ? 'Tambah Kategori Keuangan'
                                : 'Edit Kategori Keuangan'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelola kategori untuk modul Keuangan',
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
              if (_currentState == ContentState.table)
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
                    'Buat Baru',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontSize: 12,
                      height: 1.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: currentMaxHeight),
            child: _currentState == ContentState.table
                ? _buildTable()
                : _buildForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        border: Border.all(color: CustomColors.borderCardColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: CustomColors.borderCardColor, width: 1),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Nama Kategori',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Aksi',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_categories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text('Tidak ada kategori keuangan',
                    style: TextStyle(color: Colors.white)),
              ),
            )
          else
            ..._categories.map((kategori) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: CustomColors.borderCardColor, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          kategori.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () => _openForm(kategori),
                              icon: const Icon(Icons.edit_outlined,
                                  size: 18, color: Color(0xFF1379F0)),
                              tooltip: 'Edit',
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              onPressed: () => _deleteKategori(kategori),
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.redAccent),
                              tooltip: 'Hapus',
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
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
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveKategori,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1379F0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  _editingKategori == null ? 'Buat Baru' : 'Simpan',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
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