class FavoriteProduct {
  final String name;
  final String category;
  final int totalQty;
  final int totalSales;

  FavoriteProduct({
    required this.name,
    required this.category,
    required this.totalQty,
    required this.totalSales,
  });

  factory FavoriteProduct.fromMap(Map<String, dynamic> map) {
    return FavoriteProduct(
      name: map['name'],
      category: map['category'],
      totalQty: map['total_qty'],
      totalSales: map['total_sales'],
    );
  }
}
