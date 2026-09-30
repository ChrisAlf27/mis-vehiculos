import 'appointment.dart';

class MaintenanceRecord {
  final int? id;
  final int vehicleId;
  final String maintenanceTypeId;
  final DateTime date;
  final int kmAtService;
  final double? cost;
  final String? mechanic;
  final String? productsUsed;
  final String? notes;
  final DateTime createdAt;

  MaintenanceRecord({
    this.id,
    required this.vehicleId,
    required this.maintenanceTypeId,
    required this.date,
    required this.kmAtService,
    this.cost,
    this.mechanic,
    this.productsUsed,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'maintenance_type_id': maintenanceTypeId,
        'date': date.toIso8601String(),
        'km_at_service': kmAtService,
        'cost': cost,
        'mechanic': mechanic,
        'products_used': productsUsed,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory MaintenanceRecord.fromMap(Map<String, dynamic> map) =>
      MaintenanceRecord(
        id: map['id'] as int?,
        vehicleId: map['vehicle_id'] as int,
        maintenanceTypeId: map['maintenance_type_id'] as String,
        date: DateTime.parse(map['date'] as String),
        kmAtService: map['km_at_service'] as int,
        cost: map['cost'] != null ? (map['cost'] as num).toDouble() : null,
        mechanic: map['mechanic'] as String?,
        productsUsed: map['products_used'] as String?,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  MaintenanceRecord copyWith({
    int? id,
    int? vehicleId,
    String? maintenanceTypeId,
    DateTime? date,
    int? kmAtService,
    double? cost,
    String? mechanic,
    String? productsUsed,
    String? notes,
  }) =>
      MaintenanceRecord(
        id: id ?? this.id,
        vehicleId: vehicleId ?? this.vehicleId,
        maintenanceTypeId: maintenanceTypeId ?? this.maintenanceTypeId,
        date: date ?? this.date,
        kmAtService: kmAtService ?? this.kmAtService,
        cost: cost ?? this.cost,
        mechanic: mechanic ?? this.mechanic,
        productsUsed: productsUsed ?? this.productsUsed,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );
}

enum RecommendationStatus { overdue, dueSoon, pendingRecord, ok }

class MaintenanceRecommendation {
  final String maintenanceTypeId;
  final String maintenanceTypeName;
  final String icon;
  final String priority;
  final int intervalKm;
  final int intervalDays;
  final int? lastKm;
  final DateTime? lastDate;
  final int nextDueKm;
  final DateTime nextDueDate;
  final int currentKm;

  /// Cuándo se llegaría a [nextDueKm] según el uso promedio. Null si no hay
  /// suficientes lecturas de km para estimarlo.
  final DateTime? estimatedKmDate;

  /// Nunca se registró y, contando desde 0 km / desde el alta del vehículo,
  /// ya tendría que haberse hecho: no se sabe si está vencido o si se hizo
  /// antes de usar la app, así que se pide cargar el último servicio.
  final bool pendingRecord;

  final int dueSoonKm;
  final int dueSoonDays;

  /// Intervalos propios de este vehículo en vez de los del tipo.
  final bool hasOverride;

  final Appointment? appointment;

  MaintenanceRecommendation({
    required this.maintenanceTypeId,
    required this.maintenanceTypeName,
    required this.icon,
    required this.priority,
    required this.intervalKm,
    required this.intervalDays,
    this.lastKm,
    this.lastDate,
    required this.nextDueKm,
    required this.nextDueDate,
    required this.currentKm,
    this.estimatedKmDate,
    this.pendingRecord = false,
    this.dueSoonKm = 500,
    this.dueSoonDays = 14,
    this.hasOverride = false,
    this.appointment,
  });

  int get kmRemaining => nextDueKm - currentKm;
  int get daysRemaining => nextDueDate.difference(DateTime.now()).inDays;

  int? get estimatedDaysRemaining => estimatedKmDate == null
      ? null
      : estimatedKmDate!.difference(DateTime.now()).inDays;

  bool get isOverdueKm => kmRemaining < 0 && intervalKm > 0;
  bool get isOverdueDate => daysRemaining < 0 && intervalDays > 0;
  bool get isOverdue => !pendingRecord && (isOverdueKm || isOverdueDate);

  // La estimación por uso sólo adelanta el aviso a "próximo": vencido se
  // decide con el km real cargado, nunca con uno proyectado.
  bool get isDueSoonByUsage =>
      intervalKm > 0 &&
      estimatedDaysRemaining != null &&
      estimatedDaysRemaining! < dueSoonDays;

  bool get isDueSoon =>
      !pendingRecord &&
      !isOverdue &&
      ((intervalKm > 0 && kmRemaining < dueSoonKm) ||
          (intervalDays > 0 && daysRemaining < dueSoonDays) ||
          isDueSoonByUsage);

  RecommendationStatus get status {
    if (pendingRecord) return RecommendationStatus.pendingRecord;
    if (isOverdue) return RecommendationStatus.overdue;
    if (isDueSoon) return RecommendationStatus.dueSoon;
    return RecommendationStatus.ok;
  }

  /// La primera fecha en la que toca, por tiempo o por uso estimado.
  DateTime? get expectedDate {
    final byDate = intervalDays > 0 ? nextDueDate : null;
    final byKm = estimatedKmDate;
    if (byDate == null) return byKm;
    if (byKm == null) return byDate;
    return byKm.isBefore(byDate) ? byKm : byDate;
  }

  /// urgency score for sorting (lower = more urgent)
  double get urgencyScore {
    double score = 0;
    if (intervalKm > 0) score += kmRemaining / intervalKm;
    if (intervalDays > 0) score += daysRemaining / intervalDays;
    return score;
  }
}
