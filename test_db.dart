import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  final dbPath = 'C:\\Users\\USER\\AppData\\Roaming\\com.example\\meko_poin\\app_database.db';
  final db = await databaseFactory.openDatabase(dbPath);
  final items = await db.query('Data_Transaction_Item', orderBy: 'id DESC', limit: 5);
  for (final item in items) {
    print(item);
  }
}
