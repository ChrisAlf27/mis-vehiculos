/// Un turno con el mecánico para un vehículo, con los mantenimientos que se
/// le van a hacer. Mientras un mantenimiento está en un turno, su aviso
/// automático por tiempo o km no se programa: lo reemplaza el del turno.
class Appointment {
  final int? id;
  final int vehicleId;
  final DateTime scheduledAt;
  final String? mechanic;
  final String? notes;

  /// 0 = a la hora del turno, 60 = una hora antes, 1440 = un día antes.
  final int remindMinutesBefore;

  final List<String> maintenanceTypeIds;

  const Appointment({
    this.id,
    required this.vehicleId,
    required this.scheduledAt,
    this.mechanic,
    this.notes,
    this.remindMinutesBefore = 1440,
    this.maintenanceTypeIds = const [],
  });

  static const remindOptions = [0, 60, 1440];

  DateTime get remindAt =>
      scheduledAt.subtract(Duration(minutes: remindMinutesBefore));

  bool get isPast => scheduledAt.isBefore(DateTime.now());

  /// Sólo la fila de `appointments`; los mantenimientos van en
  /// `appointment_items`.
  Map<String, dynamic> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'mechanic': mechanic,
        'notes': notes,
        'remind_minutes_before': remindMinutesBefore,
      };

  factory Appointment.fromMap(
    Map<String, dynamic> map, {
    List<String> maintenanceTypeIds = const [],
  }) =>
      Appointment(
        id: map['id'] as int?,
        vehicleId: map['vehicle_id'] as int,
        scheduledAt: DateTime.parse(map['scheduled_at'] as String),
        mechanic: map['mechanic'] as String?,
        notes: map['notes'] as String?,
        remindMinutesBefore: map['remind_minutes_before'] as int? ?? 1440,
        maintenanceTypeIds: maintenanceTypeIds,
      );
}
