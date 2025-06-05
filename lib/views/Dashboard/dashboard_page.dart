import 'package:flutter/material.dart';
import 'package:meko_poin/models/user.dart';
import 'package:meko_poin/views/Dashboard/components/header.dart';
import 'package:meko_poin/views/Dashboard/components/sidebar.dart';
import 'package:meko_poin/views/Dashboard/contents/ringkasan_content.dart';
import 'package:meko_poin/views/Dashboard/contents/pelanggan_content.dart';
import 'package:meko_poin/views/Dashboard/contents/masterdata_content.dart';
import 'package:meko_poin/views/Dashboard/contents/inventori_content.dart';
import 'package:meko_poin/views/Dashboard/contents/transaksi_content.dart';
import 'package:meko_poin/views/Dashboard/contents/pengguna_content.dart';
import 'package:meko_poin/views/Dashboard/contents/database_content.dart';

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
    String getModulPage(String menu) {
      if (menu == 'Ringkasan' || menu == 'Pelanggan') {
        return 'Dashboards';
      } else if (menu == 'Master Data' ||
          menu == 'Inventori' ||
          menu == 'Transaksi' ||
          menu == 'Pengguna') {
        return 'Managements';
      } else if (menu == 'Database') {
        return 'Settings';
      } else {
        return 'Unknown';
      }
    }

    return Scaffold(
        body: Stack(
      children: [
        Row(
          children: [
            // Sidebar dengan animasi
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: SizedBox(
                width: _showSidebar ? 280 : 30,
                child: Visibility(
                  visible: _showSidebar,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: true,
                  child: Sidebar(
                    activeMenu: _selectedMenu,
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
                  Header(
                    currentModulPage: getModulPage(_selectedMenu),
                    currentPage: _selectedMenu,
                    trailing: const CircleAvatar(
                      radius: 18,
                      backgroundImage: AssetImage('assets/user.png'),
                    ),
                  ),
                  Expanded(
                    child: DashboardContent(menu: _selectedMenu),
                  ),
                ],
              ),
            ),
          ],
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: 20,
          left: _showSidebar ? 260 : 10,
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            firstChild: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(3.1416),
              child: IconButton(
                icon: const Icon(Icons.keyboard_tab),
                onPressed: _toggleSidebar,
                color: Colors.grey.shade500,
                iconSize: 18,
                style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(const Color(0xFFFFFFFF)),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        side: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1.0,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    )),
              ),
            ),
            secondChild: IconButton(
              icon: const Icon(Icons.keyboard_tab),
              onPressed: _toggleSidebar,
              iconSize: 18,
              color: Colors.grey.shade500,
              style: ButtonStyle(
                  backgroundColor:
                      WidgetStateProperty.all(const Color(0xFFFFFFFF)),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      side: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1.0,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  )),
            ),
            crossFadeState: _showSidebar
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
          ),
        )
      ],
    ));
  }
}

class DashboardContent extends StatelessWidget {
  final String menu;

  const DashboardContent({super.key, required this.menu});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 40, right: 40, top: 20, bottom: 20),
      width: double.infinity,
      child: _buildContentForMenu(),
    );
  }

  Widget _buildContentForMenu() {
    switch (menu) {
      case 'Ringkasan':
        return const RingkasanContent();
      case 'Pelanggan':
        return const PelangganContent();
      case 'Master Data':
        return const MasterDataContent();
      case 'Inventori':
        return const InventoriContent();
      case 'Transaksi':
        return const TransaksiContent();
      case 'Pengguna':
        return const PenggunaContent();
      case 'Database':
        return const DatabaseContent();
      default:
        return Center(
          child: Text("Halaman $menu",
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        );
    }
  }
}
