import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meko_poin/models/transaction.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class TransactionTableRow extends StatelessWidget {
  final Transaction transaction;
  final String customerName;
  final String customerPhone;
  final String discountDisplay;
  final String addedBy;
  final VoidCallback onViewDetail;
  final bool isSelected;
  final Function(bool?) onSelectChanged;

  const TransactionTableRow({
    super.key,
    required this.transaction,
    required this.customerName,
    required this.customerPhone,
    required this.discountDisplay,
    required this.addedBy,
    required this.onViewDetail,
    required this.isSelected,
    required this.onSelectChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm:ss');
    final amountFormat = NumberFormat('#,###');

    return Container(
      constraints: const BoxConstraints(minHeight: 55),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: CustomColors.borderCardColor)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            SizedBox(
              width: 59,
              child: Checkbox(
                value: isSelected,
                onChanged: onSelectChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                activeColor: Colors.blue.shade400,
                side: const BorderSide(width: 0.4, color: Colors.grey),
              ),
            ),
            VerticalDivider(
                thickness: 1, width: 1, color: CustomColors.borderCardColor),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      customerPhone,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w400,
                        color: CustomColors.fontSubColor,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            VerticalDivider(
                thickness: 1, width: 1, color: CustomColors.borderCardColor),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  discountDisplay,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            VerticalDivider(
                thickness: 1, width: 1, color: CustomColors.borderCardColor),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  'Rp ${amountFormat.format(transaction.finalPrice)}',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.0,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            VerticalDivider(
                thickness: 1, width: 1, color: CustomColors.borderCardColor),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  addedBy,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.0,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            VerticalDivider(
                thickness: 1, width: 1, color: CustomColors.borderCardColor),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  dateFormat.format(transaction.createdAt),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.0,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            VerticalDivider(
                thickness: 1, width: 1, color: CustomColors.borderCardColor),
            SizedBox(
              width: 60,
              child: Center(
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'detail') {
                      onViewDetail();
                    }
                  },
                  offset: const Offset(0, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(
                      color: CustomColors.borderCardColor,
                      width: 1,
                    ),
                  ),
                  color: CustomColors.cardColor, // tema gelap
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'detail',
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        splashColor: Colors.transparent,
                        hoverColor: CustomColors.borderCardColor, // efek hover
                        onTap: () => Navigator.pop(context, 'detail'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: const [
                              Icon(Icons.remove_red_eye_outlined,
                                  color: Color(0xFF60A5FA),
                                  size: 16), // warna biru konsisten
                              SizedBox(width: 8),
                              Text(
                                'Lihat Detail',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  icon: const Icon(
                    Icons.more_vert,
                    color: CustomColors.fontSubColor,
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
