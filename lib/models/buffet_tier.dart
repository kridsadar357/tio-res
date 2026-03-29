import 'dart:convert';

/// BuffetTier: Represents a buffet pricing tier
class BuffetTier {
  final int? id;
  final String name;
  final double price;
  final String? description;
  final bool isActive;
  final List<int> excludedCategoryIds; // Categories hidden for this tier

  BuffetTier({
    this.id,
    required this.name,
    required this.price,
    this.description,
    this.isActive = true,
    this.excludedCategoryIds = const [],
  });

  factory BuffetTier.fromMap(Map<String, dynamic> map) {
    // Parse excluded_category_ids from JSON string or null
    List<int> excluded = [];
    final excludedRaw = map['excluded_category_ids'];
    if (excludedRaw != null && excludedRaw is String && excludedRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(excludedRaw);
        if (decoded is List) {
          excluded = decoded.map((e) => e as int).toList();
        }
      } catch (_) {
        // Fallback: try comma-separated
        excluded = excludedRaw.split(',').map((s) => int.tryParse(s.trim()) ?? 0).where((i) => i > 0).toList();
      }
    }
    
    return BuffetTier(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      description: map['description'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      excludedCategoryIds: excluded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price': price,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'excluded_category_ids': excludedCategoryIds.isEmpty ? null : jsonEncode(excludedCategoryIds),
    };
  }

  BuffetTier copyWith({
    int? id,
    String? name,
    double? price,
    String? description,
    bool? isActive,
    List<int>? excludedCategoryIds,
  }) {
    return BuffetTier(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      excludedCategoryIds: excludedCategoryIds ?? this.excludedCategoryIds,
    );
  }
}
