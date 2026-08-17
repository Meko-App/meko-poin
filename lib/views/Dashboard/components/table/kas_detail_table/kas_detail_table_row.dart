import 'package:flutter/material.dart';
import 'package:meko_poin/models/additional/kas_with_balance.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:intl/intl.dart';

class KasDetailTableRow extends StatelessWidget {
  final KasWithBalance kasWithBalance;
  final bool isSelected;
  final bool canEdit;
  final Function(bool?) onSelectChanged;
  final VoidCallback onEdit;

  const KasDetailTableRow({
    super.key,
    required this.kasWithBalance,
    required this.isSelected,
    this.canEdit = true,
    required this.onSelectChanged,
    required this.onEdit,
  });

  String formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final kas = kasWithBalance.kas;
    final isTransfer = kas.fromVariable != null || kas.toVariable != null;
    final variableLabel = kas.variable == 'saldo' ? 'Saldo' : 'Cash';
    final variableDisplay = isTransfer
        ? '${kas.fromVariable == 'saldo' ? 'Saldo' : 'Cash'} \u2192 ${kas.toVariable == 'saldo' ? 'Saldo' : 'Cash'}'
        : variableLabel;

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
              width: 60,
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
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  formatDate(kas.cashDate),
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
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  formatCurrency(kas.amount),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.0,
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
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: isTransfer
                    ? Text(
                        'Transfer',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.0,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF60A5FA),
                          fontFamily: 'Inter',
                        ),
                      )
                    : Text(
                        kas.type == 'income' ? 'Pemasukan' : 'Pengeluaran',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.0,
                          fontWeight: FontWeight.w500,
                          color: kas.type == 'income'
                              ? Color(0xFF0BC33F)
                              : Color(0xFFED143B),
                          fontFamily: 'Inter',
                        ),
                      ),
              ),
            ),
            VerticalDivider(
                thickness: 1, width: 1, color: CustomColors.borderCardColor),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  variableDisplay,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.0,
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
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  formatCurrency(kasWithBalance.initialBalance),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.0,
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
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  formatCurrency(kasWithBalance.finalBalance),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.0,
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
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 20.0),
                child: Text(
                  kas.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.0,
                    fontWeight: FontWeight.w500,
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
              child: isTransfer || !canEdit
                  ? const SizedBox.shrink()
                  : Center(
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit();
                          }
                        },
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
                                    Icon(Icons.edit,
                                        color: Color(0xFF60A5FA), size: 16),
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
}
