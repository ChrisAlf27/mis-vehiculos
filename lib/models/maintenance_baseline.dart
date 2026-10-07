/// Qué se sabe de un mantenimiento de un vehículo usado antes de tener
/// registros propios. Un registro real siempre lo reemplaza.
enum BaselineMode {
  /// Se sabe (aproximado) cuándo se hizo por última vez: [MaintenanceBaseline.km]
  /// y/o [MaintenanceBaseline.date]. Lo que falte se cuenta desde la compra.
  known,

  /// No se sabe y conviene revisarlo: queda en estado "revisar".
  check,

  /// No se sabe y se asume que se hizo al comprarlo.
  assumed,
}

class MaintenanceBaseline {
  final int vehicleId;
  final String maintenanceTypeId;
  final BaselineMode mode;
  final int? km;
  final DateTime? date;

  const MaintenanceBaseline({
    required this.vehicleId,
    required this.maintenanceTypeId,
    required this.mode,
    this.km,
    this.date,
  });

  Map<String, dynamic> toMap() => {
        'vehicle_id': vehicleId,
        'maintenance_type_id': maintenanceTypeId,
        'mode': mode.name,
        'km': mode == BaselineMode.known ? km : null,
        'date': mode == BaselineMode.known ? date?.toIso8601String() : null,
      };

  factory MaintenanceBaseline.fromMap(Map<String, dynamic> map) =>
      MaintenanceBaseline(
        vehicleId: map['vehicle_id'] as int,
        maintenanceTypeId: map['maintenance_type_id'] as String,
        mode: BaselineMode.values.firstWhere((m) => m.name == map['mode'],
            orElse: () => BaselineMode.check),
        km: map['km'] as int?,
        date: map['date'] != null ? DateTime.parse(map['date'] as String) : null,
      );

  /// Lo que se propone de entrada según la prioridad: lo importante se revisa,
  /// el resto se asume hecho.
  static BaselineMode defaultModeFor(String priority) =>
      priority == 'high' ? BaselineMode.check : BaselineMode.assumed;
}
