import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InventoryLogTableRow extends StatelessWidget {
  final DateTime createdAt;
  final String notes;
  final int initialStock;
  final int currentStock;
  final int difference;
  final String type;

  const InventoryLogTableRow({
    super.key,
    required this.createdAt,
    required this.notes,
    required this.initialStock,
    required this.currentStock,
    required this.difference,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 55,
      ),
      decoration: BoxDecoration(
        color: type == 'increment' ? Colors.green.shade50 : Colors.red.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Created At
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  DateFormat('d MMMM yyyy, HH:mm:ss', 'id_ID')
                      .format(createdAt),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111B37),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            VerticalDivider(thickness: 1, width: 1, color: Colors.grey[300]),

            // Notes
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  notes.isEmpty ? '-' : notes,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.0,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF27314B),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            VerticalDivider(thickness: 1, width: 1, color: Colors.grey[300]),

            // Initial Stock
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  initialStock.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.0,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF27314B),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            VerticalDivider(thickness: 1, width: 1, color: Colors.grey[300]),

            // Current Stock
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  currentStock.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.0,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF27314B),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            VerticalDivider(thickness: 1, width: 1, color: Colors.grey[300]),

            // Difference
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  difference.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.0,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF27314B),
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
