import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meko_poin/models/additional/transaction_with_customer_user.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class CardPelanggan extends StatefulWidget {
  final TransactionRepository transactionRepo;

  const CardPelanggan({super.key, required this.transactionRepo});

  @override
  State<CardPelanggan> createState() => _CardPelangganState();
}

class _CardPelangganState extends State<CardPelanggan> {
  int currentPage = 1;
  final int itemsPerPage = 4;
  List<TransactionWithCustomerUser> transactions = [];
  bool isLoading = true;
  String errorMessage = '';
  String sortBy = 'name'; // default sort
  bool isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Menggunakan method baru untuk ambil data hari ini
      final results =
          await widget.transactionRepo.getTodayTransactionsWithCustomer();

      setState(() {
        transactions = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat data: ${e.toString()}';
      });
    }
  }

  List<TransactionWithCustomerUser> get sortedTransactions {
    List<TransactionWithCustomerUser> sorted = List.from(transactions);
    sorted.sort((a, b) {
      int result;
      switch (sortBy) {
        case 'name':
          result = a.customerName.compareTo(b.customerName);
          break;
        case 'transaction':
          result = a.transaction.finalPrice.compareTo(b.transaction.finalPrice);
          break;
        case 'time':
          result = a.transaction.createdAt.compareTo(b.transaction.createdAt);
          break;
        default:
          result = a.customerName.compareTo(b.customerName);
      }
      return isAscending ? result : -result;
    });
    return sorted;
  }

  List<TransactionWithCustomerUser> get currentPageData {
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    return sortedTransactions.sublist(start,
        end > sortedTransactions.length ? sortedTransactions.length : end);
  }

  void onSort(String column) {
    setState(() {
      if (sortBy == column) {
        isAscending = !isAscending;
      } else {
        sortBy = column;
        isAscending = true;
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH.mm').format(dateTime);
  }

  String _formatPrice(int price) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(price);
  }

  Icon _sortIcon(String column) {
    if (sortBy != column) {
      return const Icon(
        Icons.unfold_more,
        size: 14,
        color: CustomColors.fontSubColor,
      );
    }
    return Icon(
      isAscending ? Icons.arrow_upward : Icons.arrow_downward,
      size: 14,
      color: CustomColors.fontSubColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    const double cardHeight = 365;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }

    final totalPages = (transactions.length / itemsPerPage).ceil();
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage > transactions.length)
        ? transactions.length
        : currentPage * itemsPerPage;

    return Container(
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        border: Border.all(color: CustomColors.borderCardColor),
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: BoxConstraints(
        minHeight: cardHeight,
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Pelanggan',
            style: TextStyle(
              fontSize: 16,
              height: 1.0,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 16),

          // Table Header
          Container(
            decoration: BoxDecoration(
              color: CustomColors.cardColor,
              border: Border(
                top: BorderSide(color: CustomColors.borderCardColor),
                bottom: BorderSide(color: CustomColors.borderCardColor),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Kolom Nama
                  Expanded(
                    child: InkWell(
                      onTap: () => onSort('name'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            right:
                                BorderSide(color: CustomColors.borderCardColor),
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                'Nama',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                  color: CustomColors.fontSubColor,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(width: 4),
                              _sortIcon('name'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Kolom Transaksi
                  Expanded(
                    child: InkWell(
                      onTap: () => onSort('transaction'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            right:
                                BorderSide(color: CustomColors.borderCardColor),
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                'Transaksi',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                  color: CustomColors.fontSubColor,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(width: 4),
                              _sortIcon('transaction'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Kolom Jam
                  Expanded(
                    child: InkWell(
                      onTap: () => onSort('time'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                'Jam',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                  color: CustomColors.fontSubColor,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(width: 4),
                              _sortIcon('time'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Table Content atau pesan kosong
          if (transactions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: const Center(
                child: Text(
                  'Tidak ada data transaksi hari ini',
                  style: TextStyle(
                    fontSize: 14,
                    color: CustomColors.fontSubColor,
                  ),
                ),
              ),
            )
          else
            ...currentPageData.map((transaction) => Container(
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: CustomColors.borderCardColor)),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18.0, vertical: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  transaction.customerName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.2,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                Text(
                                  transaction.customerPhone,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.2,
                                    fontWeight: FontWeight.w400,
                                    color: CustomColors.fontSubColor,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        VerticalDivider(
                            thickness: 1,
                            width: 1,
                            color: CustomColors.borderCardColor),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18.0, vertical: 6.0),
                            child: Text(
                              _formatPrice(transaction.transaction.finalPrice),
                              style: TextStyle(
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
                            thickness: 1,
                            width: 1,
                            color: CustomColors.borderCardColor),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18.0, vertical: 6.0),
                            child: Text(
                              _formatTime(transaction.transaction.createdAt),
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.0,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),

          // Pagination hanya muncul jika data lebih dari 4
          if (transactions.length > 4)
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$startItem-$endItem of ${transactions.length}',
                    style: TextStyle(
                        fontSize: 13,
                        height: 14 / 13,
                        color: CustomColors.fontSubColor,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(width: 20),
                  Row(
                    children: [
                      IconButton(
                        onPressed: currentPage > 1
                            ? () => setState(() => currentPage--)
                            : null,
                        icon: Transform.rotate(
                          angle: 3.1416,
                          child: Icon(Icons.arrow_right_alt,
                              size: 18,
                              color: currentPage > 1
                                  ? Colors.white
                                  : CustomColors.fontSubColor),
                        ),
                      ),
                      ...List.generate(totalPages, (index) {
                        final page = index + 1;
                        final isActive = currentPage == page;
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => setState(() => currentPage = page),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? CustomColors.borderCardColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$page',
                                style: TextStyle(
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  color: isActive
                                      ? Colors.white
                                      : CustomColors.fontSubColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      IconButton(
                        onPressed: currentPage < totalPages
                            ? () => setState(() => currentPage++)
                            : null,
                        icon: Icon(Icons.arrow_right_alt,
                            size: 18,
                            color: currentPage < totalPages
                                ? Colors.white
                                : CustomColors.fontSubColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
