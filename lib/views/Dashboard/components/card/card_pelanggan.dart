import 'package:flutter/material.dart';

class CardPelanggan extends StatefulWidget {
  const CardPelanggan({super.key});

  @override
  State<CardPelanggan> createState() => _CardPelangganState();
}

class _CardPelangganState extends State<CardPelanggan> {
  int currentPage = 1;
  final int itemsPerPage = 5;
  String? sortColumn;
  bool sortAscending = true;

  final List<Map<String, dynamic>> customerData = [
    {
      'name': 'John Doe',
      'phone': '087865771241',
      'transaction': 30000,
      'time': '05.00'
    },
    {
      'name': 'Jane Smith',
      'phone': '081234567890',
      'transaction': 25000,
      'time': '06.30'
    },
    {
      'name': 'Robert Johnson',
      'phone': '085678901234',
      'transaction': 15000,
      'time': '07.15'
    },
    {
      'name': 'Emily Davis',
      'phone': '082345678901',
      'transaction': 40000,
      'time': '08.45'
    },
    {
      'name': 'Michael Wilson',
      'phone': '089012345678',
      'transaction': 35000,
      'time': '09.30'
    },
    {
      'name': 'Sarah Brown',
      'phone': '081122334455',
      'transaction': 20000,
      'time': '10.20'
    },
    {
      'name': 'David Taylor',
      'phone': '085566778899',
      'transaction': 45000,
      'time': '11.10'
    },
    {
      'name': 'Jessica Miller',
      'phone': '081234567891',
      'transaction': 30000,
      'time': '12.00'
    },
    {
      'name': 'Thomas Anderson',
      'phone': '082345678902',
      'transaction': 25000,
      'time': '13.45'
    },
    {
      'name': 'Lisa Martinez',
      'phone': '083456789012',
      'transaction': 50000,
      'time': '14.30'
    },
  ];

  List<Map<String, dynamic>> get sortedData {
    List<Map<String, dynamic>> data = List.from(customerData);

    if (sortColumn != null) {
      data.sort((a, b) {
        final aValue = a[sortColumn!];
        final bValue = b[sortColumn!];

        if (aValue == null || bValue == null) return 0;

        if (aValue is String && bValue is String) {
          return sortAscending
              ? aValue.compareTo(bValue)
              : bValue.compareTo(aValue);
        } else if (aValue is int && bValue is int) {
          return sortAscending
              ? aValue.compareTo(bValue)
              : bValue.compareTo(aValue);
        }
        return 0;
      });
    }
    return data;
  }

  List<Map<String, dynamic>> get currentPageData {
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    return sortedData.sublist(
      startIndex,
      endIndex > sortedData.length ? sortedData.length : endIndex,
    );
  }

  void onSort(String column) {
    setState(() {
      if (sortColumn == column) {
        sortAscending = !sortAscending;
      } else {
        sortColumn = column;
        sortAscending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = sortedData.length;
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = currentPage * itemsPerPage > totalItems
        ? totalItems
        : currentPage * itemsPerPage;
    final totalPages = (totalItems / itemsPerPage).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pelanggan",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Table
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade200),
                children: [
                  _buildTableHeader('Nama & No HP', 'name'),
                  _buildTableHeader('Transaksi', 'transaction'),
                  _buildTableHeader('Waktu', 'time'),
                ],
              ),
              ...currentPageData.map((data) => TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['name']),
                            const SizedBox(height: 4),
                            Text(
                              data['phone'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Rp ${data['transaction'].toString().replaceAllMapped(
                                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                (match) => '${match[1]}.',
                              )}',
                          textAlign: TextAlign.end,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(data['time']),
                      ),
                    ],
                  )),
            ],
          ),

          // Pagination
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$startItem-$endItem of $totalItems'),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: currentPage > 1
                        ? () => setState(() => currentPage--)
                        : null,
                  ),
                  ...List.generate(totalPages > 5 ? 5 : totalPages, (index) {
                    final page = _getPageNumber(index, totalPages);
                    return page != null
                        ? TextButton(
                            onPressed: () => setState(() => currentPage = page),
                            child: Text(
                              '$page',
                              style: TextStyle(
                                color: currentPage == page
                                    ? Colors.blue
                                    : Colors.black,
                              ),
                            ),
                          )
                        : const SizedBox(width: 8);
                  }),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: currentPage < totalPages
                        ? () => setState(() => currentPage++)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String label, String column) {
    return InkWell(
      onTap: () => onSort(column),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            if (sortColumn == column)
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: Colors.blue,
              ),
          ],
        ),
      ),
    );
  }

  int? _getPageNumber(int index, int totalPages) {
    if (totalPages <= 5) return index + 1;
    if (currentPage <= 3) return index + 1 <= 5 ? index + 1 : null;
    if (currentPage >= totalPages - 2) {
      return index + totalPages - 4 <= totalPages
          ? index + totalPages - 4
          : null;
    }
    return currentPage - 2 + index;
  }
}
