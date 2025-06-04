import 'package:flutter/material.dart';
import 'package:meko_poin/models/user.dart';
import 'package:meko_poin/views/auth/login_page.dart';
import '../../services/auth_service.dart';

class DashboardPage extends StatefulWidget {
  final User user;

  const DashboardPage({super.key, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showSidebar = true;
  String _selectedMenu = "Ringkasan";

  void _toggleSidebar() {
    setState(() {
      _showSidebar = !_showSidebar;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar dengan animasi
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Container(
              width: _showSidebar ? 280 : 0,
              child: Visibility(
                visible: _showSidebar,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: true,
                child: Sidebar(
                  onMenuSelected: (menu) {
                    setState(() {
                      _selectedMenu = menu;
                    });
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                DashboardHeader(
                  showSidebar: _showSidebar,
                  onMenuPressed: _toggleSidebar,
                ),
                Expanded(
                  child: DashboardContent(menu: _selectedMenu),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardHeader extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final bool showSidebar;

  const DashboardHeader({
    super.key,
    required this.onMenuPressed,
    required this.showSidebar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.only(left: 12, right: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.25)),
      ),
      child: Row(
        children: [
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            firstChild: IconButton(
              icon: const Icon(Icons.close_fullscreen),
              onPressed: onMenuPressed,
            ),
            secondChild: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuPressed,
            ),
            crossFadeState: showSidebar
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
          ),
          const SizedBox(width: 8),
          const Text(
            'Dashboards',
            style: TextStyle(color: Colors.blueGrey, fontSize: 14),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          const SizedBox(width: 6),
          const Text(
            'Ringkasan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Spacer(),
          const CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage('assets/user.png'),
          ),
        ],
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  final String menu;

  const DashboardContent({super.key, required this.menu});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      child: _buildContentForMenu(),
    );
  }

  Widget _buildContentForMenu() {
    switch (menu) {
      case 'Ringkasan':
        return _buildRingkasan();
      case 'Pelanggan':
        return _buildSimplePage("Halaman Pelanggan");
      case 'Master Data':
        return _buildSimplePage("Halaman Master Data");
      case 'Inventori':
        return _buildSimplePage("Halaman Inventori");
      case 'Transaksi':
        return _buildSimplePage("Halaman Transaksi");
      case 'Pengguna':
        return _buildSimplePage("Halaman Pengguna");
      case 'Database':
        return _buildSimplePage("Halaman Database");
      default:
        return _buildSimplePage("Halaman $menu");
    }
  }

  Widget _buildRingkasan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Dashboard",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text("Data ringkasan berdasarkan hari ini",
            style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildCard("Pelanggan")),
            const SizedBox(width: 24),
            Expanded(child: _buildCard("Penjualan Hari Ini")),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildCard("Gudang")),
            const SizedBox(width: 24),
            Expanded(child: _buildCard("Produk Terfavorit")),
          ],
        ),
      ],
    );
  }

  Widget _buildSimplePage(String title) {
    return Center(
      child: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildCard(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class Sidebar extends StatefulWidget {
  final Function(String) onMenuSelected;

  const Sidebar({super.key, required this.onMenuSelected});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String _activeMenu = "Ringkasan";
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
          right: BorderSide(color: Colors.grey, width: 0.25),
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
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        children: children
            .map((menu) => SidebarMenuItem(
                  title: menu,
                  active: _activeMenu == menu,
                  onTap: () async {
                    if (menu == 'Logout') {
                      // Jalankan logika logout di sini
                      await _logout(context);
                    } else {
                      setState(() {
                        _activeMenu = menu;
                      });
                      widget.onMenuSelected(menu);
                    }
                  },
                ))
            .toList(),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    // Misal kamu sudah punya _authService
    await _authService.logout(); // pastikan ini tersedia
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
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEFF6FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (active)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(width: 18),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    color: active ? Colors.blue : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
