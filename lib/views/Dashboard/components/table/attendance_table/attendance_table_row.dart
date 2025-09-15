import 'package:flutter/material.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class AttendanceTableRow extends StatelessWidget {
  final String date;
  final String transactionCount;
  final String revenue;
  final bool isSelected;
  final Function(bool?) onSelectChanged;

  const AttendanceTableRow({
    super.key,
    required this.date,
    required this.transactionCount,
    required this.revenue,
    required this.isSelected,
    required this.onSelectChanged,
  });

  @override
  Widget build(BuildContext context) {
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
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  date,
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
                  transactionCount,
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
                  revenue,
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
          ],
        ),
      ),
    );
  }
}
