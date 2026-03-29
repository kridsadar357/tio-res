/// MenuCategory: Represents a category of menu items
///
/// Examples: Buffet Main, Appetizers, Main Course, Desserts, Drinks, Alcohol
class MenuCategory {
  final int? id;
  final String name; // Primary name (Thai default)
  final String? nameEn; // English name
  final String? nameCn; // Chinese name
  final String? iconPath;

  MenuCategory({
    this.id,
    required this.name,
    this.nameEn,
    this.nameCn,
    this.iconPath,
  });

  /// Create MenuCategory from database map
  factory MenuCategory.fromMap(Map<String, dynamic> map) {
    return MenuCategory(
      id: map['id'] as int,
      name: map['name'] as String,
      nameEn: map['name_en'] as String?,
      nameCn: map['name_cn'] as String?,
      iconPath: map['icon_path'] as String?,
    );
  }

  /// Convert MenuCategory to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'name_cn': nameCn,
      'icon_path': iconPath,
    };
  }

  /// Create a copy with modified fields
  MenuCategory copyWith({
    int? id,
    String? name,
    String? nameEn,
    String? nameCn,
    String? iconPath,
  }) {
    return MenuCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      nameCn: nameCn ?? this.nameCn,
      iconPath: iconPath ?? this.iconPath,
    );
  }

  /// Get localized name based on language code
  String getLocalizedName(String langCode) {
    switch (langCode) {
      case 'en':
        return nameEn ?? name;
      case 'cn':
      case 'zh':
        return nameCn ?? name;
      case 'th':
      default:
        return name;
    }
  }
}
