class LayoutObjectModel {
  final int? id;
  final String type; // 'wall', 'window', 'plant', 'chair', 'text', 'other'
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final int? color;
  final String? label;
  final int zIndex;
  final int? iconPoint;

  LayoutObjectModel({
    this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
    this.color,
    this.label,
    this.zIndex = 0,
    this.iconPoint,
  });

  factory LayoutObjectModel.fromMap(Map<String, dynamic> map) {
    return LayoutObjectModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      width: (map['width'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
      color: map['color'] as int?,
      label: map['label'] as String?,
      zIndex: map['z_index'] as int? ?? 0,
      iconPoint: map['icon_point'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
      'color': color,
      'label': label,
      'z_index': zIndex,
      'icon_point': iconPoint,
    };
  }

  LayoutObjectModel copyWith({
    int? id,
    String? type,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    int? color,
    String? label,
    int? zIndex,
    int? iconPoint,
  }) {
    return LayoutObjectModel(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
      label: label ?? this.label,
      zIndex: zIndex ?? this.zIndex,
      iconPoint: iconPoint ?? this.iconPoint,
    );
  }
}
