import 'package:flutter/material.dart';
import 'package:meko_poin/models/additional/master_data_with_user.dart';

class MasterDataTablePagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int startItem;
  final int endItem;
  final List<MasterDataWithUser> data;
  final int itemsPerPage;
  final Function(int) onItemsPerPageChanged;
  final Function(int) onPageChanged;

  const MasterDataTablePagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.startItem,
    required this.endItem,
    required this.data,
    required this.itemsPerPage,
    required this.onItemsPerPageChanged,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              const Text(
                'Tampil',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4B5675),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: itemsPerPage,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4B5675),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16, color: Color(0xFF4B5675)),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    elevation: 4,
                    onChanged: (value) {
                      onItemsPerPageChanged(value!);
                    },
                    items: [10, 20, 50, 100].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '$value',
                            style: TextStyle(
                              color: itemsPerPage == value
                                  ? const Color(0xFF4B5675)
                                  : const Color(0xFF6B7280),
                              fontWeight: itemsPerPage == value
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'per halaman',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4B5675),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '$startItem-$endItem dari ${data.length}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4B5675),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: currentPage > 1
                    ? () => onPageChanged(currentPage - 1)
                    : null,
                icon: Transform.rotate(
                  angle: 3.1416,
                  child: const Icon(Icons.arrow_right_alt, size: 18),
                ),
                color: currentPage > 1 ? Colors.black : Colors.grey.shade400,
              ),
              ...List.generate(totalPages, (index) {
                final page = index + 1;
                final isActive = currentPage == page;
                return GestureDetector(
                  onTap: () => onPageChanged(page),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFE6E8F0)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$page',
                      style: TextStyle(
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                );
              }),
              IconButton(
                onPressed: currentPage < totalPages
                    ? () => onPageChanged(currentPage + 1)
                    : null,
                icon: const Icon(Icons.arrow_right_alt, size: 18),
                color: currentPage < totalPages
                    ? Colors.black
                    : Colors.grey.shade400,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
