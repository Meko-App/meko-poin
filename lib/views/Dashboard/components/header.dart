import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final String currentPage;
  final String currentModulPage;
  final Widget? trailing;
  final bool showSidebar;

  const Header({
    super.key,
    required this.currentPage,
    required this.currentModulPage,
    this.trailing,
    this.showSidebar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 40, right: 40, top: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F3F9), width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                currentModulPage,
                style: TextStyle(color: Color(0xFF4b5675), fontSize: 14),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right,
                  size: 16, color: Color(0xFFA4ABBF)),
              const SizedBox(width: 8),
              Text(
                currentPage,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFF111B37),
                ),
              ),
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
