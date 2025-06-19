import 'package:meko_poin/models/inventory.dart';

class InventoryWithUserMasterData {
  final Inventory inventoryData;
  final String name;
  final String addedBy;

  InventoryWithUserMasterData({
    required this.inventoryData,
    required this.name,
    required this.addedBy,
  });
}
