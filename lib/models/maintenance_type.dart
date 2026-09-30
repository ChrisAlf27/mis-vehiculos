/// Un mantenimiento configurable, propio de un tipo de vehículo.
class MaintenanceType {
  /// Texto a propósito: los registros viejos guardan ids como 'car_oil_change'.
  final String id;
  final int vehicleTypeId;
  final String name;
  final String description;
  final String icon;

  /// 0 = no se controla por km / por tiempo.
  final int intervalKm;
  final int intervalDays;

  /// 'high' | 'medium' | 'low'
  final String priority;

  /// Uno inactivo no se ofrece al cargar ni se recomienda, pero su historial
  /// sigue visible.
  final bool active;
  final int sortOrder;

  const MaintenanceType({
    required this.id,
    required this.vehicleTypeId,
    required this.name,
    this.description = '',
    this.icon = '🔧',
    this.intervalKm = 0,
    this.intervalDays = 0,
    this.priority = 'medium',
    this.active = true,
    this.sortOrder = 0,
  });

  bool get isTracked => intervalKm > 0 || intervalDays > 0;

  static String newId() => 'custom_${DateTime.now().microsecondsSinceEpoch}';

  Map<String, dynamic> toMap() => {
        'id': id,
        'vehicle_type_id': vehicleTypeId,
        'name': name,
        'description': description,
        'icon': icon,
        'interval_km': intervalKm,
        'interval_days': intervalDays,
        'priority': priority,
        'active': active ? 1 : 0,
        'sort_order': sortOrder,
      };

  factory MaintenanceType.fromMap(Map<String, dynamic> map) => MaintenanceType(
        id: map['id'] as String,
        vehicleTypeId: map['vehicle_type_id'] as int,
        name: map['name'] as String,
        description: map['description'] as String? ?? '',
        icon: map['icon'] as String? ?? '🔧',
        intervalKm: map['interval_km'] as int? ?? 0,
        intervalDays: map['interval_days'] as int? ?? 0,
        priority: map['priority'] as String? ?? 'medium',
        active: (map['active'] as int? ?? 1) == 1,
        sortOrder: map['sort_order'] as int? ?? 0,
      );

  MaintenanceType copyWith({
    String? name,
    String? description,
    String? icon,
    int? intervalKm,
    int? intervalDays,
    String? priority,
    bool? active,
    int? sortOrder,
  }) =>
      MaintenanceType(
        id: id,
        vehicleTypeId: vehicleTypeId,
        name: name ?? this.name,
        description: description ?? this.description,
        icon: icon ?? this.icon,
        intervalKm: intervalKm ?? this.intervalKm,
        intervalDays: intervalDays ?? this.intervalDays,
        priority: priority ?? this.priority,
        active: active ?? this.active,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
