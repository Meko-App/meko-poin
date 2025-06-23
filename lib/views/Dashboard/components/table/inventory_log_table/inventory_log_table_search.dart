import 'package:flutter/material.dart';
import 'package:meko_poin/models/inventory_log.dart';

class InventoryLogTableSearch extends StatelessWidget {
  final List<InventoryLog> currentPageData;
  final List<InventoryLog> data;
  final Function(String) onSearch;

  const InventoryLogTableSearch({
    super.key,
    required this.currentPageData,
    required this.data,
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
            'Menampilkan ${currentPageData.length} dari ${data.length} data log',
            style: const TextStyle(
              fontSize: 14,
              height: 1.0,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111B37),
              fontFamily: 'Inter',
            ),
          ),
          // SizedBox(
          //   width: 385,
          //   height: 34,
          //   child: TextField(
          //     onChanged: onSearch,
          //     style: const TextStyle(
          //       fontSize: 11,
          //       fontWeight: FontWeight.w400,
          //       fontFamily: 'Inter',
          //       color: Colors.black,
          //     ),
          //     decoration: InputDecoration(
          //       hintText: 'Cari Catatan', // Updated hint text
          //       hintStyle: const TextStyle(
          //         fontSize: 11,
          //         fontWeight: FontWeight.w400,
          //         fontFamily: 'Inter',
          //         color: Color(0xFF78829D),
          //       ),
          //       prefixIcon: const Icon(
          //         Icons.search,
          //         size: 14,
          //         color: Color(0xFFA4ABBF),
          //       ),
          //       prefixIconConstraints: const BoxConstraints(
          //         minWidth: 30,
          //         minHeight: 20,
          //       ),
          //       contentPadding:
          //           const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          //       border: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(6),
          //         borderSide: BorderSide(color: Colors.grey.shade300),
          //       ),
          //       enabledBorder: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(6),
          //         borderSide: BorderSide(color: Colors.grey.shade300),
          //       ),
          //     ),
          //   ),
          // )
        ],
      ),
    );
  }
}
