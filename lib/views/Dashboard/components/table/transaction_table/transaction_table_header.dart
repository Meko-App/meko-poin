import 'package:flutter/material.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class TransactionTableHeader extends StatelessWidget {
  final String sortBy;
  final bool isAscending;
  final Function(String) onSort;
  final Icon Function(String) sortIcon;
  final bool isAllSelected;
  final Function(bool?) onSelectAllChanged;

  const TransactionTableHeader({
    super.key,
    required this.sortBy,
    required this.isAscending,
    required this.onSort,
    required this.sortIcon,
    required this.isAllSelected,
    required this.onSelectAllChanged,
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
            SizedBox(
              width: 60,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: CustomColors.borderCardColor),
                  ),
                ),
                alignment: Alignment.center,
                child: Checkbox(
                  value: isAllSelected,
                  onChanged: onSelectAllChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  activeColor: Colors.blue.shade400,
                  side: const BorderSide(width: 0.4, color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => onSort('customerName'),
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
                        Expanded(
                          child: Text(
                            'Nama Pelanggan',
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                              color: CustomColors.fontSubColor,
                              fontFamily: 'Inter',
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        sortIcon('customerName'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => onSort('invoice'),
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
                          'Invoice',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: CustomColors.fontSubColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 4),
                        sortIcon('invoice'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => onSort('discount'),
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
                          'Diskon',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: CustomColors.fontSubColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 4),
                        sortIcon('discount'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => onSort('totalPrice'),
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
                          'Total',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: CustomColors.fontSubColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 4),
                        sortIcon('totalPrice'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => onSort('paymentMethod'),
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
                        Expanded(
                          child: Text(
                            'Metode Pembayaran',
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                              color: CustomColors.fontSubColor,
                              fontFamily: 'Inter',
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        sortIcon('paymentMethod'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => onSort('addedBy'),
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
                        Expanded(
                          child: Text(
                            'Ditambahkan Oleh',
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                              color: CustomColors.fontSubColor,
                              fontFamily: 'Inter',
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        sortIcon('addedBy'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => onSort('date'),
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
                        sortIcon('date'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                alignment: Alignment.center,
                child: const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
