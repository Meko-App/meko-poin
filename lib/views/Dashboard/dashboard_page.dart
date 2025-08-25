import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:meko_poin/models/user.dart';
import 'package:meko_poin/services/customer_repository.dart';
import 'package:meko_poin/services/inventory_log_repository.dart';
import 'package:meko_poin/services/inventory_repository.dart';
import 'package:meko_poin/services/master_data_repository.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:meko_poin/services/user_repository.dart';
import 'package:meko_poin/views/Dashboard/components/header.dart';
import 'package:meko_poin/views/Dashboard/components/sidebar.dart';
import 'package:meko_poin/views/Dashboard/contents/ringkasan_content.dart';
import 'package:meko_poin/views/Dashboard/contents/pelanggan_content.dart';
import 'package:meko_poin/views/Dashboard/contents/masterdata_content.dart';
import 'package:meko_poin/views/Dashboard/contents/inventory_content.dart';
import 'package:meko_poin/views/Dashboard/contents/transaksi_content.dart';
import 'package:meko_poin/views/Dashboard/contents/pengguna_content.dart';
import 'package:meko_poin/views/Dashboard/contents/database_content.dart';
import 'package:meko_poin/views/Dashboard/contents/utils/content_state.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class DashboardPage extends StatefulWidget {
  final User user;
  final UserRepository userRepository;
  final TransactionRepository transactionRepository;
  final MasterDataRepository masterDataRepository;
  final InventoryRepository inventoryRepository;
  final InventoryLogRepository inventoryLogRepository;
  final CustomerRepository customerRepository;
  final String? initialMenu;

  const DashboardPage(
      {super.key,
      required this.user,
      required this.userRepository,
      required this.transactionRepository,
      required this.masterDataRepository,
      required this.inventoryRepository,
      required this.inventoryLogRepository,
      required this.customerRepository,
      this.initialMenu});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showSidebar = true;
  late String _selectedMenu;
  ContentState? _contentCurrentState;
  int _ContentKey = 0;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _selectedMenu =
        widget.initialMenu ?? 'Ringkasan'; // Tambahkan fallback value
    _avatarPath = widget.user.avatarPath;
    if (widget.user.roleId != 1) {
      _contentCurrentState = ContentState.form; // Langsung tampilkan form
    }
  }

  void _toggleSidebar() {
    setState(() {
      _showSidebar = !_showSidebar;
    });
  }

  void _updateContentState(ContentState state) {
    setState(() {
      _contentCurrentState = state;
    });
  }

  Future<String?> _pickAndSaveAvatar() async {
    try {
      // 1. Pilih file dari sistem
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null) return null;

      // 2. Baca file yang dipilih
      final filePath = result.files.single.path!;
      final fileName =
          'avatar_${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}${path.extension(filePath)}';

      // 3. Dapatkan direktori dokumen aplikasi
      final Directory appDir;
      if (Platform.isMacOS) {
        appDir = await getApplicationSupportDirectory();
      } else {
        appDir = await getApplicationDocumentsDirectory();
      }
      final avatarDir = Directory('${appDir.path}/photorism-app/avatars');

      // 4. Buat folder jika belum ada
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      // 5. Salin file ke direktori aplikasi
      final savedPath = '${avatarDir.path}/$fileName';
      await File(filePath).copy(savedPath);
      return savedPath;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan avatar: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _handleAvatarClick() async {
    final selectedImagePath = await showDialog<String?>(
      context: context,
      builder: (context) {
        String? currentImagePath; // simpan di dalam builder
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Konfirmasi Avatar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 350,
                  maxWidth: 400,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (currentImagePath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(currentImagePath!),
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      const Text(
                        'Pilih gambar terlebih dahulu',
                        style: TextStyle(color: Colors.white70),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final path = await _pickAndSaveAvatar();
                        if (path != null) {
                          setDialogState(() {
                            currentImagePath = path;
                          });
                        }
                      },
                      child: const Text('Pilih Gambar Baru'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1379F0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, currentImagePath),
                  child: const Text('Gunakan'),
                ),
              ],
            );
          },
        );
      },
    );

    // Simpan ke database jika gambar dipilih
    if (selectedImagePath != null && selectedImagePath.isNotEmpty) {
      try {
        // Update avatar di database
        await widget.userRepository
            .updateUserAvatar(widget.user.id!, selectedImagePath);

        // Update state lokal
        setState(() {
          _avatarPath = selectedImagePath;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar berhasil diperbarui')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memperbarui avatar: $e')),
          );
        }
      }
    }
  }

  Widget _buildAvatar() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleAvatarClick,
        child: _avatarPath != null
            ? CircleAvatar(
                radius: 18,
                backgroundImage: _avatarPath!.startsWith('assets/')
                    ? AssetImage(_avatarPath!)
                    : FileImage(File(_avatarPath!)) as ImageProvider,
              )
            : const CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage('assets/user.png'),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String getModulPage(String menu) {
      if (menu == 'Ringkasan' || menu == 'Pelanggan') {
        return 'Dashboards';
      } else if (menu == 'Master Data' ||
          menu == 'Inventori' ||
          menu == 'Transaksi' ||
          menu == 'Tambah Transaksi' ||
          menu == 'Pengguna') {
        return 'Managements';
      } else if (menu == 'Database') {
        return 'Settings';
      } else {
        return 'Unknown';
      }
    }

    String headerCurrentPage =
        _selectedMenu == 'Inventori' ? 'Gudang' : _selectedMenu;
    String? headerSubPage;

    if (_selectedMenu == 'Pengguna' ||
        _selectedMenu == 'Master Data' ||
        _selectedMenu == 'Inventori' ||
        _selectedMenu == 'Transaksi') {
      if (_contentCurrentState == ContentState.form) {
        headerSubPage = 'Buat Baru';
      } else if (_contentCurrentState == ContentState.log) {
        headerSubPage = 'Log Aktivitas';
      } else if (_contentCurrentState == ContentState.detail) {
        headerSubPage = 'Detail Transaksi';
      } else {
        headerSubPage = null;
      }
    } else {
      headerSubPage = null;
    }

    return Scaffold(
        body: Stack(
      children: [
        Row(
          children: [
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
                        _contentCurrentState = null;
                        _ContentKey++;
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
                    currentPage: headerCurrentPage,
                    currentPage2: headerSubPage,
                    trailing: GestureDetector(
                      onTap: _handleAvatarClick,
                      child: _buildAvatar(),
                    ),
                  ),
                  Expanded(
                    child: DashboardContent(
                        menu: _selectedMenu,
                        userId: widget.user.roleId,
                        onContentStateChanged: (state) {
                          if (_selectedMenu == 'Pengguna' ||
                              _selectedMenu == 'Master Data' ||
                              _selectedMenu == 'Inventori' ||
                              _selectedMenu == 'Transaksi') {
                            _updateContentState(state);
                          }
                        },
                        userRepository: widget.userRepository,
                        transactionRepository: widget.transactionRepository,
                        masterDataRepository: widget.masterDataRepository,
                        inventoryRepository: widget.inventoryRepository,
                        inventoryLogRepository: widget.inventoryLogRepository,
                        customerRepository: widget.customerRepository,
                        contentKey: _ContentKey),
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
                color: Colors.white,
                iconSize: 18,
                style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(CustomColors.inputColor),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        side: BorderSide(
                          color: CustomColors.borderInputColor,
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
              color: Colors.white,
              style: ButtonStyle(
                  backgroundColor:
                      WidgetStateProperty.all(CustomColors.inputColor),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      side: BorderSide(
                        color: CustomColors.borderInputColor,
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
  final int userId;
  final Function(ContentState)? onContentStateChanged;
  final UserRepository userRepository;
  final TransactionRepository transactionRepository;
  final MasterDataRepository masterDataRepository;
  final InventoryRepository inventoryRepository;
  final InventoryLogRepository inventoryLogRepository;
  final CustomerRepository customerRepository;
  final int contentKey;

  const DashboardContent({
    super.key,
    required this.menu,
    required this.userId,
    this.onContentStateChanged,
    required this.userRepository,
    required this.transactionRepository,
    required this.masterDataRepository,
    required this.inventoryRepository,
    required this.inventoryLogRepository,
    required this.customerRepository,
    this.contentKey = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CustomColors.background,
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
        return PelangganContent(
          customerRepository: customerRepository,
        );
      case 'Master Data':
        return MasterdataContent(
          key: ValueKey(contentKey),
          onStateChanged: onContentStateChanged!,
          masterDataRepository: masterDataRepository,
        );
      case 'Inventori':
        return InventoryContent(
          key: ValueKey(contentKey),
          onStateChanged: onContentStateChanged!,
          inventoryRepository: inventoryRepository,
          inventoryLogRepository: inventoryLogRepository, // Teruskan repository
        );
      case 'Transaksi':
        return TransaksiContent(
          key: ValueKey(contentKey),
          user: userId,
          onStateChanged: onContentStateChanged!,
          transactionRepository: transactionRepository, // Teruskan repository
        );
      case 'Tambah Transaksi':
        return TransaksiContent(
          key: ValueKey(contentKey),
          menu: 'Tambah Transaksi',
          onStateChanged: onContentStateChanged!,
          transactionRepository: transactionRepository,
        );
      case 'Pengguna':
        return PenggunaContent(
          key: ValueKey(contentKey),
          onStateChanged: onContentStateChanged!,
          userRepository: userRepository, // Teruskan repository
        );
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
