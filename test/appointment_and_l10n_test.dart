import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vehiculos_app/models/appointment.dart';
import 'package:vehiculos_app/services/backup_service.dart';

void main() {
  group('Appointment', () {
    final at = DateTime(2030, 5, 10, 15, 30);

    test('el aviso se corre según la anticipación elegida', () {
      Appointment a(int minutes) => Appointment(
            vehicleId: 1,
            scheduledAt: at,
            remindMinutesBefore: minutes,
          );
      expect(a(0).remindAt, at);
      expect(a(60).remindAt, DateTime(2030, 5, 10, 14, 30));
      expect(a(1440).remindAt, DateTime(2030, 5, 9, 15, 30));
    });

    test('sobrevive a guardar y leer', () {
      final a = Appointment(
        id: 7,
        vehicleId: 3,
        scheduledAt: at,
        mechanic: 'Taller Juan',
        notes: 'Llevar aceite',
        remindMinutesBefore: 60,
      );
      final back = Appointment.fromMap(a.toMap(),
          maintenanceTypeIds: ['moto_oil_change', 'moto_air_filter']);
      expect(back.id, 7);
      expect(back.vehicleId, 3);
      expect(back.scheduledAt, at);
      expect(back.mechanic, 'Taller Juan');
      expect(back.notes, 'Llevar aceite');
      expect(back.remindMinutesBefore, 60);
      expect(back.maintenanceTypeIds, ['moto_oil_change', 'moto_air_filter']);
    });
  });

  test('un backup v4 (un turno por mantenimiento) pasa a turnos con ítems', () {
    final tables = <String, List<Map<String, dynamic>>>{
      'appointments': [
        {
          'vehicle_id': 1,
          'maintenance_type_id': 'moto_oil_change',
          'scheduled_at': '2030-05-10T15:30:00.000',
          'mechanic': 'Juan',
          'notes': null,
          'remind_minutes_before': 60,
        },
        {
          'vehicle_id': 2,
          'maintenance_type_id': 'car_spark_plugs',
          'scheduled_at': '2030-06-01T09:00:00.000',
          'mechanic': null,
          'notes': null,
          'remind_minutes_before': 1440,
        },
      ],
    };
    BackupService.upgradeTables(tables, 4);

    expect(tables['appointments']!.map((a) => a['id']), [1, 2]);
    expect(tables['appointments']!.first.containsKey('maintenance_type_id'),
        isFalse);
    expect(tables['appointment_items'], [
      {'appointment_id': 1, 'maintenance_type_id': 'moto_oil_change'},
      {'appointment_id': 2, 'maintenance_type_id': 'car_spark_plugs'},
    ]);
  });

  test('el inglés tiene todas las claves del español', () {
    Map<String, dynamic> read(String f) =>
        jsonDecode(File('lib/l10n/$f').readAsStringSync())
            as Map<String, dynamic>;
    Set<String> keys(Map<String, dynamic> m) =>
        m.keys.where((k) => !k.startsWith('@')).toSet();

    final missing =
        keys(read('app_es.arb')).difference(keys(read('app_en.arb')));
    expect(missing, isEmpty, reason: 'Faltan en app_en.arb: $missing');
  });
}
