import 'package:flutter/material.dart';
import 'package:meko_poin/models/kas.dart';
import 'package:meko_poin/services/kas_repository.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/content_state.dart';
import 'package:meko_poin/views/Dashboard/components/table/kas_table/kas_table.dart';
import 'package:meko_poin/views/Dashboard/components/table/kas_table/kas_detail_table.dart';
import 'package:meko_poin/views/Dashboard/components/form/kas_form.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:intl/intl.dart'; // Import untuk format currency

class KasContent extends StatefulWidget {
  final Function(ContentState) onStateChanged;
  final KasRepository kasRepository;

  const KasContent({
    super.key,
    required this.onStateChanged,
    required this.kasRepository,
  });

  @override
  State<KasContent> createState() => _KasContentState();
}

class _KasContentState extends State<KasContent> {
  ContentState _currentState = ContentState.table;
  DateTime? _selectedMonthForDetail;
  Map<String, dynamic>? _dataToEdit;
  double _totalSaldo = 0; // Variabel untuk menyimpan total saldo
  bool _isLoadingTotalSaldo = true; // Loading state untuk total saldo

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStateChanged(_currentState);
    });
    _loadTotalSaldo(); // Load total saldo saat init
  }

  void _showForm({Map<String, dynamic>? data}) {
    setState(() {
      _currentState = ContentState.form;
      _dataToEdit = data;
      widget.onStateChanged(_currentState);
    });
  }

  void _showDetail(DateTime month) {
    setState(() {
      _currentState = ContentState.detail;
      _selectedMonthForDetail = month;
      widget.onStateChanged(_currentState);
    });
  }

  void _showTable() {
    setState(() {
      _currentState = ContentState.table;
      _selectedMonthForDetail = null;
      _dataToEdit = null;
      widget.onStateChanged(_currentState);
    });
    // Refresh total saldo ketika kembali ke tabel
    _loadTotalSaldo();
  }

  // Method untuk load total saldo dari seluruh database
  Future<void> _loadTotalSaldo() async {
    if (_currentState != ContentState.table) return;

    setState(() => _isLoadingTotalSaldo = true);
    try {
      final totalSaldo = await widget.kasRepository.getTotalSaldo();
      setState(() => _totalSaldo = totalSaldo);
    } catch (e) {
      debugPrint('Error loading total saldo: $e');
    } finally {
      setState(() => _isLoadingTotalSaldo = false);
    }
  }

  Future<void> _handleDataFormSubmit(Map<String, dynamic> data) async {
    try {
      final kasData = Kas.fromMap(data);

      if (_dataToEdit == null) {
        await widget.kasRepository.insertKas(kasData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data kas berhasil ditambahkan')),
          );
        }
      } else {
        // Edit existing data
        final updatedData = Kas(
          id: _dataToEdit!['id'],
          cashDate: kasData.cashDate,
          description: kasData.description,
          amount: kasData.amount,
          type: kasData.type,
          createdBy: kasData.createdBy,
          updatedBy: kasData
              .createdBy, // Assuming updated_by should be the same as created_by for now
        );

        await widget.kasRepository.updateKas(updatedData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data kas berhasil diperbarui')),
          );
        }
      }
      // Refresh total saldo setelah menambah/mengedit data
      _loadTotalSaldo();
      _showTable();
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
    double currentMaxHeight = _currentState == ContentState.form ||
            _currentState == ContentState.detail
        ? double.infinity
        : MediaQuery.of(context).size.height * 0.77;

    // Format currency untuk total saldo
    final formattedTotalSaldo = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(_totalSaldo);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (_currentState == ContentState.form ||
                      _currentState == ContentState.detail)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _showTable,
                      color: Colors.grey.shade700,
                    ),
                  if (_currentState == ContentState.form ||
                      _currentState == ContentState.detail)
                    const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentState == ContentState.table
                            ? "Kas Tunai"
                            : (_currentState == ContentState.form
                                ? (_dataToEdit != null
                                    ? "Edit Data Kas"
                                    : "Tambah Data Kas")
                                : "Detail Kas Bulanan"),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentState == ContentState.table
                            ? "Data arus kas tunai bulanan"
                            : (_currentState == ContentState.form
                                ? (_dataToEdit != null
                                    ? "Edit data arus kas bulanan"
                                    : "Tambah data arus kas bulanan")
                                : "Detail transaksi kas bulanan"),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: CustomColors.fontSubColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Total Saldo - Hanya ditampilkan di state table
              if (_currentState == ContentState.table)
                _isLoadingTotalSaldo
                    ? SizedBox(
                        width: 120,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        'Total Saldo: $formattedTotalSaldo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
            ],
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: currentMaxHeight,
            ),
            child: _currentState == ContentState.table
                ? KasTable(
                    kasRepository: widget.kasRepository,
                    onViewDetail: _showDetail,
                    onAddNew: () => _showForm(),
                  )
                : (_currentState == ContentState.form
                    ? KasForm(
                        onCancel: _showTable,
                        initialData: _dataToEdit,
                        onSubmit: _handleDataFormSubmit,
                      )
                    : KasDetailTable(
                        kasRepository: widget.kasRepository,
                        selectedMonth: _selectedMonthForDetail!,
                        onBack: _showTable,
                        // onEdit: (data) => _showForm(data: data),
                      )),
          ),
        ],
      ),
    );
  }
}
