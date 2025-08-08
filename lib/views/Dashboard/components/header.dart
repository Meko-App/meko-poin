import 'package:flutter/material.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class Header extends StatelessWidget {
  final String currentPage;
  final String currentModulPage;
  final Widget? trailing;
  final bool showSidebar;
  final String? currentPage2;

  const Header({
    super.key,
    required this.currentPage,
    required this.currentModulPage,
    this.trailing,
    this.showSidebar = true,
    this.currentPage2,
  });

  @override
  Widget build(BuildContext context) {
    final FontWeight currentPageFontWeight =
        currentPage2 != null ? FontWeight.w400 : FontWeight.w500;

    return Container(
      padding: const EdgeInsets.only(left: 40, right: 40, top: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: CustomColors.background,
        border: Border(
          bottom: BorderSide(color: CustomColors.borderCardColor, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                currentModulPage,
                style: TextStyle(color: Color(0xFF9A9CAE), fontSize: 14),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right,
                  size: 16, color: Color(0xFFA4ABBF)),
              const SizedBox(width: 8),
              Text(
                currentPage,
                style: TextStyle(
                  fontWeight: currentPageFontWeight,
                  fontSize: 14,
                  color: const Color(0xFFDBDCE4),
                ),
              ),
              if (currentPage2 != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right,
                    size: 16, color: Color(0xFFA4ABBF)),
                const SizedBox(width: 8),
                Text(
                  currentPage2!, // Gunakan '!' karena sudah kita cek tidak null
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFFDBDCE4),
                  ),
                ),
              ],
            ],
          ),
          trailing ??
              const CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage('assets/user.png'),
              ),
        ],
      ),
    );
  }
}
