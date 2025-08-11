import 'package:flutter/material.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class InventoryLogTableHeader extends StatelessWidget {
  final String sortBy;
  final bool isAscending;
  final Function(String) onSort;
  final Icon Function(String) sortIcon;

  const InventoryLogTableHeader({
    super.key,
    required this.sortBy,
    required this.isAscending,
    required this.onSort,
    required this.sortIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            // Waktu (created_at)
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: () => onSort('createdAt'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: CustomColors.borderCardColor),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          'Tanggal',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: CustomColors.fontSubColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 4),
                        sortIcon('createdAt'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Catatan (notes)
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: () => onSort('notes'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: CustomColors.borderCardColor),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          'Aktivitas',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: CustomColors.fontSubColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 4),
                        sortIcon('notes'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Stok Awal (initialStock)
            Expanded(
              flex: 1,
              child: InkWell(
                onTap: () => onSort('initialStock'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: CustomColors.borderCardColor),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          'Stok Awal',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: CustomColors.fontSubColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 4),
                        sortIcon('initialStock'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Stok Saat Ini (currentStock)
            Expanded(
              flex: 1,
              child: InkWell(
                onTap: () => onSort('currentStock'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: CustomColors.borderCardColor),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          'Stok Akhir',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: CustomColors.fontSubColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 4),
                        sortIcon('currentStock'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Perubahan (difference)
            Expanded(
              flex: 1,
              child: InkWell(
                onTap: () => onSort('difference'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  // No right border for the last column
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          'Selisih',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: CustomColors.fontSubColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 4),
                        sortIcon('difference'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
