import 'package:flutter/material.dart';
import 'package:meko_poin/models/kas.dart';
import 'package:meko_poin/services/kas_repository.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/content_state.dart';
import 'package:meko_poin/views/Dashboard/components/table/kas_table/kas_table.dart';
import 'package:meko_poin/views/Dashboard/components/table/kas_detail_table/kas_detail_table.dart';
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

enum FormOrigin { fromTable, fromDetail }

class _KasContentState extends State<KasContent> {
  ContentState _currentState = ContentState.table;
  DateTime? _selectedMonthForDetail;
  Map<String, dynamic>? _dataToEdit;
  double _totalSaldo = 0;
  bool _isLoadingTotalSaldo = true;
  String? _selectedMonthName;
  int? _selectedMonth;
  int? _selectedYear;
  FormOrigin _formOrigin = FormOrigin.fromTable;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStateChanged(_currentState);
    });
    _loadTotalSaldo(); // Load total saldo saat init
  }

  void _showForm(
      {Map<String, dynamic>? data, FormOrigin origin = FormOrigin.fromTable}) {
    setState(() {
      _currentState = ContentState.form;
      _dataToEdit = data;
      _formOrigin = origin;
      widget.onStateChanged(_currentState);
    });
  }

  void _showDetail(DateTime month) {
    setState(() {
      _currentState = ContentState.detailKas;
      _selectedMonthForDetail = month;
      _selectedMonthName = _getMonthName(month);
      _selectedMonth = int.tryParse(_getMonth(month));
      _selectedYear = int.tryParse(_getYear(month));
      _formOrigin = FormOrigin.fromTable;
      widget.onStateChanged(_currentState);
    });

    _loadTotalSaldo();
  }

  void _showTable() {
    setState(() {
      _currentState = ContentState.table;
      _selectedMonthForDetail = null;
      _dataToEdit = null;
      _selectedMonthName = null;
      widget.onStateChanged(_currentState);
    });

    _loadTotalSaldo();
  }

  String _getMonthName(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  String _getMonth(DateTime date) {
    return DateFormat('M', 'id_ID').format(date);
  }

  String _getYear(DateTime date) {
    return DateFormat('yyyy', 'id_ID').format(date);
  }

  Future<void> _loadTotalSaldo() async {
    if (_currentState != ContentState.table &&
        _currentState != ContentState.detailKas) {
      return;
    }

    setState(() => _isLoadingTotalSaldo = true);
    try {
      if (_currentState == ContentState.table) {
        final totalSaldo = await widget.kasRepository.getTotalSaldo();
        setState(() => _totalSaldo = totalSaldo);
      } else if (_currentState == ContentState.detailKas) {
        final totalSaldo = await widget.kasRepository
            .getTotalSaldoBulanan(_selectedYear!, _selectedMonth!);
        setState(() => _totalSaldo = totalSaldo);
      }
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
          updatedBy: kasData.createdBy,
        );

        await widget.kasRepository.updateKas(updatedData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data kas berhasil diperbarui')),
          );
        }
      }

      _loadTotalSaldo();

      if (_formOrigin == FormOrigin.fromDetail) {
        _showDetail(_selectedMonthForDetail!);
      } else {
        _showTable();
      }
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
    double currentMaxHeight = _currentState == ContentState.form
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
                      _currentState == ContentState.detailKas)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        if (_currentState == ContentState.form) {
                          if (_formOrigin == FormOrigin.fromDetail) {
                            _showDetail(_selectedMonthForDetail!);
                          } else {
                            _showTable();
                          }
                        } else {
                          _showTable();
                        }
                      },
                      color: Colors.grey.shade700,
                    ),
                  if (_currentState == ContentState.form ||
                      _currentState == ContentState.detailKas)
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
                                : "Detail Kas Tunai"),
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
                                : "Data arus kas tunai $_selectedMonthName"),
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
              if (_currentState == ContentState.table ||
                  _currentState == ContentState.detailKas)
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
                    onAddNew: () => _showForm(origin: FormOrigin.fromTable),
                  )
                : (_currentState == ContentState.form
                    ? KasForm(
                        onCancel: () {
                          if (_formOrigin == FormOrigin.fromDetail) {
                            _showDetail(_selectedMonthForDetail!);
                          } else {
                            _showTable();
                          }
                        },
                        initialData: _dataToEdit,
                        onSubmit: _handleDataFormSubmit,
                      )
                    : KasDetailTable(
                        kasRepository: widget.kasRepository,
                        selectedMonth: _selectedMonthForDetail!,
                        onBack: _showTable,
                        onEdit: (data) => _showForm(
                            data: data, origin: FormOrigin.fromDetail),
                        onAddNew: () =>
                            _showForm(origin: FormOrigin.fromDetail),
                      )),
          ),
        ],
      ),
    );
  }
}
