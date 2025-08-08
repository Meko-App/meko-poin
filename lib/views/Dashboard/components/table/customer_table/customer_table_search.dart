import 'package:flutter/material.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class CustomerTableSearch extends StatelessWidget {
  final List<dynamic> currentPageData;
  final List<dynamic> data;
  final Function(String) onSearch;

  const CustomerTableSearch({
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
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari Nama',
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
                        borderSide:
                            BorderSide(color: CustomColors.borderCardColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:
                            BorderSide(color: CustomColors.borderCardColor),
                      ),
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
