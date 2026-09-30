/// Tipo de vehículo configurable (auto, moto, camión…). Cada tipo tiene su
/// propia lista de mantenimientos.
class VehicleType {
  final int? id;
  final String name;
  final String icon;
  final int sortOrder;

  const VehicleType({
    this.id,
    required this.name,
    required this.icon,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'sort_order': sortOrder,
      };

  factory VehicleType.fromMap(Map<String, dynamic> map) => VehicleType(
        id: map['id'] as int?,
        name: map['name'] as String,
        icon: map['icon'] as String,
        sortOrder: map['sort_order'] as int? ?? 0,
      );

  VehicleType copyWith({int? id, String? name, String? icon, int? sortOrder}) =>
      VehicleType(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
