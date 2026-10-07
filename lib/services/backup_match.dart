/// Cómo se reconoce, al importar un backup, que un vehículo ya está en el
/// teléfono.
class BackupMatch {
  static String normalizePlate(Object? plate) => (plate as String? ?? '')
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// El vehículo local que es el mismo que [vehicle] del backup: la misma
  /// patente o, sin patente, el mismo nombre, marca y modelo.
  static Map<String, dynamic>? find(
      Map<String, dynamic> vehicle, Iterable<Map<String, dynamic>> local) {
    String lower(Object? s) => (s as String? ?? '').trim().toLowerCase();
    final plate = normalizePlate(vehicle['license_plate']);
    for (final l in local) {
      final localPlate = normalizePlate(l['license_plate']);
      if (plate.isNotEmpty) {
        if (localPlate == plate) return l;
      } else if (localPlate.isEmpty &&
          lower(l['name']) == lower(vehicle['name']) &&
          lower(l['brand']) == lower(vehicle['brand']) &&
          lower(l['model']) == lower(vehicle['model'])) {
        return l;
      }
    }
    return null;
  }
}
