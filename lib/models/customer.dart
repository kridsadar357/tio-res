/// Customer: Represents a restaurant customer for loyalty/CRM
class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final int points;
  final int createdAt; // milliseconds since epoch

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.points = 0,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      points: map['points'] as int? ?? 0,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'points': points,
      'created_at': createdAt,
    };
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    int? points,
    int? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  DateTime get createdAtDateTime =>
      DateTime.fromMillisecondsSinceEpoch(createdAt);
}
