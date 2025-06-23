import 'package:flutter/material.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'views/auth/login_page.dart';
import 'package:window_manager/window_manager.dart';
import 'package:meko_poin/services/user_repository.dart';
import 'package:meko_poin/utils/validators.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi window manager
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    center: true,
    title: "POS Photorism App",
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'app_database.db');

  if (await databaseFactoryFfi.databaseExists(path)) {
    await databaseFactoryFfi.deleteDatabase(path);
  }

  final databaseHelper = DatabaseHelper.instance;
  await databaseHelper.database;

  final userRepository = UserRepository(databaseHelper);
  Validators.initialize(userRepository);

  runApp(const MyApp());

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await Future.delayed(const Duration(milliseconds: 150));
    await windowManager.maximize();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
