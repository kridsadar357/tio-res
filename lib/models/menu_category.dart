/// MenuCategory: Represents a category of menu items
///
/// Examples: Buffet Main, Appetizers, Main Course, Desserts, Drinks, Alcohol
class MenuCategory {
  final int? id;
  final String name;
  final String? iconPath;

  MenuCategory({
    this.id,
    required this.name,
    this.iconPath,
  });

  /// Create MenuCategory from database map
  factory MenuCategory.fromMap(Map<String, dynamic> map) {
    return MenuCategory(
      id: map['id'] as int,
      name: map['name'] as String,
      iconPath: map['icon_path'] as String?,
    );
  }

  /// Convert MenuCategory to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_path': iconPath,
    };
  }

  /// Create a copy with modified fields
  MenuCategory copyWith({
    int? id,
    String? name,
    String? iconPath,
  }) {
    return MenuCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconPath: iconPath ?? this.iconPath,
    );
  }
}
