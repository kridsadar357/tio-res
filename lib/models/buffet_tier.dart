/// BuffetTier: Represents a buffet pricing tier
class BuffetTier {
  final int? id;
  final String name;
  final double price;
  final String? description;
  final bool isActive;

  BuffetTier({
    this.id,
    required this.name,
    required this.price,
    this.description,
    this.isActive = true,
  });

  factory BuffetTier.fromMap(Map<String, dynamic> map) {
    return BuffetTier(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      description: map['description'] as String?,
      isActive: (map['is_active'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price': price,
      'description': description,
      'is_active': isActive ? 1 : 0,
    };
  }

  BuffetTier copyWith({
    int? id,
    String? name,
    double? price,
    String? description,
    bool? isActive,
  }) {
    return BuffetTier(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
