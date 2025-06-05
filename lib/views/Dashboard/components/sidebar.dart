import 'package:flutter/material.dart';
import 'package:meko_poin/services/auth_service.dart';
import 'package:meko_poin/views/auth/login_page.dart';

class Sidebar extends StatefulWidget {
  final Function(String) onMenuSelected;
  final String? activeMenu;

  const Sidebar({
    super.key,
    required this.onMenuSelected,
    this.activeMenu = "Ringkasan",
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final AuthService _authService = AuthService();
  final Map<String, bool> _expandedMenus = {
    "Dashboards": true,
    "Managements": false,
    "Settings": false,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(vertical: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LOGO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 31,
                  height: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  "MEKO POIN",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildAccordionMenu("Dashboards", Icons.dashboard_outlined,
              ["Ringkasan", "Pelanggan"]),
          _buildAccordionMenu("Managements", Icons.layers_outlined,
              ["Master Data", "Inventori", "Transaksi", "Pengguna"]),
          _buildAccordionMenu(
              "Settings", Icons.settings_outlined, ["Database", "Logout"]),
        ],
      ),
    );
  }

  Widget _buildAccordionMenu(
      String title, IconData icon, List<String> children) {
    final isExpanded = _expandedMenus[title] ?? false;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: (val) {
          setState(() {
            _expandedMenus[title] = val;
          });
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 24),
        trailing: Icon(
          isExpanded ? Icons.remove : Icons.add,
          size: 16,
          color: Colors.grey.shade400,
        ),
        title: Row(
          children: [
            Icon(icon, size: 22, color: Colors.grey.shade400),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        children: children
            .map((menu) => SidebarMenuItem(
                  title: menu,
                  active: widget.activeMenu == menu,
                  onTap: () async {
                    if (menu == 'Logout') {
                      await _logout(context);
                    } else {
                      widget.onMenuSelected(menu);
                    }
                  },
                ))
            .toList(),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}

class SidebarMenuItem extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback? onTap;

  const SidebarMenuItem({
    super.key,
    required this.title,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFF9F9F9)
            : const Color.fromARGB(0, 255, 255, 255),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9.5, vertical: 0),
                child: Row(
                  spacing: 17,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 1.5,
                          height: 16,
                          color: Colors.grey.shade200,
                        ),
                        Container(
                          width: 1.5,
                          height: 16,
                          color: Colors.grey.shade200,
                        ),
                        Container(
                          width: 1.5,
                          height: 16,
                          color: Colors.grey.shade200,
                        )
                      ],
                    ),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color:
                              active ? Color(0xFF1379F0) : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedPositioned(
                  top: 20,
                  left: 7.5,
                  duration: const Duration(milliseconds: 250),
                  child: AnimatedOpacity(
                      opacity: active ? 1 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1379F0),
                          shape: BoxShape.circle,
                        ),
                      )))
            ],
          )),
    );
  }
}
