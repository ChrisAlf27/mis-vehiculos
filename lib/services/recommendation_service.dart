import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/app_settings.dart';
import '../models/appointment.dart';
import '../models/km_reading.dart';
import 'database_service.dart';

class RecommendationService {
  final DatabaseService _db = DatabaseService();

  /// Ventana para el promedio: refleja el uso reciente sin que un viaje largo
  /// aislado lo distorsione demasiado.
  static const _usageWindow = Duration(days: 180);

  /// Con menos de una semana entre lecturas el promedio no es confiable.
  static const _minSpan = Duration(days: 7);

  Future<UsageEstimate?> getUsage(Vehicle vehicle) async =>
      estimateUsage(await _db.getKmReadings(vehicle.id!));

  static UsageEstimate? estimateUsage(List<KmReading> readings) {
    if (readings.length < 2) return null;
    final reference = readings.last;

    final windowStart = reference.date.subtract(_usageWindow);
    var start = readings.firstWhere((r) => !r.date.isBefore(windowStart));
    if (reference.date.difference(start.date) < _minSpan) {
      start = readings.first;
    }

    final span = reference.date.difference(start.date);
    if (span < _minSpan) return null;

    final kmDiff = reference.km - start.km;
    if (kmDiff <= 0) return null;

    return UsageEstimate(
      kmPerDay: kmDiff / (span.inMinutes / (24 * 60)),
      reference: reference,
    );
  }

  Future<List<MaintenanceRecommendation>> getRecommendations(
    Vehicle vehicle, {
    UsageEstimate? usage,
    AppSettings? settings,
  }) async {
    usage ??= await getUsage(vehicle);
    settings ??= await _db.getSettings();

    final types = await _db.getMaintenanceTypes(
      vehicleTypeId: vehicle.vehicleTypeId,
      onlyActive: true,
    );
    final overrides = await _db.getIntervalOverrides(vehicle.id!);
    final lastRecords = await _db.getLastRecordsByType(vehicle.id!);
    // Si un mantenimiento está en más de un turno, vale el más cercano (la
    // lista viene ordenada por fecha).
    final appointments = <String, Appointment>{};
    for (final a in await _db.getAppointments(vehicleId: vehicle.id)) {
      for (final typeId in a.maintenanceTypeIds) {
        appointments.putIfAbsent(typeId, () => a);
      }
    }
    final now = DateTime.now();
    final recommendations = <MaintenanceRecommendation>[];

    for (final type in types) {
      final override = overrides[type.id];
      if (override?.hidden == true) continue;
      final intervalKm = override?.intervalKm ?? type.intervalKm;
      final intervalDays = override?.intervalDays ?? type.intervalDays;
      if (intervalKm <= 0 && intervalDays <= 0) continue;

      final lastRecord = lastRecords[type.id];
      final int nextDueKm;
      final DateTime nextDueDate;
      var pendingRecord = false;

      if (lastRecord != null) {
        nextDueKm = intervalKm > 0
            ? lastRecord.kmAtService + intervalKm
            : vehicle.currentKm + 999999;
        nextDueDate = intervalDays > 0
            ? lastRecord.date.add(Duration(days: intervalDays))
            : now.add(const Duration(days: 99999));
      } else {
        // Nunca registrado: se cuenta desde 0 km y desde el alta del vehículo.
        // Si por ahí ya tocaba, no se puede saber si está vencido o si se hizo
        // antes de usar la app: queda "sin registro" en vez de "vencido".
        nextDueKm = intervalKm > 0 ? intervalKm : vehicle.currentKm + 999999;
        nextDueDate = intervalDays > 0
            ? vehicle.createdAt.add(Duration(days: intervalDays))
            : now.add(const Duration(days: 99999));
        pendingRecord = (intervalKm > 0 && vehicle.currentKm >= nextDueKm) ||
            (intervalDays > 0 && nextDueDate.isBefore(now));
      }

      recommendations.add(MaintenanceRecommendation(
        maintenanceTypeId: type.id,
        maintenanceTypeName: type.name,
        icon: type.icon,
        priority: type.priority,
        intervalKm: intervalKm,
        intervalDays: intervalDays,
        lastKm: lastRecord?.kmAtService,
        lastDate: lastRecord?.date,
        nextDueKm: nextDueKm,
        nextDueDate: nextDueDate,
        currentKm: vehicle.currentKm,
        estimatedKmDate:
            !pendingRecord && intervalKm > 0 && nextDueKm > vehicle.currentKm
                ? usage?.dateForKm(nextDueKm)
                : null,
        pendingRecord: pendingRecord,
        dueSoonKm: settings.dueSoonKm,
        dueSoonDays: settings.dueSoonDays,
        hasOverride: override != null &&
            (override.intervalKm != null || override.intervalDays != null),
        appointment: appointments[type.id],
      ));
    }

    const order = {
      RecommendationStatus.overdue: 0,
      RecommendationStatus.dueSoon: 1,
      RecommendationStatus.pendingRecord: 2,
      RecommendationStatus.ok: 3,
    };
    recommendations.sort((a, b) {
      final byStatus = order[a.status]!.compareTo(order[b.status]!);
      return byStatus != 0
          ? byStatus
          : a.urgencyScore.compareTo(b.urgencyScore);
    });

    return recommendations;
  }
}
