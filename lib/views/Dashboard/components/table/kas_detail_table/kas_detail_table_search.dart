import 'package:flutter/material.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class KasDetailTableSearch extends StatelessWidget {
  final List<dynamic> currentPageData;
  final List<dynamic> data;
  final VoidCallback onBack;
  final Function(String) onSearch;
  final VoidCallback onPrint;
  final VoidCallback onAddNew;
  final String monthName;

  const KasDetailTableSearch({
    super.key,
    required this.currentPageData,
    required this.data,
    required this.onBack,
    required this.onSearch,
    required this.onPrint,
    required this.onAddNew,
    required this.monthName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Menampilkan ${currentPageData.length} of ${data.length} data',
            style: const TextStyle(
              fontSize: 14,
              height: 1.0,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(
            width: 500,
            height: 34,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: onSearch,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Inter',
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari Keterangan',
                      hintStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Inter',
                        color: CustomColors.fontSubColor,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 14,
                        color: Colors.white,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 20,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: CustomColors.borderCardColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: CustomColors.borderCardColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF0BC33F), // Green background
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(color: Color(0xFF0BC33F)),
                    ),
                    minimumSize: const Size(108, 40),
                  ),
                  onPressed: onPrint,
                  child: const Text(
                    'Cetak Laporan',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontSize: 12,
                      height: 1.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1379F0), // Blue background
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    minimumSize: const Size(100, 40),
                  ),
                  onPressed: onAddNew,
                  child: const Text(
                    'Buat Baru',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontSize: 12,
                      height: 1.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
