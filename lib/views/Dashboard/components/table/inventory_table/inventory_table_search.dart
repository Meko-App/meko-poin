import 'package:flutter/material.dart';

class InventoryTableSearch extends StatelessWidget {
  final List<dynamic> currentPageData;
  final List<dynamic> data;
  final VoidCallback onAddNew;
  final Function(String) onSearch;

  const InventoryTableSearch({
    super.key,
    required this.currentPageData,
    required this.data,
    required this.onAddNew,
    required this.onSearch,
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
              color: Color(0xFF111B37),
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(
            width: 385,
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
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari Nama',
                      hintStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Inter',
                        color: Color(0xFF78829D),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 14,
                        color: Color(0xFFA4ABBF),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 20,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1379F0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
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
