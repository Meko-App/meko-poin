import 'package:flutter/material.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:path/path.dart';
// import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'views/auth/login_page.dart';
import 'package:window_manager/window_manager.dart';
import 'package:meko_poin/services/user_repository.dart';
import 'package:meko_poin/utils/validators.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize date formatting
    await initializeDateFormatting('id_ID', null);

    // Initialize window manager
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(800, 600),
      center: true,
      title: "POS Photorism App",
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    // Initialize database
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // For development only - remove in production
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');
    if (await databaseFactoryFfi.databaseExists(path)) {
      await databaseFactoryFfi.deleteDatabase(path);
    }

    // Initialize database helper
    final databaseHelper = DatabaseHelper.instance;
    await databaseHelper.database;

    // Initialize user repository and validators
    final userRepository = UserRepository(databaseHelper);
    Validators.initialize(userRepository);

    // Show window
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    runApp(const MyApp());

    // Maximize window after app starts
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        await windowManager.maximize();
      } catch (e) {
        debugPrint('Failed to maximize window: $e');
      }
    });
  } catch (e, stackTrace) {
    debugPrint('Application initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    // You might want to show an error dialog here
    runApp(const ErrorApp());
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Application failed to initialize',
              style: Theme.of(context).textTheme.headlineSmall),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Photorism App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
