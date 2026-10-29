import 'package:flutter/material.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class KasDetailTablePagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int startItem;
  final int endItem;
  final List<dynamic> data;
  final int itemsPerPage;
  final Function(int) onItemsPerPageChanged;
  final Function(int) onPageChanged;

  const KasDetailTablePagination({
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

  Widget _buildPaginationInfo() {
    return Text(
      '$startItem-$endItem dari ${data.length}',
      style: const TextStyle(
        fontSize: 13,
        color: CustomColors.fontSubColor,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildPageButton(int page) {
    final isActive = currentPage == page;
    return GestureDetector(
      onTap: () => onPageChanged(page),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? CustomColors.borderCardColor : Colors.transparent,
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
  }

  Widget _buildRightControls() {
    final visiblePages = _buildVisiblePages();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPaginationInfo(),
        const SizedBox(width: 16),
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
          return _buildPageButton(page);
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

  Widget _buildLeftControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Tampil',
          style: TextStyle(
            fontSize: 13,
            color: CustomColors.fontSubColor,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: CustomColors.inputColor,
            border: Border.all(color: CustomColors.borderInputColor, width: 1),
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
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: CustomColors.fontSubColor,
              ),
              dropdownColor: CustomColors.inputColor,
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
                        color: Colors.white,
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
            color: CustomColors.fontSubColor,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 980;

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLeftControls(),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildRightControls(),
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLeftControls(),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildRightControls(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
