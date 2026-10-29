import 'package:flutter/material.dart';
import 'package:meko_poin/models/category.dart';
import 'package:meko_poin/utils/custom_colors.dart';

class CategoryTableSearch extends StatelessWidget {
  final List<Category> currentPageData;
  final List<Category> data;
  final VoidCallback onAddNew;
  final Function(String) onSearch;

  const CategoryTableSearch({
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