/// Intervalo propio de un mantenimiento para UN vehículo, que pisa el del tipo.
/// Un null deja el valor del tipo; [hidden] saca el mantenimiento de las
/// recomendaciones de ese vehículo (ej. aceite en una moto eléctrica).
class IntervalOverride {
  final int vehicleId;
  final String maintenanceTypeId;
  final int? intervalKm;
  final int? intervalDays;
  final bool hidden;

  const IntervalOverride({
    required this.vehicleId,
    required this.maintenanceTypeId,
    this.intervalKm,
    this.intervalDays,
    this.hidden = false,
  });

  bool get isEmpty => intervalKm == null && intervalDays == null && !hidden;

  Map<String, dynamic> toMap() => {
        'vehicle_id': vehicleId,
        'maintenance_type_id': maintenanceTypeId,
        'interval_km': intervalKm,
        'interval_days': intervalDays,
        'hidden': hidden ? 1 : 0,
      };

  factory IntervalOverride.fromMap(Map<String, dynamic> map) =>
      IntervalOverride(
        vehicleId: map['vehicle_id'] as int,
        maintenanceTypeId: map['maintenance_type_id'] as String,
        intervalKm: map['interval_km'] as int?,
        intervalDays: map['interval_days'] as int?,
        hidden: (map['hidden'] as int? ?? 0) == 1,
      );
}
