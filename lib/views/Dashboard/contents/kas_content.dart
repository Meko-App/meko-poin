import 'package:flutter/material.dart';
import 'package:meko_poin/models/kas.dart';
import 'package:meko_poin/services/kas_repository.dart';
import 'package:meko_poin/services/keuangan_kategori_repository.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/content_state.dart';
import 'package:meko_poin/views/Dashboard/components/table/kas_table/kas_table.dart';
import 'package:meko_poin/views/Dashboard/components/table/kas_detail_table/kas_detail_table.dart';
import 'package:meko_poin/views/Dashboard/components/form/kas_form.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import untuk format currency

class KasContent extends StatefulWidget {
  final Function(ContentState) onStateChanged;
  final KasRepository kasRepository;
  final KeuanganKategoriRepository kategoriRepository;
  final int? user;

  const KasContent(
      {super.key,
      required this.onStateChanged,
      required this.kasRepository,
      required this.kategoriRepository,
      this.user});

  @override
  State<KasContent> createState() => _KasContentState();
}

enum FormOrigin { fromTable, fromDetail }

class _KasContentState extends State<KasContent> {
  ContentState _currentState = ContentState.table;
  DateTime? _selectedMonthForDetail;
  Map<String, dynamic>? _dataToEdit;
  double _totalSaldo = 0;
  int _totalCash = 0;
  int _totalSaldoVariable = 0;
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
      final totalCash = await widget.kasRepository.getTotalCash();
      final totalSaldoVariable =
          await widget.kasRepository.getTotalSaldoVariable();

      if (_currentState == ContentState.table) {
        final totalKeuangan =
            await widget.kasRepository.getTotalKeuangan();
        setState(() {
          _totalCash = totalCash;
          _totalSaldoVariable = totalSaldoVariable;
          _totalSaldo = totalKeuangan.toDouble();
        });
      } else if (_currentState == ContentState.detailKas) {
        final totalKeuangan = await widget.kasRepository
            .getTotalSaldoBulanan(_selectedYear!, _selectedMonth!);
        setState(() {
          _totalCash = totalCash;
          _totalSaldoVariable = totalSaldoVariable;
          _totalSaldo = totalKeuangan;
        });
      }
    } catch (e) {
      debugPrint('Error loading total saldo: $e');
    } finally {
      setState(() => _isLoadingTotalSaldo = false);
    }
  }

  Future<void> _handleDataFormSubmit(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId') ?? 0;

      if (data['type'] == 'transfer') {
        await widget.kasRepository.transferKas(
          amount: data['amount'] as int,
          description: data['description'] as String,
          fromVariable: data['from_variable'] as String,
          toVariable: data['to_variable'] as String,
          cashDate: DateTime.parse(data['cash_date'] as String),
          categoryId: data['category_id'] as int?,
          userId: userId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transfer keuangan berhasil')),
          );
        }
      } else if (_dataToEdit == null) {
        final kasData = Kas.fromMap(data);
        await widget.kasRepository.insertKas(kasData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data keuangan berhasil ditambahkan')),
          );
        }
      } else {
        final kasData = Kas.fromMap(data);

        final updatedData = Kas(
          id: _dataToEdit!['id'],
          cashDate: kasData.cashDate,
          description: kasData.description,
          amount: kasData.amount,
          type: kasData.type,
          variable: _dataToEdit!['variable'] ?? kasData.variable,
          categoryId: kasData.categoryId,
          updatedBy: userId,
        );

        await widget.kasRepository.updateKas(updatedData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data keuangan berhasil diperbarui')),
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
                            ? "Keuangan"
                            : (_currentState == ContentState.form
                                ? (_dataToEdit != null
                                    ? "Edit Data Keuangan"
                                    : "Tambah Data Keuangan")
                                : "Detail Keuangan"),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentState == ContentState.table
                            ? "Data arus keuangan bulanan"
                            : (_currentState == ContentState.form
                                ? (_dataToEdit != null
                                    ? "Edit data arus keuangan bulanan"
                                    : "Tambah data arus keuangan bulanan")
                                : "Data arus keuangan $_selectedMonthName"),
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

              // Total Keuangan - Hanya ditampilkan di state table
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
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Cash: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_totalCash)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: CustomColors.fontSubColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Saldo: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_totalSaldoVariable)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: CustomColors.fontSubColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total Keuangan: $formattedTotalSaldo',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
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
                        user: widget.user,
                        kasRepository: widget.kasRepository,
                        kategoriRepository: widget.kategoriRepository,
                      )
                    : KasDetailTable(
                        kasRepository: widget.kasRepository,
                        selectedMonth: _selectedMonthForDetail!,
                        canEdit: widget.user != 2,
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
