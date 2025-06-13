import 'package:flutter/material.dart';

class CardGudang extends StatefulWidget {
  const CardGudang({super.key});

  @override
  State<CardGudang> createState() => _CardGudangState();
}

class _CardGudangState extends State<CardGudang> {
  int currentPage = 1;
  final int itemsPerPage = 4;

  List<Map<String, dynamic>> data = [
    {
      'item': '4R MATTE',
      'description': 'Penambahan Stok Sebesar 2',
      'change': 2,
      'type': 'increase'
    },
    {
      'item': 'KEYCHAIN KOTAK',
      'description': 'Pengurangan Stok Sebesar 7',
      'change': 7,
      'type': 'decrease'
    },
    {
      'item': 'KEYCHAIN PERSECI',
      'description':
          'Transaksi pada 5 Juni 2025, 05.00 dengan pengurangan sebesar 8',
      'change': 8,
      'type': 'decrease'
    },
    {
      'item': 'STRIPE GLOSSY',
      'description':
          'Transaksi pada 5 Juni 2025, 05.00 dengan pengurangan sebesar 2',
      'change': 2,
      'type': 'decrease'
    },
    {
      'item': 'STRIPE GLOSSY',
      'description':
          'Transaksi pada 5 Juni 2025, 05.00 dengan pengurangan sebesar 2',
      'change': 2,
      'type': 'decrease'
    },
    {
      'item': '4R GLOSSY',
      'description': 'Penambahan Stok Sebesar 5',
      'change': 5,
      'type': 'increase'
    },
    {
      'item': 'KEYCHAIN BULAT',
      'description': 'Pengurangan Stok Sebesar 3',
      'change': 3,
      'type': 'decrease'
    },
  ];

  String sortBy = 'item'; // default sort
  bool isAscending = true;

  List<Map<String, dynamic>> get sortedData {
    List<Map<String, dynamic>> sorted = List.from(data);
    sorted.sort((a, b) {
      dynamic valueA = a[sortBy];
      dynamic valueB = b[sortBy];

      int result = valueA.toString().compareTo(valueB.toString());
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

  @override
  Widget build(BuildContext context) {
    final totalPages = (data.length / itemsPerPage).ceil();
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage > data.length)
        ? data.length
        : currentPage * itemsPerPage;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Gudang',
            style: TextStyle(
              fontSize: 16,
              height: 1.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111B37),
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 16),

          // Table Header
          Container(
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
                  // Kolom Item
                  Expanded(
                    child: InkWell(
                      onTap: () => onSort('item'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                              right: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text('Item',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF4B5675),
                                    fontFamily: 'Inter',
                                  )),
                              const SizedBox(width: 4),
                              _sortIcon('item'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Kolom Deskripsi
                  Expanded(
                    child: InkWell(
                      onTap: () => onSort('description'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                              right: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                'Deskripsi',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF4B5675),
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(width: 4),
                              _sortIcon('description'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Kolom Perubahan
                  Expanded(
                    child: InkWell(
                      onTap: () => onSort('change'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                'Perubahan',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF4B5675),
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(width: 4),
                              _sortIcon('change'),
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
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Kolom Item
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18.0, vertical: 18.0),
                          child: Text(
                            row['item'],
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.1,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF27314B),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                      VerticalDivider(
                          thickness: 1, width: 1, color: Colors.grey[300]),

                      // Kolom Deskripsi
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18.0, vertical: 18.0),
                          child: Text(
                            row['description'],
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.1,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF27314B),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                      VerticalDivider(
                          thickness: 1, width: 1, color: Colors.grey[300]),

                      // Kolom Perubahan
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18.0, vertical: 18.0),
                          child: Row(
                            children: [
                              Icon(
                                row['type'] == 'increase'
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: row['type'] == 'increase'
                                    ? Colors.green
                                    : Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                row['change'].toString(),
                                style: TextStyle(
                                    fontSize: 14,
                                    height: 1.1,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'Inter',
                                    color: row['type'] == 'increase'
                                        ? Colors.green
                                        : Colors.red),
                              ),
                            ],
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
                      fontSize: 13,
                      height: 14 / 13,
                      color: Color(0xFF4B5675),
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
                      icon: Transform.rotate(
                        angle: 3.1416,
                        child: const Icon(
                          Icons.arrow_right_alt,
                          size: 18,
                        ),
                      ),
                      color:
                          currentPage > 1 ? Colors.black : Colors.grey.shade400,
                    ),
                    ...List.generate(totalPages, (index) {
                      final page = index + 1;
                      final isActive = currentPage == page;
                      return MouseRegion(
                        cursor: SystemMouseCursors.click, // pointer saat hover
                        child: GestureDetector(
                          onTap: () => setState(() => currentPage = page),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Color(0xFFE6E8F0)
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
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    IconButton(
                      onPressed: currentPage < totalPages
                          ? () => setState(() => currentPage++)
                          : null,
                      icon: const Icon(
                        Icons.arrow_right_alt,
                        size: 18,
                      ),
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
