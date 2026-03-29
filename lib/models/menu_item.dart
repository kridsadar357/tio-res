/// MenuItem: Represents an item on the restaurant menu
///
/// Key features:
/// - price: 0.0 for items included in buffet, >0 for extra chargeable items
/// - imagePath: Local file path to stored image (null if no image)
/// - isBuffetIncluded: Helps with reporting and filtering
class MenuItem {
  final int? id; // Null when creating new item
  final String name;
  final String? nameEn;
  final String? nameTh;
  final String? nameCn;
  final int categoryId;
  final double price;
  final String? imagePath;
  final bool isBuffetIncluded;
  final String? description;
  final String? sku;
  final int status; // 1 = Active, 0 = Sold Out

  MenuItem({
    this.id,
    required this.name,
    this.nameEn,
    this.nameTh,
    this.nameCn,
    required this.categoryId,
    required this.price,
    this.imagePath,
    this.isBuffetIncluded = true,
    this.description,
    this.sku,
    this.status = 1,
  });

  /// Create MenuItem from database map
  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'] as int,
      name: map['name'] as String,
      nameEn: map['name_en'] as String?,
      nameTh: map['name_th'] as String?,
      nameCn: map['name_cn'] as String?,
      categoryId: map['category_id'] as int,
      price: (map['price'] as num).toDouble(),
      imagePath: map['image_path'] as String?,
      isBuffetIncluded: (map['is_buffet_included'] as int) == 1,
      description: map['description'] as String?,
      sku: map['sku'] as String?,
      status: map['status'] as int? ?? 1,
    );
  }

  /// Convert MenuItem to database map
  /// Note: isBuffetIncluded is converted to integer for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'name_en': nameEn,
      'name_th': nameTh,
      'name_cn': nameCn,
      'category_id': categoryId,
      'price': price,
      'image_path': imagePath,
      'is_buffet_included': isBuffetIncluded ? 1 : 0,
      'description': description,
      'sku': sku,
      'status': status,
    };
  }

  /// Create a copy with modified fields
  MenuItem copyWith({
    int? id,
    String? name,
    String? nameEn,
    String? nameTh,
    String? nameCn,
    int? categoryId,
    double? price,
    String? imagePath,
    bool? isBuffetIncluded,
    String? description,
    String? sku,
    int? status,
    bool clearImagePath = false,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      nameTh: nameTh ?? this.nameTh,
      nameCn: nameCn ?? this.nameCn,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      isBuffetIncluded: isBuffetIncluded ?? this.isBuffetIncluded,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      status: status ?? this.status,
    );
  }

  /// Check if item has an extra charge (not included in buffet)
  bool get hasExtraCharge => price > 0;

  /// Get formatted price string
  String get formattedPrice =>
      hasExtraCharge ? '\$${price.toStringAsFixed(2)}' : 'Included';

  /// Check if item has an image
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  /// Check if item is available
  bool get isAvailable => status == 1;
}
