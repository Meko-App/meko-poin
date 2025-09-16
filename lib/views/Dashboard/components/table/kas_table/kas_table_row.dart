import 'package:flutter/material.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:intl/intl.dart';

class KasTableRow extends StatelessWidget {
  final int month;
  final int year;
  final int totalIncome;
  final int totalOutcome;
  final int netAmount;
  final bool isSelected;
  final Function(bool?) onSelectChanged;
  final VoidCallback onViewDetail;

  const KasTableRow({
    super.key,
    required this.month,
    required this.year,
    required this.totalIncome,
    required this.totalOutcome,
    required this.netAmount,
    required this.isSelected,
    required this.onSelectChanged,
    required this.onViewDetail,
  });

  String get monthName {
    return DateFormat('MMMM', 'id_ID').format(DateTime(year, month));
  }

  String formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 55,
      ),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
          color: CustomColors.borderCardColor,
        )),
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
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  monthName,
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
            // VerticalDivider(
            //     thickness: 1, width: 1, color: CustomColors.borderCardColor),
            // Expanded(
            //   child: Container(
            //     padding: const EdgeInsets.symmetric(
            //         horizontal: 18.0, vertical: 20.0),
            //     child: Text(
            //       formatCurrency(totalIncome),
            //       style: TextStyle(
            //         fontSize: 14,
            //         height: 1.0,
            //         fontWeight: FontWeight.w400,
            //         color: Colors.green[300],
            //         fontFamily: 'Inter',
            //       ),
            //     ),
            //   ),
            // ),
            // VerticalDivider(
            //     thickness: 1, width: 1, color: CustomColors.borderCardColor),
            // Expanded(
            //   child: Container(
            //     padding: const EdgeInsets.symmetric(
            //         horizontal: 18.0, vertical: 20.0),
            //     child: Text(
            //       formatCurrency(totalOutcome),
            //       style: TextStyle(
            //         fontSize: 14,
            //         height: 1.0,
            //         fontWeight: FontWeight.w400,
            //         color: Colors.red[300],
            //         fontFamily: 'Inter',
            //       ),
            //     ),
            //   ),
            // ),
            VerticalDivider(
                thickness: 1, width: 1, color: CustomColors.borderCardColor),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  formatCurrency(netAmount),
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
            SizedBox(
              width: 60,
              child: Center(
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'detail') {
                      // onViewDetail();
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
                        // onTap: () => Navigator.pop(context, 'detail'),
                        onTap: () => {},
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
