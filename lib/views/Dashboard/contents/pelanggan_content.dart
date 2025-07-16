import 'package:flutter/material.dart';
import 'package:meko_poin/services/customer_repository.dart';
import 'package:meko_poin/views/Dashboard/components/table/customer_table/customer_table.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/content_state.dart';

class PelangganContent extends StatefulWidget {
  final CustomerRepository customerRepository;

  const PelangganContent({super.key, required this.customerRepository});

  @override
  State<PelangganContent> createState() => _PenggunaContentState();
}

class _PenggunaContentState extends State<PelangganContent> {
  ContentState _currentState = ContentState.table;
  late final CustomerRepository customerRepository;

  @override
  void initState() {
    super.initState();
    customerRepository = widget.customerRepository;
  }

  void _showTable() {
    setState(() {
      _currentState = ContentState.table;
    });
  }

  @override
  Widget build(BuildContext context) {
    double currentMaxHeight = _currentState == ContentState.table
        ? MediaQuery.of(context).size.height * 0.77
        : double.infinity;

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
                    "Pelanggan",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Data ringkasan pelanggan",
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
              child: CustomerTable(
                customerRepository: customerRepository,
              )),
        ],
      ),
    );
  }
}
