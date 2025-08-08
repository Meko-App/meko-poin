import 'package:flutter/material.dart';
import 'package:meko_poin/models/additional/log_inventory_with_master_data.dart';
// import 'package:meko_poin/models/inventory_log.dart';
import 'package:meko_poin/services/inventory_log_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class CardGudang extends StatefulWidget {
  final InventoryLogRepository inventoryLogRepo;

  const CardGudang({super.key, required this.inventoryLogRepo});

  @override
  State<CardGudang> createState() => _CardGudangState();
}

class _CardGudangState extends State<CardGudang> {
  int currentPage = 1;
  final int itemsPerPage = 4;
  List<LogInventoryWithMasterData> logs = [];
  bool isLoading = true;
  String errorMessage = '';
  String sortBy = 'item'; // default sort
  bool isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Menggunakan method baru untuk ambil data hari ini
      final results = await widget.inventoryLogRepo.getTodayInventoryLogs();

      setState(() {
        logs = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat data: ${e.toString()}';
      });
    }
  }

  List<LogInventoryWithMasterData> get sortedLogs {
    List<LogInventoryWithMasterData> sorted = List.from(logs);
    sorted.sort((a, b) {
      int result;
      switch (sortBy) {
        case 'item':
          result = a.productName.compareTo(b.productName);
          break;
        case 'description':
          result = a.inventoryLog.notes.compareTo(b.inventoryLog.notes);
          break;
        case 'change':
          result =
              a.inventoryLog.difference.compareTo(b.inventoryLog.difference);
          break;
        default:
          result = a.productName.compareTo(b.productName);
      }
      return isAscending ? result : -result;
    });
    return sorted;
  }

  List<LogInventoryWithMasterData> get currentPageData {
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    return sortedLogs.sublist(
        start, end > sortedLogs.length ? sortedLogs.length : end);
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
    if (sortBy != column) {
      return const Icon(
        Icons.unfold_more,
        size: 14,
        color: CustomColors.fontSubColor,
      );
    }
    return Icon(
      isAscending ? Icons.arrow_upward : Icons.arrow_downward,
      size: 14,
      color: CustomColors.fontSubColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    const double cardHeight = 365;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }

    final totalPages = (logs.length / itemsPerPage).ceil();
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage > logs.length)
        ? logs.length
        : currentPage * itemsPerPage;

    return Container(
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        border: Border.all(color: CustomColors.borderCardColor),
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: BoxConstraints(
        minHeight: cardHeight,
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
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 16),

          // Table Header
          Container(
            decoration: BoxDecoration(
              color: CustomColors.cardColor,
              border: Border(
                top: BorderSide(color: CustomColors.borderCardColor),
                bottom: BorderSide(color: CustomColors.borderCardColor),
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
                              right: BorderSide(
                                  color: CustomColors.borderCardColor)),
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
                                    color: CustomColors.fontSubColor,
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
                              right: BorderSide(
                                  color: CustomColors.borderCardColor)),
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
                                  color: CustomColors.fontSubColor,
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
                                  color: CustomColors.fontSubColor,
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

          if (logs.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: const Center(
                child: Text(
                  'Tidak ada data update stok hari ini',
                  style: TextStyle(
                    fontSize: 14,
                    color: CustomColors.fontSubColor,
                  ),
                ),
              ),
            )
          else
            ...currentPageData.map((log) => Container(
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: CustomColors.borderCardColor)),
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
                              log.productName,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.1,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                        VerticalDivider(
                            thickness: 1,
                            width: 1,
                            color: CustomColors.borderCardColor),

                        // Kolom Deskripsi
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18.0, vertical: 18.0),
                            child: Text(
                              log.inventoryLog.notes,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.1,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                        VerticalDivider(
                            thickness: 1,
                            width: 1,
                            color: CustomColors.borderCardColor),

                        // Kolom Perubahan
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18.0, vertical: 18.0),
                            child: Row(
                              children: [
                                Icon(
                                  log.inventoryLog.type == 'increment'
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: log.inventoryLog.type == 'increment'
                                      ? Colors.green
                                      : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(log.inventoryLog.difference.toString(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.1,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'Inter',
                                      color: Colors.white,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),

          // Pagination
          if (logs.length > 4)
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$startItem-$endItem of ${logs.length}',
                    style: TextStyle(
                        fontSize: 13,
                        height: 14 / 13,
                        color: CustomColors.fontSubColor,
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
                          child: Icon(Icons.arrow_right_alt,
                              size: 18,
                              color: currentPage > 1
                                  ? Colors.white
                                  : CustomColors.fontSubColor),
                        ),
                      ),
                      ...List.generate(totalPages, (index) {
                        final page = index + 1;
                        final isActive = currentPage == page;
                        return MouseRegion(
                          cursor:
                              SystemMouseCursors.click, // pointer saat hover
                          child: GestureDetector(
                            onTap: () => setState(() => currentPage = page),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? CustomColors.borderCardColor
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
                                  color: isActive
                                      ? Colors.white
                                      : CustomColors.fontSubColor,
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
                        icon: Icon(Icons.arrow_right_alt,
                            size: 18,
                            color: currentPage < totalPages
                                ? Colors.white
                                : CustomColors.fontSubColor),
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
