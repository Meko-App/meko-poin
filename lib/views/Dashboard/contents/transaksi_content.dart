import 'package:flutter/material.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:meko_poin/views/Dashboard/components/detail/transaction_detail.dart';
import 'package:meko_poin/views/Dashboard/components/form/transaction_form.dart';
import 'package:meko_poin/views/Dashboard/components/table/transaction_table/transaction_table.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/content_state.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class TransaksiContent extends StatefulWidget {
  final Function(ContentState) onStateChanged;
  final TransactionRepository transactionRepository;

  const TransaksiContent({
    super.key,
    required this.onStateChanged,
    required this.transactionRepository,
  });

  @override
  State<TransaksiContent> createState() => _TransaksiContentState();
}

class _TransaksiContentState extends State<TransaksiContent> {
  ContentState _currentState = ContentState.table;
  late final TransactionRepository transactionRepository;
  int? _selectedTransactionId;

  @override
  void initState() {
    super.initState();
    transactionRepository = widget.transactionRepository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStateChanged(_currentState);
    });
  }

  void _showForm() {
    setState(() {
      _selectedTransactionId = null;
      _currentState = ContentState.form;
      widget.onStateChanged(_currentState);
    });
  }

  void _showTable() {
    setState(() {
      _selectedTransactionId = null;
      _currentState = ContentState.table;
      widget.onStateChanged(_currentState);
    });
  }

  void _showDetail(int transactionId) {
    setState(() {
      _currentState = ContentState.detail;
      _selectedTransactionId = transactionId;
      widget.onStateChanged(_currentState);
    });
  }

  Future<void> _printReport() async {
    // Implement print report functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating report...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    double currentMaxHeight = _currentState == ContentState.form
        ? double.infinity
        : MediaQuery.of(context).size.height * 0.77;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                        ? "Transaksi"
                        : _currentState == ContentState.detail
                            ? "Detail Transaksi"
                            : "Tambah Data Transaksi",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentState == ContentState.table
                        ? "Data untuk mengelola transaksi"
                        : _currentState == ContentState.detail
                            ? "Menampilkan detail data transaksi"
                            : "Form untuk menambah data transaksi",
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
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: currentMaxHeight,
            ),
            child: _currentState == ContentState.table
                ? TransactionTable(
                    transactionRepository: transactionRepository,
                    onViewDetail: _showDetail,
                    onAddNew: _showForm,
                    onPrintReport: _printReport,
                  )
                : _currentState == ContentState.detail
                    ? TransactionDetail(
                        transactionId: _selectedTransactionId!,
                        transactionRepository: transactionRepository,
                        onBackPressed: _showTable, // Tambahkan ini
                      )
                    : TransactionForm(
                        onCancel: _showTable,
                        onSubmit: (p0) {},
                        onSuccess: _showTable,
                      ),
          ),
        ],
      ),
    );
  }
}
