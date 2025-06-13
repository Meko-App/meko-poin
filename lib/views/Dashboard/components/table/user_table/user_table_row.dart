import 'package:flutter/material.dart';

class UserTableRow extends StatelessWidget {
  final Map<String, dynamic> row;

  const UserTableRow({
    super.key,
    required this.row,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 55, // Tinggi minimum row
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
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
                  row['name'],
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
                  row['email'],
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
                  row['role'],
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
                      // TODO: aksi edit
                    } else if (value == 'delete') {
                      // TODO: aksi hapus
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
                          Icon(Icons.edit, color: Color(0xFF3B82F6), size: 16),
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
                              color: Colors.grey, size: 16),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(fontSize: 14)),
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
