import 'package:flutter/material.dart';
import 'package:meko_poin/services/auth_service.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/views/auth/login_page.dart';
import 'package:meko_poin/utils/custom_colors.dart';

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
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await _authService.getCurrentUserRole();
    setState(() {
      _userRole = role;
    });
  }

  final Map<String, bool> _expandedMenus = {
    "Dashboards": true,
    "Managements": false,
    "Settings": false,
  };

  @override
  Widget build(BuildContext context) {
    if (_userRole == null) {
      return const CircularProgressIndicator(); // atau tampilan loading
    }

    return Container(
      width: 280,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 25),
      decoration: BoxDecoration(
        color: CustomColors.background,
        border: Border(
          right: BorderSide(color: CustomColors.borderCardColor, width: 1.0),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LOGO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                children: [
                  Image.asset(
                    'assets/logo-photorism.png',
                    width: 204,
                    height: 37.36,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            if (_userRole == '1')
              _buildAccordionMenu("Dashboards", Icons.dashboard_outlined,
                  ["Ringkasan", "Pelanggan"]),

            if (_userRole == '1')
              _buildAccordionMenu("Managements", Icons.layers_outlined,
                  ["Master Data", "Inventori", "Transaksi", "Pengguna"])
            else
              _buildAccordionMenu("Managements", Icons.layers_outlined,
                  ["Tambah Transaksi", "Transaksi"]),

            if (_userRole == '1')
              _buildAccordionMenu(
                  "Settings", Icons.settings_outlined, ["Database", "Logout"])
            else
              _buildAccordionMenu(
                  "Settings", Icons.settings_outlined, ["Logout"]),
          ],
        ),
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
          color: Colors.white,
        ),
        title: Row(
          children: [
            Icon(icon, size: 22, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
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
    final navigator = Navigator.of(context, rootNavigator: true);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 400), // Control width here
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and title
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color:
                            isDarkMode ? Colors.amber[300] : Colors.amber[700],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Peringatan Logout',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Content text
                  Text(
                    'Sebelum logout, pastikan Anda sudah melakukan backup data.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Backup Button - full width but constrained by parent
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await DatabaseHelper.instance
                            .backupDatabase(dialogContext);
                        navigator.pop(false);
                        await _showLogoutConfirmation(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1379F0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.backup,
                            size: 20,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Backup Sekarang',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Divider(
                    height: 1,
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  ),
                  const SizedBox(height: 16),

                  // Footer Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => navigator.pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              isDarkMode ? Colors.grey[300] : Colors.grey[700],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => navigator.pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              isDarkMode ? Colors.red[300] : Colors.red[600],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Logout Tanpa Backup'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (shouldLogout ?? false) {
      await _authService.logout();
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 400), // Same width control
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon
                  Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: isDarkMode ? Colors.blue[300] : Colors.blue[600],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Konfirmasi Logout',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Content text
                  Text(
                    'Backup selesai. Apakah Anda yakin ingin logout?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => navigator.pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              isDarkMode ? Colors.grey[300] : Colors.grey[700],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => navigator.pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDarkMode ? Colors.blue[800] : Colors.blue[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirm ?? false) {
      await _authService.logout();
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
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
        // color: active
        //     ? const Color(0xFFFFFFFF)
        //     : const Color.fromARGB(0, 255, 255, 255),
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
                          color: Colors.grey.shade800,
                        ),
                        Container(
                          width: 1.5,
                          height: 16,
                          color: Colors.grey.shade800,
                        ),
                        Container(
                          width: 1.5,
                          height: 16,
                          color: Colors.grey.shade800,
                        )
                      ],
                    ),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: active ? Color(0xFF1379F0) : Colors.white,
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
