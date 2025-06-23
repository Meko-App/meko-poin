import 'package:flutter/material.dart';

class InventoryTableRow extends StatelessWidget {
  final String name;
  final int stock;
  final String notes;
  final String addedBy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewLog;

  const InventoryTableRow({
    super.key,
    required this.name,
    required this.stock,
    required this.notes,
    required this.addedBy,
    required this.onEdit,
    required this.onDelete,
    required this.onViewLog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 55,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
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
            VerticalDivider(thickness: 1, width: 1, color: Colors.grey[300]),
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
                    color: Color(0xFF111B37),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            VerticalDivider(thickness: 1, width: 1, color: Colors.grey[300]),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  stock.toString(),
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
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  notes,
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
                    color: Color(0xFF27314B),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            VerticalDivider(thickness: 1, width: 1, color: Colors.grey[300]),
            SizedBox(
              width: 60,
              child: Center(
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    } else if (value == 'log') {
                      onViewLog();
                    }
                  },
                  offset: const Offset(0, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: Colors.white,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: const [
                          Icon(Icons.edit, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Text('Edit', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: const [
                          Icon(Icons.delete_outline,
                              color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'log',
                      child: Row(
                        children: const [
                          Icon(Icons.access_time, color: Colors.blue, size: 16),
                          SizedBox(width: 8),
                          Text('Log Aktivitas', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
