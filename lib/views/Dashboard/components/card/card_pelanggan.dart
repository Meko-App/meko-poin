import 'package:flutter/material.dart';

class CardPelanggan extends StatefulWidget {
  const CardPelanggan({super.key});

  @override
  State<CardPelanggan> createState() => _CardPelangganState();
}

class _CardPelangganState extends State<CardPelanggan> {
  int currentPage = 1;
  final int itemsPerPage = 5;

  List<Map<String, dynamic>> data = [
    {
      'name': 'John Doe',
      'phone': '087865771241',
      'transaction': 30000,
      'time': '05.00'
    },
    {
      'name': 'Alice Smith',
      'phone': '081234567890',
      'transaction': 25000,
      'time': '06.00'
    },
    {
      'name': 'Bob Johnson',
      'phone': '089876543210',
      'transaction': 15000,
      'time': '04.30'
    },
    {
      'name': 'Charlie Brown',
      'phone': '082345678912',
      'transaction': 20000,
      'time': '08.00'
    },
    {
      'name': 'Diana Ross',
      'phone': '087777777777',
      'transaction': 35000,
      'time': '07.15'
    },
    {
      'name': 'John Legend',
      'phone': '081122334455',
      'transaction': 32000,
      'time': '05.45'
    },
    {
      'name': 'John Doe',
      'phone': '087865771241',
      'transaction': 30000,
      'time': '05.00'
    },
    {
      'name': 'Alice Smith',
      'phone': '081234567890',
      'transaction': 25000,
      'time': '06.00'
    },
    {
      'name': 'Bob Johnson',
      'phone': '089876543210',
      'transaction': 15000,
      'time': '04.30'
    },
    {
      'name': 'Charlie Brown',
      'phone': '082345678912',
      'transaction': 20000,
      'time': '08.00'
    },
    {
      'name': 'Diana Ross',
      'phone': '087777777777',
      'transaction': 35000,
      'time': '07.15'
    },
    {
      'name': 'John Legend',
      'phone': '081122334455',
      'transaction': 32000,
      'time': '05.45'
    },
  ];

  String sortBy = 'name'; // default sort
  bool isAscending = true;

  List<Map<String, dynamic>> get sortedData {
    List<Map<String, dynamic>> sorted = List.from(data);
    sorted.sort((a, b) {
      dynamic valueA = a[sortBy];
      dynamic valueB = b[sortBy];

      int result;
      if (valueA is int) {
        result = valueA.compareTo(valueB);
      } else if (valueA is String &&
          RegExp(r'^\d{2}\.\d{2}$').hasMatch(valueA)) {
        // Convert time "05.00" -> 500 for comparison
        result = int.parse(valueA.replaceAll('.', ''))
            .compareTo(int.parse(valueB.replaceAll('.', '')));
      } else {
        result = valueA.toString().compareTo(valueB.toString());
      }

      return isAscending ? result : -result;
    });
    return sorted;
  }

  List<Map<String, dynamic>> get currentPageData {
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    return sortedData.sublist(
        start, end > sortedData.length ? sortedData.length : end);
  }

  void onSort(String column) {
    setState(() {
      if (sortBy == column) {
        isAscending = !isAscending;
      } else {
        sortBy = column;
        isAscending = true;
      }
    });
  }

  Icon _sortIcon(String column) {
    if (sortBy != column) return const Icon(Icons.unfold_more, size: 14);
    return Icon(
      isAscending ? Icons.arrow_upward : Icons.arrow_downward,
      size: 14,
    );
  }

  String _formatCurrency(int value) {
    return value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (data.length / itemsPerPage).ceil();
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage > data.length)
        ? data.length
        : currentPage * itemsPerPage;

    return Container(
      // margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Pelanggan',
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 20, fontFamily: 'Inter'),
          ),
          const SizedBox(height: 16),

          // Table Header
          Container(
            // padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Kolom Nama
                  Expanded(
                    child: InkWell(
                      onTap: () => onSort('name'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text('Nama',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 18,
                                      fontFamily: 'Inter')),
                              const SizedBox(width: 4),
                              _sortIcon('name'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Kolom Transaksi
                  Expanded(
                    child: InkWell(
                      onTap: () => onSort('transaction'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text('Transaksi',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 18,
                                      fontFamily: 'Inter')),
                              const SizedBox(width: 4),
                              _sortIcon('transaction'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Kolom Jam (tanpa border kanan)
                  Expanded(
                    child: InkWell(
                      onTap: () => onSort('time'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text('Jam',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 18,
                                      fontFamily: 'Inter')),
                              const SizedBox(width: 4),
                              _sortIcon('time'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Table Rows
          ...currentPageData.map((row) => Container(
                // padding:
                //     const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row['name'],
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Inter'),
                              ),
                              Text(
                                row['phone'],
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                    fontFamily: 'Inter'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      VerticalDivider(
                          thickness: 1, width: 1, color: Colors.grey[300]),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18.0, vertical: 8.0),
                          child: Text(
                            'Rp ${_formatCurrency(row['transaction'])}',
                            style: TextStyle(fontSize: 16, fontFamily: 'Inter'),
                          ),
                        ),
                      ),
                      VerticalDivider(
                          thickness: 1, width: 1, color: Colors.grey[300]),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18.0, vertical: 8.0),
                          child: Text(
                            row['time'],
                            style: TextStyle(fontSize: 16, fontFamily: 'Inter'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),

          // Pagination
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$startItem-$endItem of ${data.length}',
                  style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400),
                ),
                const SizedBox(width: 20),
                Row(
                  children: [
                    IconButton(
                      onPressed: currentPage > 1
                          ? () => setState(() => currentPage--)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      color:
                          currentPage > 1 ? Colors.black : Colors.grey.shade400,
                    ),
                    ...List.generate(totalPages, (index) {
                      final page = index + 1;
                      final isActive = currentPage == page;
                      return GestureDetector(
                        onTap: () => setState(() => currentPage = page),
                        child: Container(
                          // margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.grey.shade300
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$page',
                            style: TextStyle(
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14,
                                fontFamily: 'Inter'),
                          ),
                        ),
                      );
                    }),
                    IconButton(
                      onPressed: currentPage < totalPages
                          ? () => setState(() => currentPage++)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                      color: currentPage < totalPages
                          ? Colors.black
                          : Colors.grey.shade400,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
