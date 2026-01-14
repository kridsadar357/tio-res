/// TableModel: Represents a dining table in the restaurant
///
/// Status codes:
/// - 0: Available (Green)
/// - 1: Occupied/Eating (Red)
/// - 2: Cleaning (Yellow)
class TableModel {
  final int id;
  final String tableName;
  final int status;
  final int? currentOrderId;
  final double? totalAmount;

  // Layout properties
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final String shape;
  final int color;

  TableModel({
    required this.id,
    required this.tableName,
    required this.status,
    this.currentOrderId,
    this.totalAmount,
    this.x = 0,
    this.y = 0,
    this.width = 80,
    this.height = 80,
    this.rotation = 0,
    this.shape = 'rectangle',
    this.color = 0xFF4CAF50, // Default Green
  });

  /// Create TableModel from database map
  factory TableModel.fromMap(Map<String, dynamic> map) {
    return TableModel(
      id: map['id'] as int,
      tableName: map['table_name'] as String,
      status: map['status'] as int,
      currentOrderId: map['current_order_id'] as int?,
      totalAmount: map['current_total_amount'] != null
          ? (map['current_total_amount'] as num).toDouble()
          : null,
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      width: (map['width'] as num?)?.toDouble() ?? 80.0,
      height: (map['height'] as num?)?.toDouble() ?? 80.0,
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
      shape: map['shape'] as String? ?? 'rectangle',
      color: map['color'] as int? ?? 0xFF4CAF50,
    );
  }

  /// Convert TableModel to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_name': tableName,
      'status': status,
      'current_order_id': currentOrderId,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
      'shape': shape,
      'color': color,
    };
  }

  /// Create a copy with modified fields (useful for state management)
  TableModel copyWith({
    int? id,
    String? tableName,
    int? status,
    int? currentOrderId,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    String? shape,
    int? color,
  }) {
    return TableModel(
      id: id ?? this.id,
      tableName: tableName ?? this.tableName,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      shape: shape ?? this.shape,
      color: color ?? this.color,
    );
  }

  /// Check if table is available
  bool get isAvailable => status == 0;

  /// Check if table is occupied
  bool get isOccupied => status == 1;

  /// Check if table is being cleaned
  bool get isCleaning => status == 2;

  /// Get human-readable status text
  String get statusText {
    switch (status) {
      case 0:
        return 'Available';
      case 1:
        return 'Occupied';
      case 2:
        return 'Cleaning';
      default:
        return 'Unknown';
    }
  }
}
