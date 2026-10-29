import 'package:flutter/material.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class CardTablePagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int startItem;
  final int endItem;
  final int totalItems;
  final int itemsPerPage;
  final ValueChanged<int> onItemsPerPageChanged;
  final ValueChanged<int> onPageChanged;

  const CardTablePagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.startItem,
    required this.endItem,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onItemsPerPageChanged,
    required this.onPageChanged,
  });

  List<int?> _buildVisiblePages() {
    if (totalPages <= 7) {
      return List<int?>.generate(totalPages, (index) => index + 1);
    }

    final pages = <int>{1, totalPages, currentPage};
    if (currentPage > 1) pages.add(currentPage - 1);
    if (currentPage < totalPages) pages.add(currentPage + 1);

    final sortedPages = pages.toList()..sort();
    final visiblePages = <int?>[];

    for (int i = 0; i < sortedPages.length; i++) {
      if (i > 0 && sortedPages[i] - sortedPages[i - 1] > 1) {
        visiblePages.add(null);
      }
      visiblePages.add(sortedPages[i]);
    }

    return visiblePages;
  }

  Widget _buildRightControls() {
    final visiblePages = _buildVisiblePages();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$startItem-$endItem dari $totalItems',
          style: const TextStyle(
            fontSize: 13,
            color: CustomColors.fontSubColor,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed:
              currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          icon: Transform.rotate(
            angle: 3.1416,
            child: Icon(
              Icons.arrow_right_alt,
              size: 18,
              color: currentPage > 1 ? Colors.white : CustomColors.fontSubColor,
            ),
          ),
        ),
        ...visiblePages.map((page) {
          if (page == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '...',
                style: TextStyle(
                  fontSize: 14,
                  color: CustomColors.fontSubColor,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final isActive = currentPage == page;
          return GestureDetector(
            onTap: () => onPageChanged(page),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? CustomColors.borderCardColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$page',
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  color: isActive ? Colors.white : CustomColors.fontSubColor,
                ),
              ),
            ),
          );
        }),
        IconButton(
          onPressed: currentPage < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
          icon: Icon(
            Icons.arrow_right_alt,
            size: 18,
            color: currentPage < totalPages
                ? Colors.white
                : CustomColors.fontSubColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 560;

          if (isNarrow) {
            return Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildRightControls(),
              ),
            );
          }

          return Align(
            alignment: Alignment.centerRight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildRightControls(),
            ),
          );
        },
      ),
    );
  }
}
