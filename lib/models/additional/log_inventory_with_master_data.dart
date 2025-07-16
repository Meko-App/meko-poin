import 'package:meko_poin/models/inventory_log.dart';

class LogInventoryWithMasterData {
  final InventoryLog inventoryLog;
  final String productName;

  LogInventoryWithMasterData({
    required this.inventoryLog,
    required this.productName,
  });
}
