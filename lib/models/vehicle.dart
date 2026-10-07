class Vehicle {
  final int? id;
  final String name;
  final int vehicleTypeId;
  final String brand;
  final String model;
  final int year;
  final String licensePlate;
  int currentKm;
  final String? photoPath;
  final DateTime createdAt;

  /// Recordatorio semanal que pregunta el km actual.
  final bool kmReminderEnabled;

  /// 1 = lunes … 7 = domingo (igual que DateTime.weekday).
  final int kmReminderWeekday;
  final int kmReminderHour;
  final int kmReminderMinute;

  /// Comprado usado: su historial anterior se completa con puntos de partida
  /// ([MaintenanceBaseline]) en vez de contar desde 0 km.
  final bool used;

  /// Cuándo y con cuántos km se compró (sólo usados). Sin fecha vale el alta.
  final DateTime? acquiredAt;
  final int? acquiredKm;

  Vehicle({
    this.id,
    required this.name,
    required this.vehicleTypeId,
    required this.brand,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.currentKm,
    this.photoPath,
    DateTime? createdAt,
    this.kmReminderEnabled = false,
    this.kmReminderWeekday = DateTime.sunday,
    this.kmReminderHour = 20,
    this.kmReminderMinute = 0,
    this.used = false,
    this.acquiredAt,
    this.acquiredKm,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        // Columna heredada de la versión 1 (NOT NULL); el tipo real es vehicle_type_id.
        'type': 'custom',
        'vehicle_type_id': vehicleTypeId,
        'brand': brand,
        'model': model,
        'year': year,
        'license_plate': licensePlate,
        'current_km': currentKm,
        'photo_path': photoPath,
        'created_at': createdAt.toIso8601String(),
        'km_reminder_enabled': kmReminderEnabled ? 1 : 0,
        'km_reminder_weekday': kmReminderWeekday,
        'km_reminder_hour': kmReminderHour,
        'km_reminder_minute': kmReminderMinute,
        'used': used ? 1 : 0,
        'acquired_at': acquiredAt?.toIso8601String(),
        'acquired_km': acquiredKm,
      };

  factory Vehicle.fromMap(Map<String, dynamic> map) => Vehicle(
        id: map['id'] as int?,
        name: map['name'] as String,
        vehicleTypeId: map['vehicle_type_id'] as int,
        brand: map['brand'] as String,
        model: map['model'] as String,
        year: map['year'] as int,
        licensePlate: map['license_plate'] as String,
        currentKm: map['current_km'] as int,
        photoPath: map['photo_path'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        kmReminderEnabled: (map['km_reminder_enabled'] as int? ?? 0) == 1,
        kmReminderWeekday:
            map['km_reminder_weekday'] as int? ?? DateTime.sunday,
        kmReminderHour: map['km_reminder_hour'] as int? ?? 20,
        kmReminderMinute: map['km_reminder_minute'] as int? ?? 0,
        used: (map['used'] as int? ?? 0) == 1,
        acquiredAt: map['acquired_at'] != null
            ? DateTime.parse(map['acquired_at'] as String)
            : null,
        acquiredKm: map['acquired_km'] as int?,
      );

  Vehicle copyWith({
    int? id,
    String? name,
    int? vehicleTypeId,
    String? brand,
    String? model,
    int? year,
    String? licensePlate,
    int? currentKm,
    String? photoPath,
    bool? kmReminderEnabled,
    int? kmReminderWeekday,
    int? kmReminderHour,
    int? kmReminderMinute,
    bool? used,
    DateTime? acquiredAt,
    int? acquiredKm,
  }) =>
      Vehicle(
        id: id ?? this.id,
        name: name ?? this.name,
        vehicleTypeId: vehicleTypeId ?? this.vehicleTypeId,
        brand: brand ?? this.brand,
        model: model ?? this.model,
        year: year ?? this.year,
        licensePlate: licensePlate ?? this.licensePlate,
        currentKm: currentKm ?? this.currentKm,
        photoPath: photoPath ?? this.photoPath,
        createdAt: createdAt,
        kmReminderEnabled: kmReminderEnabled ?? this.kmReminderEnabled,
        kmReminderWeekday: kmReminderWeekday ?? this.kmReminderWeekday,
        kmReminderHour: kmReminderHour ?? this.kmReminderHour,
        kmReminderMinute: kmReminderMinute ?? this.kmReminderMinute,
        used: used ?? this.used,
        acquiredAt: acquiredAt ?? this.acquiredAt,
        acquiredKm: acquiredKm ?? this.acquiredKm,
      );

  /// Desde dónde se cuenta lo que se asume hecho al comprarlo.
  DateTime get acquiredDate => acquiredAt ?? createdAt;
  int get acquiredOdometer => acquiredKm ?? currentKm;

  @override
  String toString() => '$name ($brand $model $year)';
}
