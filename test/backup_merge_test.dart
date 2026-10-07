import 'package:flutter_test/flutter_test.dart';
import 'package:vehiculos_app/services/backup_match.dart';
import 'package:vehiculos_app/services/backup_service.dart';

void main() {
  group('BackupMatch.find', () {
    final local = [
      {'id': 1, 'name': 'C3', 'brand': 'Citroen', 'model': 'C3', 'license_plate': 'FDM 718'},
      {'id': 2, 'name': 'Bici', 'brand': 'X', 'model': 'Y', 'license_plate': ''},
    ];

    test('la patente manda, sin importar espacios ni mayúsculas', () {
      final m = BackupMatch.find(
          {'name': 'Otro nombre', 'brand': 'a', 'model': 'b', 'license_plate': 'fdm-718'},
          local);
      expect(m?['id'], 1);
    });

    test('con patente distinta no es el mismo', () {
      expect(
          BackupMatch.find(
              {'name': 'C3', 'brand': 'Citroen', 'model': 'C3', 'license_plate': 'AAA111'},
              local),
          isNull);
    });

    test('sin patente compara nombre, marca y modelo', () {
      expect(
          BackupMatch.find(
              {'name': ' bici ', 'brand': 'x', 'model': 'Y', 'license_plate': null},
              local)?['id'],
          2);
      expect(
          BackupMatch.find(
              {'name': 'Bici', 'brand': 'X', 'model': 'Z', 'license_plate': ''},
              local),
          isNull);
    });
  });

  group('builtInTypeKeys', () {
    test('usa la clave si el backup la tiene', () {
      expect(
          BackupService.builtInTypeKeys({
            'vehicle_types': [
              {'id': 5, 'key': 'motorcycle'},
            ],
          }),
          {5: 'motorcycle'});
    });

    test('en backups viejos la deduce por los mantenimientos de fábrica', () {
      final keys = BackupService.builtInTypeKeys({
        'vehicle_types': [
          {'id': 1, 'name': 'Mi auto'},
          {'id': 2, 'name': 'Motos'},
          {'id': 3, 'name': 'Camión'},
        ],
        'maintenance_types': [
          {'id': 'car_oil_change', 'vehicle_type_id': 1},
          {'id': 'car_air_filter', 'vehicle_type_id': 1},
          {'id': 'moto_chain_lube', 'vehicle_type_id': 2},
          {'id': 'custom_1', 'vehicle_type_id': 3},
        ],
      });
      expect(keys, {1: 'car', 2: 'motorcycle'});
    });
  });
}
