import 'dart:math';

enum ReceiptComponentType {
  header,
  text,
  divider,
  image,
  barcode,
  qrcode,
  space,
  dynamicItems, // The list of order items
  dynamicTotal, // The total/tax summary
  // Store Info components (auto-filled from settings)
  shopLogo,     // Shop logo image
  shopName,     // Shop name from settings
  shopAddress,  // Shop address from settings
  shopTel,      // Shop telephone from settings
}

enum ReceiptAlignment {
  left,
  center,
  right,
}

/// Represents a single element on the receipt
class ReceiptComponent {
  final String id;
  final ReceiptComponentType type;
  Map<String, dynamic> data;
  Map<String, dynamic> style;

  ReceiptComponent({
    required this.id,
    required this.type,
    Map<String, dynamic>? data,
    Map<String, dynamic>? style,
  })  : data = data ?? {},
        style = style ?? {};

  // Factory for creating default components
  factory ReceiptComponent.create(ReceiptComponentType type) {
    final id =
        '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(10000)}';
    switch (type) {
      case ReceiptComponentType.header:
        return ReceiptComponent(
          id: id,
          type: type,
          data: {'text': 'Store Name'},
          style: {'fontSize': 24, 'alignment': 'center', 'bold': true},
        );
      case ReceiptComponentType.text:
        return ReceiptComponent(
          id: id,
          type: type,
          data: {'text': 'Custom Text'},
          style: {'fontSize': 14, 'alignment': 'left', 'bold': false},
        );
      case ReceiptComponentType.divider:
        return ReceiptComponent(
          id: id,
          type: type,
          data: {'char': '-'},
          style: {'alignment': 'center'},
        );
      case ReceiptComponentType.space:
        return ReceiptComponent(
          id: id,
          type: type,
          data: {},
          style: {'height': 20},
        );
      case ReceiptComponentType.image:
        return ReceiptComponent(
          id: id,
          type: type,
          data: {'path': null}, // Placeholder
          style: {'alignment': 'center', 'width': 100},
        );
      case ReceiptComponentType.qrcode:
        return ReceiptComponent(
          id: id,
          type: type,
          data: {'payload': 'https://respos.app'},
          style: {'alignment': 'center', 'size': 6}, // esc_pos_utils size 1-8
        );
      case ReceiptComponentType.dynamicItems:
        return ReceiptComponent(
          id: id,
          type: type,
          data: {'label': 'Order Items'},
          style: {'fontSize': 12}, // Base font size for items
        );
      case ReceiptComponentType.dynamicTotal:
        return ReceiptComponent(
          id: id,
          type: type,
          data: {'label': 'Totals'},
          style: {'fontSize': 12},
        );
      case ReceiptComponentType.shopLogo:
        return ReceiptComponent(
          id: id,
          type: type,
          data: {'useSettings': true}, // Auto-load from settings
          style: {'alignment': 'center', 'width': 150},
        );
      case ReceiptComponentType.shopName:
        return ReceiptComponent(
          id: id,
          type: type,
          data: {'useSettings': true}, // Auto-load from settings
          style: {'fontSize': 24, 'alignment': 'center', 'bold': true},
        );
      case ReceiptComponentType.shopAddress:
        return ReceiptComponent(
          id: id,
          type: type,
          data: {'useSettings': true},
          style: {'fontSize': 12, 'alignment': 'center', 'bold': false},
        );
      case ReceiptComponentType.shopTel:
        return ReceiptComponent(
          id: id,
          type: type,
          data: {'useSettings': true},
          style: {'fontSize': 12, 'alignment': 'center', 'bold': false},
        );
      default:
        return ReceiptComponent(id: id, type: type);
    }
  }

  ReceiptComponent copyWith({
    Map<String, dynamic>? data,
    Map<String, dynamic>? style,
  }) {
    return ReceiptComponent(
      id: id,
      type: type,
      data: data ?? Map.from(this.data),
      style: style ?? Map.from(this.style),
    );
  }

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name, // Store enum as string
      'data': data,
      'style': style,
    };
  }

  factory ReceiptComponent.fromJson(Map<String, dynamic> json) {
    return ReceiptComponent(
      id: json['id'] as String,
      type: ReceiptComponentType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => ReceiptComponentType.text,
      ),
      data: Map<String, dynamic>.from(json['data'] as Map<dynamic, dynamic>? ?? {}),
      style: Map<String, dynamic>.from(json['style'] as Map<dynamic, dynamic>? ?? {}),
    );
  }
}

/// Represents the entire receipt layout configuration
class ReceiptLayout {
  final int paperSizeMm; // 58 or 80
  final List<ReceiptComponent> components;

  ReceiptLayout({
    this.paperSizeMm = 80,
    required this.components,
  });

  ReceiptLayout copyWith({
    int? paperSizeMm,
    List<ReceiptComponent>? components,
  }) {
    return ReceiptLayout(
      paperSizeMm: paperSizeMm ?? this.paperSizeMm,
      components: components ?? List.from(this.components),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paperSizeMm': paperSizeMm,
      'components': components.map((c) => c.toJson()).toList(),
    };
  }

  factory ReceiptLayout.fromJson(Map<String, dynamic> json) {
    return ReceiptLayout(
      paperSizeMm: (json['paperSizeMm'] as num?)?.toInt() ?? 80,
      components: (json['components'] as List<dynamic>?)
              ?.map((c) =>
                  ReceiptComponent.fromJson(Map<String, dynamic>.from(c as Map<dynamic, dynamic>)))
              .toList() ??
          [],
    );
  }

  // Helper to create a default starter layout
  factory ReceiptLayout.defaultLayout() {
    return ReceiptLayout(
      components: [
        ReceiptComponent.create(ReceiptComponentType.header)
          ..data['text'] = 'My Restaurant',
        ReceiptComponent.create(ReceiptComponentType.text)
          ..data['text'] = '123 Food Street\nCity, Country',
        ReceiptComponent.create(ReceiptComponentType.divider),
        ReceiptComponent.create(ReceiptComponentType.dynamicItems),
        ReceiptComponent.create(ReceiptComponentType.divider),
        ReceiptComponent.create(ReceiptComponentType.dynamicTotal),
        ReceiptComponent.create(ReceiptComponentType.space),
        ReceiptComponent.create(ReceiptComponentType.text)
          ..data['text'] = 'Thank you for dining with us!',
        ReceiptComponent.create(ReceiptComponentType.text)
          ..style['alignment'] = 'center'
          ..data['text'] = 'Visit again',
      ],
    );
  }
}
