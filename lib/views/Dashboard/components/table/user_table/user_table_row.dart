import 'package:flutter/material.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class UserTableRow extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAttendance;
  final bool isSelected;
  final Function(bool?) onSelectChanged;

  const UserTableRow({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    required this.onEdit,
    required this.onDelete,
    required this.onAttendance,
    required this.isSelected,
    required this.onSelectChanged,
  });

  @override
  Widget build(BuildContext context) {
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
                  email,
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
                  role,
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
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    } else if (value == 'attendance') {
                      onAttendance();
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
                  color: CustomColors.cardColor,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        splashColor: Colors.transparent,
                        hoverColor: CustomColors.borderCardColor,
                        onTap: () => Navigator.pop(context, 'edit'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.edit,
                                  color: Color(0xFF60A5FA).withOpacity(0.9),
                                  size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'Edit',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        splashColor: Colors.transparent,
                        hoverColor: CustomColors.borderCardColor,
                        onTap: () => Navigator.pop(context, 'delete'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  color: Colors.redAccent.withOpacity(0.9),
                                  size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'Hapus',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'attendance',
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        splashColor: Colors.transparent,
                        hoverColor: CustomColors.borderCardColor,
                        onTap: () => Navigator.pop(context, 'attendance'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_outlined,
                                  color: const Color.fromARGB(255, 16, 206, 63)
                                      .withOpacity(0.9),
                                  size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'Riwayat Kehadiran',
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
