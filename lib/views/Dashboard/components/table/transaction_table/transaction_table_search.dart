import 'package:flutter/material.dart';
import 'package:meko_poin/views/Dashboard/components/date_range_filter.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/report_service.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class TransactionTableSearch extends StatefulWidget {
  final List<dynamic> currentPageData;
  final List<dynamic> data;
  final Function(DateTime?, DateTime?) onDateRangeSelected;
  final VoidCallback onAddNew;
  final VoidCallback onPrintReport;
  final Function(String) onSearch;
  final int? user;

  const TransactionTableSearch(
      {super.key,
      required this.currentPageData,
      required this.data,
      required this.onDateRangeSelected,
      required this.onAddNew,
      required this.onPrintReport,
      required this.onSearch,
      this.user});

  @override
  State<TransactionTableSearch> createState() => _TransactionTableSearchState();
}

class _TransactionTableSearchState extends State<TransactionTableSearch> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Menampilkan ${widget.currentPageData.length} of ${widget.data.length} data',
            style: const TextStyle(
              fontSize: 14,
              height: 1.0,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 250,
                height: 34,
                child: TextField(
                  onChanged: widget.onSearch,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Inter',
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari Nama atau Invoice',
                    hintStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Inter',
                      color: CustomColors.fontSubColor,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 14,
                      color: Colors.white,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 20,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                          BorderSide(color: CustomColors.borderCardColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                          BorderSide(color: CustomColors.borderCardColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              DateRangeFilter(
                key: const ValueKey('transaction-table-date-range-filter'),
                initialStartDate: _startDate,
                initialEndDate: _endDate,
                onDateRangeSelected: (start, end) {
                  setState(() {
                    _startDate = start;
                    _endDate = end;
                  });
                  widget.onDateRangeSelected(start, end);
                },
              ),
              const SizedBox(width: 20),
              if (widget.user == 1)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1379F0), // Blue background
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    minimumSize: const Size(100, 40),
                  ),
                  onPressed: widget.onAddNew,
                  child: const Text(
                    'Tambah Baru',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontSize: 12,
                      height: 1.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(width: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0BC33F), // Green background
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: const BorderSide(color: Color(0xFF0BC33F)),
                  ),
                  minimumSize: const Size(108, 40),
                ),
                onPressed: () => ReportService.exportTransactionsToExcel(
                  transactions: widget.data,
                  reportTitle: 'Laporan Penjualan',
                  startDate: _startDate,
                  endDate: _endDate,
                  context: context,
                ),
                child: const Text(
                  'Cetak Laporan',
                  style: TextStyle(
                    color: Colors.white, // White text color
                    fontFamily: 'Inter',
                    fontSize: 12,
                    height: 1.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
