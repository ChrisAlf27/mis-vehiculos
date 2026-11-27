import 'package:flutter_test/flutter_test.dart';
import 'package:vehiculos_app/data/default_catalog.dart';
import 'package:vehiculos_app/data/manual_schedules.dart';
import 'package:vehiculos_app/models/app_settings.dart';
import 'package:vehiculos_app/models/interval_override.dart';

void main() {
  group('ManualSchedules', () {
    final motoIds = {for (final t in DefaultCatalog.motorcycleTypes) t.id};

    test('sólo usan mantenimientos de fábrica de moto', () {
      for (final s in ManualSchedules.all) {
        for (final id in s.intervals.keys) {
          expect(motoIds, contains(id), reason: '${s.id}: $id');
        }
      }
    });

    test('ids únicos y cada intervalo con algún valor positivo', () {
      final ids = ManualSchedules.all.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final s in ManualSchedules.all) {
        for (final e in s.intervals.entries) {
          final v = e.value;
          expect((v.km ?? 0) > 0 || (v.days ?? 0) > 0, isTrue,
              reason: '${s.id}: ${e.key}');
        }
      }
    });

    test('sugiere el manual según marca y modelo', () {
      String? suggested(String brand, String model) => ManualSchedules.all
          .where((s) => s.matches(brand, model))
          .map((s) => s.id)
          .firstOrNull;

      expect(suggested('Bajaj', 'Dominar 400'), 'bajaj_dominar_400');
      expect(suggested('Bajaj', 'Pulsar 125'), 'bajaj_pulsar_125');
      expect(suggested('Bajaj', 'Pulsar NS 125'), 'bajaj_pulsar_125');
      expect(suggested('Honda', 'Wave 110'), isNull);
      expect(suggested('', ''), isNull);
    });

    test('los repuestos de cada ítem existen', () {
      for (final s in ManualSchedules.all) {
        final ids = {for (final p in s.parts) p.id};
        for (final item in s.items) {
          for (final p in item.parts) {
            expect(ids, contains(p), reason: '${s.id}: ${item.nameEs}');
          }
        }
      }
    });
  });

  group('services de la Dominar 400', () {
    final d = ManualSchedules.byId('bajaj_dominar_400')!;
    List<String> buy(int index) => d.partsAt(index).map((p) => p.id).toList();

    test('km de cada service', () {
      expect(d.serviceKm(0), 500);
      expect(d.serviceKm(1), 2500);
      expect(d.serviceKm(8), 20000);
    });

    test('próximo service según el km', () {
      expect(d.nextServiceIndex(0), 0);
      expect(d.nextServiceIndex(500), 0);
      expect(d.nextServiceIndex(501), 1);
      expect(d.nextServiceIndex(2500), 1);
      expect(d.nextServiceIndex(2501), 2);
      expect(d.nextServiceIndex(19000), 8);
    });

    test('qué comprar en cada service', () {
      expect(buy(0), ['oil', 'oil_filter']);
      expect(buy(1), ['oil', 'oil_filter']);
      expect(buy(4), containsAll(['oil', 'air_filter', 'fuel_filter']));
      expect(buy(4), isNot(contains('spark_plugs')));
      expect(buy(6), containsAll(['oil', 'brake_pads']));
      expect(buy(8), containsAll(['spark_plugs', 'air_filter']));
      expect(buy(12), containsAll(['brake_fluid', 'brake_pads']));
    });

    test('la cadena se lubrica entre services', () {
      expect(
        d.betweenServices.map((e) => (e.$1.nameEs, e.$2.every)),
        contains(('Cadena de arrastre (sellada)', 500)),
      );
    });

    test('la tabla llega hasta el reemplazo más espaciado', () {
      expect(d.serviceKm(d.tableServices), 30000);
    });
  });

  group('services de la Pulsar 125', () {
    final p = ManualSchedules.byId('bajaj_pulsar_125')!;

    test('bujías: se limpian cada 5000 y se cambian cada 10000', () {
      final plugs = p.items.firstWhere((i) => i.nameEs == 'Bujías');
      expect(p.actionsAt(plugs, 0), isEmpty);
      expect(p.actionsAt(plugs, 1), isEmpty);
      expect(p.actionsAt(plugs, 2),
          [ManualAction.adjust, ManualAction.clean]);
      expect(p.actionsAt(plugs, 4), contains(ManualAction.replace));
      expect(p.partsAt(4).map((x) => x.id), contains('spark_plugs'));
    });
  });

  group('pendientes de services anteriores', () {
    final d = ManualSchedules.byId('bajaj_dominar_400')!;
    // Dominar con 23.600 km: el próximo es el de 25.000 (índice 10) y el
    // anterior el de 22.500.
    final next = d.nextServiceIndex(23600);
    final oil = d.items.first;
    const allDone = {
      'moto_oil_change': 22500,
      'moto_general_service': 22500,
      'moto_spark_plug': 20000,
      'moto_air_filter': 20000,
      'moto_fuel_filter': 20000,
      'moto_valve_clearance': 20000,
      'moto_chain_adjust': 22500,
      'moto_brake_pads_front': 15000,
      'moto_brake_fluid': 22500,
    };

    test('con todo registrado no queda nada', () {
      expect(d.pendingBefore(next, lastKm: allDone, sinceKm: 0), isEmpty);
    });

    test('el cambio de aceite sin registrar queda pendiente', () {
      final pending = d.pendingBefore(next,
          lastKm: {...allDone}..remove('moto_oil_change'), sinceKm: 0);
      expect(pending.map((p) => p.item), [oil]);
      expect(pending.single.isReplace, isTrue);
      expect(d.serviceKm(pending.single.service), 22500);
      expect(d.partsFor(pending).map((p) => p.id), ['oil', 'oil_filter']);
    });

    test('un registro un poco antes del service también vale', () {
      final pending = d.pendingBefore(next,
          lastKm: {...allDone, 'moto_oil_change': 22000}, sinceKm: 0);
      expect(pending, isEmpty);
    });

    test('sin service general quedan las revisiones', () {
      final pending = d.pendingBefore(next,
          lastKm: {...allDone}..remove('moto_general_service'), sinceKm: 0);
      expect(pending, isNotEmpty);
      expect(pending.every((p) => !p.isReplace), isTrue);
      expect(pending.map((p) => p.item), isNot(contains(oil)));
    });

    test('lo de antes de que la app conozca la moto no cuenta', () {
      expect(d.pendingBefore(next, lastKm: const {}, sinceKm: 22600), isEmpty);
      expect(d.pendingBefore(next, lastKm: const {}, sinceKm: 21000),
          isNotEmpty);
    });
  });

  group('AppSettings.themeMode', () {
    test('se guarda y se lee; un valor raro vuelve al del teléfono', () {
      final kv = const AppSettings(themeMode: 'dark').toKeyValues();
      expect(AppSettings.fromKeyValues(kv).themeMode, 'dark');
      expect(AppSettings.fromKeyValues({}).themeMode, 'system');
      expect(AppSettings.fromKeyValues({'theme_mode': 'x'}).themeMode,
          'system');
    });
  });

  group('IntervalOverride.manualId', () {
    test('se guarda y se lee', () {
      const o = IntervalOverride(
        vehicleId: 1,
        maintenanceTypeId: 'moto_oil_change',
        intervalKm: 2500,
        manualId: 'bajaj_dominar_400',
      );
      final back = IntervalOverride.fromMap(o.toMap());
      expect(back.manualId, 'bajaj_dominar_400');
      expect(back.fromManual, isTrue);
    });

    test('un registro viejo sin la columna no es de manual', () {
      final o = IntervalOverride.fromMap({
        'vehicle_id': 1,
        'maintenance_type_id': 'moto_oil_change',
        'interval_km': 2500,
        'interval_days': null,
        'hidden': 0,
      });
      expect(o.manualId, isNull);
      expect(o.fromManual, isFalse);
    });

    test('oculto sin intervalo no cuenta como de manual', () {
      const o = IntervalOverride(
        vehicleId: 1,
        maintenanceTypeId: 'moto_oil_change',
        hidden: true,
        manualId: 'bajaj_dominar_400',
      );
      expect(o.fromManual, isFalse);
    });
  });
}
