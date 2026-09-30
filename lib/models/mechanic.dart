class Mechanic {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;

  const Mechanic({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'notes': notes,
      };

  factory Mechanic.fromMap(Map<String, dynamic> map) => Mechanic(
        id: map['id'] as int?,
        name: map['name'] as String,
        phone: map['phone'] as String?,
        address: map['address'] as String?,
        notes: map['notes'] as String?,
      );
}
