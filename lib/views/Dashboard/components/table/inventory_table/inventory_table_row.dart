import 'package:flutter/material.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:meko_poin/views/Dashboard/components/table/inventory_table/add_reject_dialog.dart';
import 'package:meko_poin/views/Dashboard/components/table/inventory_table/add_stock_dialog.dart';

class InventoryTableRow extends StatelessWidget {
  final String name;
  final String categoryName;
  final int stock;
  final int stockReject;
  final String notes;
  final String addedBy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewLog;
  final Function(int) onAddReject;
  final Future<void> Function(int quantity, String? note) onAddStock;
  final bool isSelected;
  final Function(bool?) onSelectChanged;

  const InventoryTableRow({
    super.key,
    required this.name,
    this.categoryName = '',
    required this.stock,
    required this.stockReject,
    required this.notes,
    required this.addedBy,
    required this.onEdit,
    required this.onDelete,
    required this.onViewLog,
    required this.onAddReject,
    required this.onAddStock,
    required this.isSelected,
    required this.onSelectChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 55,
      ),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
          color: CustomColors.borderCardColor,
        )),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            SizedBox(
              width: 59,
              child: Checkbox(
                value: isSelected,
                onChanged: onSelectChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                activeColor: Colors.blue.shade400,
                side: const BorderSide(width: 0.4, color: Colors.grey),
              ),
            ),
            VerticalDivider(
                thickness: 1, width: 1, color: CustomColors.borderCardColor),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            VerticalDivider(
                thickness: 1, width: 1, color: CustomColors.borderCardColor),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            VerticalDivider(
                thickness: 1, width: 1, color: CustomColors.borderCardColor),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  stock.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.0,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            VerticalDivider(
                thickness: 1, width: 1, color: CustomColors.borderCardColor),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  notes,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.0,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            VerticalDivider(
                thickness: 1, width: 1, color: CustomColors.borderCardColor),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  addedBy,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.0,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            VerticalDivider(
                thickness: 1, width: 1, color: CustomColors.borderCardColor),
            SizedBox(
              width: 60,
              child: Center(
                child: PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuSelection(value, context),
                  offset: const Offset(0, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(
                      color: CustomColors.borderCardColor,
                      width: 1,
                    ),
                  ),
                  color: CustomColors.cardColor, // tema gelap
                  itemBuilder: (context) => [
                    // Tambah Stock
                    PopupMenuItem(
                      value: 'add_stock',
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        splashColor: Colors.transparent,
                        hoverColor: CustomColors.borderCardColor,
                        onTap: () => Navigator.pop(context, 'add_stock'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: const [
                              Icon(Icons.add,
                                  color: Colors.lightGreen, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Tambah Stock',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Tambah Reject
                    PopupMenuItem(
                      value: 'reject',
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        splashColor: Colors.transparent,
                        hoverColor: CustomColors.borderCardColor,
                        onTap: () => Navigator.pop(context, 'reject'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: const [
                              Icon(Icons.block, color: Colors.orange, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Tambah Reject',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Edit
                    PopupMenuItem(
                      value: 'edit',
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        splashColor: Colors.transparent,
                        hoverColor: CustomColors.borderCardColor,
                        onTap: () => Navigator.pop(context, 'edit'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: const [
                              Icon(Icons.edit, color: Colors.green, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Edit',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Hapus
                    PopupMenuItem(
                      value: 'delete',
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        splashColor: Colors.transparent,
                        hoverColor: CustomColors.borderCardColor,
                        onTap: () => Navigator.pop(context, 'delete'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: const [
                              Icon(Icons.delete_outline,
                                  color: Colors.redAccent, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Hapus',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Log Aktivitas
                    PopupMenuItem(
                      value: 'log',
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        splashColor: Colors.transparent,
                        hoverColor: CustomColors.borderCardColor,
                        onTap: () => Navigator.pop(context, 'log'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: const [
                              Icon(Icons.access_time,
                                  color: Colors.blue, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Log Aktivitas',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  icon: const Icon(
                    Icons.more_vert,
                    color: CustomColors.fontSubColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'edit':
        onEdit();
        break;
      case 'delete':
        onDelete();
        break;
      case 'log':
        onViewLog();
        break;
      case 'reject':
        _showAddRejectDialog(context);
        break;
      case 'add_stock':
        _showAddStockDialog(context);
        break;
    }
  }

  void _showAddRejectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddRejectDialog(
        itemName: name,
        currentRejectStock: stockReject,
        onRejectAdded: (rejectAmount) {
          onAddReject(rejectAmount);
        },
      ),
    );
  }

  void _showAddStockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddStockDialog(
        itemName: name,
        currentStock: stock,
        onStockAdded: (quantity, note) async {
          await onAddStock(quantity, note);
        },
      ),
    );
  }
}
