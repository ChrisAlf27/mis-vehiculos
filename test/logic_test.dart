import 'package:flutter_test/flutter_test.dart';
import 'package:vehiculos_app/data/default_catalog.dart';
import 'package:vehiculos_app/models/app_settings.dart';
import 'package:vehiculos_app/models/km_reading.dart';
import 'package:vehiculos_app/models/maintenance_baseline.dart';
import 'package:vehiculos_app/models/vehicle.dart';
import 'package:vehiculos_app/models/maintenance_record.dart';
import 'package:vehiculos_app/services/recommendation_service.dart';

void main() {
  group('parseKm', () {
    test('acepta números con y sin separador de miles', () {
      expect(parseKm('45000'), 45000);
      expect(parseKm(' 45.000 '), 45000);
      expect(parseKm('45,000'), 45000);
      expect(parseKm('1 234 567'), 1234567);
    });

    test('rechaza lo que no es claramente un km', () {
      for (final text in ['', 'hola', '4k', '4,1', '45.00', '12a', null]) {
        expect(parseKm(text), isNull, reason: '"$text"');
      }
    });
  });

  group('estimateUsage', () {
    final d0 = DateTime(2026, 1, 1);

    test('necesita al menos una semana entre lecturas', () {
      expect(
        RecommendationService.estimateUsage([
          KmReading(date: d0, km: 1000),
          KmReading(date: d0.add(const Duration(days: 3)), km: 1300),
        ]),
        isNull,
      );
    });

    test('promedia km por día y proyecta hacia adelante', () {
      final usage = RecommendationService.estimateUsage([
        KmReading(date: d0, km: 1000),
        KmReading(date: d0.add(const Duration(days: 10)), km: 1500),
      ])!;
      expect(usage.kmPerDay, closeTo(50, 0.001));
      expect(usage.kmPerWeek, closeTo(350, 0.001));
      expect(usage.dateForKm(2000), d0.add(const Duration(days: 20)));
    });

    test('un odómetro que no avanza no da estimación', () {
      expect(
        RecommendationService.estimateUsage([
          KmReading(date: d0, km: 1000),
          KmReading(date: d0.add(const Duration(days: 30)), km: 1000),
        ]),
        isNull,
      );
    });
  });

  group('MaintenanceRecommendation.status', () {
    MaintenanceRecommendation rec({
      required int nextDueKm,
      required int currentKm,
      bool pending = false,
      BaselineMode? baseline,
      int dueSoonKm = 500,
    }) =>
        MaintenanceRecommendation(
          maintenanceTypeId: 'x',
          maintenanceTypeName: 'X',
          icon: '🔧',
          priority: 'high',
          intervalKm: 3000,
          intervalDays: 0,
          nextDueKm: nextDueKm,
          nextDueDate: DateTime.now().add(const Duration(days: 9999)),
          currentKm: currentKm,
          pendingRecord: pending,
          baseline: baseline,
          dueSoonKm: dueSoonKm,
        );

    test('sin registro nunca figura como vencido', () {
      final r = rec(nextDueKm: 3000, currentKm: 4100, pending: true);
      expect(r.status, RecommendationStatus.pendingRecord);
      expect(r.isOverdue, isFalse);
    });

    test('"revisar" no figura como vencido ni próximo', () {
      final r = rec(
          nextDueKm: 80000, currentKm: 80000, baseline: BaselineMode.check);
      expect(r.status, RecommendationStatus.needsCheck);
      expect(r.isOverdue, isFalse);
      expect(r.isDueSoon, isFalse);
    });

    test('un punto de partida asumido se calcula como un registro', () {
      expect(
          rec(nextDueKm: 3000, currentKm: 3100, baseline: BaselineMode.assumed)
              .status,
          RecommendationStatus.overdue);
    });

    test('vencido, próximo y al día según el umbral configurado', () {
      expect(rec(nextDueKm: 3000, currentKm: 3100).status,
          RecommendationStatus.overdue);
      expect(rec(nextDueKm: 3000, currentKm: 2700).status,
          RecommendationStatus.dueSoon);
      expect(rec(nextDueKm: 3000, currentKm: 2700, dueSoonKm: 200).status,
          RecommendationStatus.ok);
    });
  });

  group('baselineStart', () {
    final bought = DateTime(2025, 6, 1);
    Vehicle vehicle({bool used = true, DateTime? acquiredAt}) => Vehicle(
          id: 1,
          name: 'Auto',
          vehicleTypeId: 1,
          brand: 'B',
          model: 'M',
          year: 2015,
          licensePlate: '',
          currentKm: 95000,
          createdAt: DateTime(2026, 1, 1),
          used: used,
          acquiredAt: acquiredAt,
          acquiredKm: 90000,
        );
    MaintenanceBaseline baseline(BaselineMode mode,
            {int? km, DateTime? date}) =>
        MaintenanceBaseline(
            vehicleId: 1,
            maintenanceTypeId: 'x',
            mode: mode,
            km: km,
            date: date);

    test('asumido: cuenta desde la compra', () {
      final s = RecommendationService.baselineStart(
          vehicle(acquiredAt: bought), baseline(BaselineMode.assumed))!;
      expect(s.km, 90000);
      expect(s.date, bought);
    });

    test('sin fecha de compra, cuenta desde el alta', () {
      final s = RecommendationService.baselineStart(
          vehicle(), baseline(BaselineMode.assumed))!;
      expect(s.date, DateTime(2026, 1, 1));
    });

    test('conocido: lo que falta sale de la compra', () {
      final onlyKm = RecommendationService.baselineStart(
          vehicle(acquiredAt: bought),
          baseline(BaselineMode.known, km: 82000))!;
      expect(onlyKm.km, 82000);
      expect(onlyKm.date, bought);

      final onlyDate = RecommendationService.baselineStart(
          vehicle(acquiredAt: bought),
          baseline(BaselineMode.known, date: DateTime(2024, 3, 1)))!;
      expect(onlyDate.km, 90000);
      expect(onlyDate.date, DateTime(2024, 3, 1));
    });

    test('revisar, sin respuesta o no usado: no hay punto de partida', () {
      expect(
          RecommendationService.baselineStart(
              vehicle(), baseline(BaselineMode.check)),
          isNull);
      expect(RecommendationService.baselineStart(vehicle(), null), isNull);
      expect(
          RecommendationService.baselineStart(
              vehicle(used: false), baseline(BaselineMode.assumed)),
          isNull);
    });

    test('sobrevive a guardar y leer', () {
      final b = MaintenanceBaseline.fromMap(
          baseline(BaselineMode.known, km: 1000, date: bought).toMap());
      expect(b.mode, BaselineMode.known);
      expect(b.km, 1000);
      expect(b.date, bought);
      // Fuera de "sé cuándo" no se guardan datos.
      expect(baseline(BaselineMode.check, km: 5).toMap()['km'], isNull);
    });
  });

  group('DefaultCatalog', () {
    test('los ids no se repiten', () {
      final ids = DefaultCatalog.maintenanceTypes.map((m) => m.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('el filtro de aceite es un mantenimiento aparte', () {
      final ids = DefaultCatalog.maintenanceTypes.map((m) => m.id).toSet();
      expect(ids, containsAll(['car_oil_filter', 'moto_oil_filter']));
    });

    test('cada tipo de vehículo tiene catálogo de la primera versión', () {
      for (final t in DefaultCatalog.vehicleTypes) {
        expect(
            DefaultCatalog.maintenanceTypes
                .where((m) => m.vehicleKey == t.key && m.since < 7),
            isNotEmpty);
      }
    });
  });

  test('AppSettings sobrevive a guardar y leer', () {
    const s = AppSettings(
      dueSoonKm: 800,
      dueSoonDays: 21,
      maintenanceRemindersEnabled: true,
      reminderDaysBefore: 3,
      reminderHour: 18,
      locale: 'en',
    );
    final back = AppSettings.fromKeyValues(s.toKeyValues());
    expect(back.dueSoonKm, 800);
    expect(back.dueSoonDays, 21);
    expect(back.maintenanceRemindersEnabled, isTrue);
    expect(back.reminderDaysBefore, 3);
    expect(back.reminderHour, 18);
    expect(back.locale, 'en');
  });
}
