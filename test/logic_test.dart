import 'package:flutter_test/flutter_test.dart';
import 'package:vehiculos_app/models/app_settings.dart';
import 'package:vehiculos_app/models/km_reading.dart';
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
          dueSoonKm: dueSoonKm,
        );

    test('sin registro nunca figura como vencido', () {
      final r = rec(nextDueKm: 3000, currentKm: 4100, pending: true);
      expect(r.status, RecommendationStatus.pendingRecord);
      expect(r.isOverdue, isFalse);
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
