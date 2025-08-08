import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class CustomerTableRow extends StatelessWidget {
  final String name;
  final String phone;
  final DateTime createdAt;

  const CustomerTableRow({
    super.key,
    required this.name,
    required this.phone,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm:ss');

    return Container(
      constraints: const BoxConstraints(
        minHeight: 55, // Tinggi minimum row
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: CustomColors.borderCardColor)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            SizedBox(
              width: 59,
              child: Checkbox(
                value: false,
                onChanged: (_) {},
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
                  name,
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
                  phone,
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
                  dateFormat.format(createdAt),
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
            // VerticalDivider(thickness: 1, width: 1, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
