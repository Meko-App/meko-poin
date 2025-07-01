import 'package:flutter/material.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:meko_poin/views/Dashboard/components/table/transaction_table/transaction_table.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/content_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      _currentState = ContentState.form;
      widget.onStateChanged(_currentState);
    });
  }

  void _showTable() {
    setState(() {
      _currentState = ContentState.table;
      widget.onStateChanged(_currentState);
    });
  }

  void _showDetail(int transactionId) {
    // Implement detail view navigation if needed
    // For now we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing details for transaction $transactionId')),
    );
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
              if (_currentState == ContentState.form)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _showTable,
                  color: Colors.grey.shade700,
                ),
              if (_currentState == ContentState.form) const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentState == ContentState.table
                        ? "Transaksi"
                        : "Tambah Data Transaksi",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentState == ContentState.table
                        ? "Data transaksi penjualan dan pembelian"
                        : "Form untuk menambah data transaksi",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade700,
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
                : Container(), // Replace with your TransactionForm when available
          ),
        ],
      ),
    );
  }
}
