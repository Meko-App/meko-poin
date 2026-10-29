import 'package:meko_poin/models/inventory_log.dart';

class LogInventoryWithMasterData {
  final InventoryLog inventoryLog;
  final String productName;
  final String categoryName;

  LogInventoryWithMasterData({
    required this.inventoryLog,
    required this.productName,
    this.categoryName = '',
  });
}
