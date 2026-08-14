import 'package:flutter/material.dart';
import 'package:meko_poin/models/category.dart';
import 'package:meko_poin/services/category_repository.dart';
import 'package:meko_poin/utils/custom_colors.dart';
import 'package:meko_poin/views/Dashboard/components/table/category_table/category_table_header.dart';
import 'package:meko_poin/views/Dashboard/components/table/category_table/category_table_pagination.dart';
import 'package:meko_poin/views/Dashboard/components/table/category_table/category_table_row.dart';
import 'package:meko_poin/views/Dashboard/components/table/category_table/category_table_search.dart';

class CategoryTable extends StatefulWidget {
  final VoidCallback onAddNew;
  final CategoryRepository categoryRepository;
  final Function(Category) onEditCategory;
  final Function(Category) onDeleteCategory;

  const CategoryTable({
    super.key,
    required this.onAddNew,
    required this.categoryRepository,
    required this.onEditCategory,
    required this.onDeleteCategory,
  });

  @override
  State<CategoryTable> createState() => _CategoryTableState();
}

class _CategoryTableState extends State<CategoryTable> {
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  int itemsPerPage = 10;
  List<Category> _categoryList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String sortBy = 'name';
  bool isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void didUpdateWidget(covariant CategoryTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadCategories();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final allData = await widget.categoryRepository.getAllCategories();
      setState(() => _categoryList = allData);
    } catch (e) {
      debugPrint('Error loading categories: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Category> get filteredCategories {
    if (_searchQuery.isEmpty) return _categoryList;
    return _categoryList
        .where((category) => category.name
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<Category> get sortedCategories {
    List<Category> sorted = List.from(filteredCategories);
    sorted.sort((a, b) {
      int result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return isAscending ? result : -result;
    });
    return sorted;
  }

  List<Category> get currentPageData {
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    return sortedCategories.sublist(
        start, end > sortedCategories.length ? sortedCategories.length : end);
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
    final totalPages = (sortedCategories.length / itemsPerPage).ceil();
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage > sortedCategories.length)
        ? sortedCategories.length
        : currentPage * itemsPerPage;

    return Container(
      decoration: BoxDecoration(
        color: CustomColors.cardColor,
        border: Border.all(color: CustomColors.borderCardColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Bar
          CategoryTableSearch(
            currentPageData: currentPageData,
            data: sortedCategories,
            onAddNew: widget.onAddNew,
            onSearch: (query) {
              setState(() {
                _searchQuery = query;
                currentPage = 1;
              });
            },
          ),

          // Header
          CategoryTableHeader(
            sortBy: sortBy,
            isAscending: isAscending,
            onSort: onSort,
            sortIcon: _sortIcon,
          ),

          // Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : sortedCategories.isEmpty
                    ? const Center(child: Text('Tidak ada data kategori'))
                    : Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: currentPageData
                                .map((category) => CategoryTableRow(
                                      category: category,
                                      key: ValueKey(category.id),
                                      onEdit: () => widget
                                          .onEditCategory(category),
                                      onDelete: () => widget
                                          .onDeleteCategory(category),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
          ),

          // Pagination
          if (!_isLoading && sortedCategories.isNotEmpty)
            CategoryTablePagination(
              currentPage: currentPage,
              totalPages: totalPages,
              startItem: startItem,
              endItem: endItem,
              data: sortedCategories,
              itemsPerPage: itemsPerPage,
              onItemsPerPageChanged: (value) {
                setState(() {
                  itemsPerPage = value;
                  currentPage = 1;
                });
              },
              onPageChanged: (page) {
                setState(() => currentPage = page);
              },
            ),
        ],
      ),
    );
  }
}
