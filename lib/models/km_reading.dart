/// Un punto (fecha, km) del odómetro de un vehículo.
class KmReading {
  final DateTime date;
  final int km;

  const KmReading({required this.date, required this.km});
}

/// Cuántos km hace el vehículo por día, calculado a partir de sus lecturas.
class UsageEstimate {
  final double kmPerDay;

  /// La lectura más reciente: desde acá se proyecta hacia adelante.
  final KmReading reference;

  const UsageEstimate({required this.kmPerDay, required this.reference});

  double get kmPerWeek => kmPerDay * 7;

  /// Fecha estimada en la que el odómetro llega a [targetKm].
  DateTime dateForKm(int targetKm) {
    final days = (targetKm - reference.km) / kmPerDay;
    return reference.date.add(Duration(minutes: (days * 24 * 60).round()));
  }

  int estimatedKmAt(DateTime date) =>
      reference.km +
      (date.difference(reference.date).inMinutes / (24 * 60) * kmPerDay)
          .round();
}

/// Interpreta un km escrito a mano: "45000", "45.000", "45,000" o "45 000".
/// Cualquier otra cosa da null — incluido "4,1" o "4k", que sacando las letras
/// o la coma se leerían como otro número.
int? parseKm(String? text) {
  final t = (text ?? '').trim();
  if (RegExp(r'^\d+$').hasMatch(t) ||
      RegExp(r'^\d{1,3}([.,\s]\d{3})+$').hasMatch(t)) {
    return int.tryParse(t.replaceAll(RegExp(r'[.,\s]'), ''));
  }
  return null;
}

/// Resultado de cargar un km: el llamador decide qué mensaje mostrar.
enum KmUpdateResult { saved, lowerThanCurrent, vehicleNotFound }
