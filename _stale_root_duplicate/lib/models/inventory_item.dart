class InventoryItem {
  final String? id;
  final String warehouseId;
  final String itemName;
  final String category;
  final int quantity;
  final String unit;
  final int lowStockThreshold;

  const InventoryItem({
    this.id,
    required this.warehouseId,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.lowStockThreshold,
  });

  factory InventoryItem.fromJson(String id, Map<String, dynamic> json) {
    return InventoryItem(
      id: id,
      warehouseId: json['warehouseId'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      category: json['category'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String? ?? '',
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warehouseId': warehouseId,
      'itemName': itemName,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'lowStockThreshold': lowStockThreshold,
    };
  }

  InventoryItem copyWith({
    String? id,
    String? warehouseId,
    String? itemName,
    String? category,
    int? quantity,
    String? unit,
    int? lowStockThreshold,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      warehouseId: warehouseId ?? this.warehouseId,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }

  static const List<String> categories = [
    'Food',
    'Water',
    'Medicine',
    'Shelter',
    'Clothing',
  ];
}
