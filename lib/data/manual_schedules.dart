/// Planes de mantenimiento tomados de los manuales de fábrica.
///
/// Cada manual tiene:
/// - la tabla por service ([items]): qué se hace en cada uno, como en el
///   manual, y qué repuestos ([parts]) hay que comprar cuando toca reemplazar;
/// - los intervalos ([intervals]) que se pueden cargar en un vehículo como
///   intervalos propios "de manual". Las claves son los ids de los
///   mantenimientos de fábrica de moto (DefaultCatalog.motorcycleTypes); en
///   km/días, null quiere decir que el manual no lo indica y queda el valor
///   general del tipo.
class ManualInterval {
  final int? km;
  final int? days;

  const ManualInterval({this.km, this.days});
}

enum ManualAction {
  inspect('Rv', 'I', 'Revisar', 'Inspect'),
  adjust('Rg', 'A', 'Regular', 'Adjust'),
  clean('Lm', 'C', 'Limpiar', 'Clean'),
  replace('Re', 'R', 'Reemplazar', 'Replace'),
  lubricate('Lb', 'L', 'Lubricar', 'Lubricate'),
  tighten('Ap', 'T', 'Apretar', 'Tighten'),
  refill('Rll', 'F', 'Rellenar', 'Top up');

  final String _abbrEs;
  final String _abbrEn;
  final String _nameEs;
  final String _nameEn;

  const ManualAction(this._abbrEs, this._abbrEn, this._nameEs, this._nameEn);

  String abbr(String locale) => locale.startsWith('en') ? _abbrEn : _abbrEs;
  String label(String locale) => locale.startsWith('en') ? _nameEn : _nameEs;
}

/// Una acción y cuándo toca.
///
/// - [first]: en el 1er service.
/// - [every]: cada tantos km, contando desde [start] (por defecto, desde
///   [every]). Si es menor que el período entre services, además se muestra
///   como tarea "entre services".
/// - [days]: además, por tiempo (lo que llegue primero).
class ManualTask {
  final ManualAction action;
  final bool first;
  final int? every;
  final int? start;
  final int? days;

  const ManualTask(
    this.action, {
    this.first = false,
    this.every,
    this.start,
    this.days,
  });

  /// Si toca en un service periódico con ese km (no el 1ro).
  bool dueAtKm(int km) {
    final e = every;
    if (e == null) return false;
    final from = start ?? e;
    return km >= from && (km - from) % e == 0;
  }
}

class ManualItem {
  final String nameEs;
  final String nameEn;
  final List<ManualTask> tasks;

  /// Ids de [ManualSchedule.parts] que hay que comprar cuando toca
  /// reemplazarlo.
  final List<String> parts;
  final String noteEs;
  final String noteEn;

  /// Mantenimientos de la app que, registrados, cuentan como hecho este ítem.
  /// Sin tipos (o para revisar y ajustar) alcanza con el service general.
  final List<String> types;

  const ManualItem(
    this.nameEs,
    this.nameEn,
    this.tasks, {
    this.parts = const [],
    this.types = const [],
    this.noteEs = '',
    this.noteEn = '',
  });

  String name(String locale) => locale.startsWith('en') ? nameEn : nameEs;
  String note(String locale) => locale.startsWith('en') ? noteEn : noteEs;
}

/// Algo que tocaba en un service anterior y no figura hecho.
class ManualPending {
  final ManualItem item;
  final List<ManualAction> actions;

  /// En qué service tocaba.
  final int service;

  const ManualPending(this.item, this.actions, this.service);

  bool get isReplace => actions.contains(ManualAction.replace);
}

class ManualPart {
  final String id;
  final String nameEs;
  final String nameEn;
  final String specEs;
  final String specEn;

  const ManualPart(this.id, this.nameEs, this.nameEn,
      {this.specEs = '', this.specEn = ''});

  String name(String locale) => locale.startsWith('en') ? nameEn : nameEs;
  String spec(String locale) => locale.startsWith('en') ? specEn : specEs;
}

class ManualSchedule {
  final String id;
  final String name;

  /// De dónde sale: manual y páginas.
  final String source;

  /// Textos que, sin espacios ni signos, aparecen en "marca modelo" del
  /// vehículo para sugerir este manual.
  final List<String> aliases;
  final String noteEs;
  final String noteEn;

  /// El 1er service y cada cuántos km van los siguientes.
  final int firstServiceKm;
  final int periodKm;

  final List<ManualItem> items;
  final List<ManualPart> parts;
  final Map<String, ManualInterval> intervals;

  const ManualSchedule({
    required this.id,
    required this.name,
    required this.source,
    required this.aliases,
    this.noteEs = '',
    this.noteEn = '',
    required this.firstServiceKm,
    required this.periodKm,
    required this.items,
    required this.parts,
    required this.intervals,
  });

  String getNote(String locale) => locale.startsWith('en') ? noteEn : noteEs;

  static String _normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[áàä]'), 'a')
      .replaceAll(RegExp(r'[éèë]'), 'e')
      .replaceAll(RegExp(r'[íìï]'), 'i')
      .replaceAll(RegExp(r'[óòö]'), 'o')
      .replaceAll(RegExp(r'[úùü]'), 'u')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// Si el manual corresponde a un vehículo con esa marca y modelo.
  bool matches(String brand, String model) {
    final text = _normalize('$brand $model');
    if (text.isEmpty) return false;
    return aliases.any((a) => text.contains(_normalize(a)));
  }

  // ─── Services ──────────────────────────────────────────────────────────────

  /// El km del service número [index] (0 = el 1ro).
  int serviceKm(int index) => index == 0 ? firstServiceKm : index * periodKm;

  /// El próximo service para ese km: el primero que todavía no se pasó.
  int nextServiceIndex(int currentKm) {
    if (currentKm <= firstServiceKm) return 0;
    final n = (currentKm / periodKm).ceil();
    return n < 1 ? 1 : n;
  }

  /// Lo que se hace en un ítem en el service [index], en el orden del enum.
  List<ManualAction> actionsAt(ManualItem item, int index) {
    final km = serviceKm(index);
    final actions = {
      for (final t in item.tasks)
        if (index == 0 ? t.first : t.dueAtKm(km)) t.action,
    };
    return ManualAction.values.where(actions.contains).toList();
  }

  /// Ítems con algo para hacer en el service [index].
  List<(ManualItem, List<ManualAction>)> tasksAt(int index) => [
        for (final item in items)
          if (actionsAt(item, index) case final a when a.isNotEmpty) (item, a),
      ];

  /// Repuestos a comprar para el service [index]: los de los ítems que se
  /// reemplazan.
  List<ManualPart> partsAt(int index) {
    final ids = <String>{
      for (final (item, actions) in tasksAt(index))
        if (actions.contains(ManualAction.replace)) ...item.parts,
    };
    return parts.where((p) => ids.contains(p.id)).toList();
  }

  /// Registrar cualquiera de estos cuenta como hechas las revisiones y ajustes
  /// de un service.
  static const generalTypes = ['moto_general_service', 'moto_inspection'];

  /// Lo que tocaba en los services anteriores al [next] y no está registrado.
  /// [lastKm] tiene el km del último registro de cada tipo de mantenimiento;
  /// un registro hasta medio período antes del service también vale. No se
  /// marca nada de antes de [sinceKm]: eso la app no lo conoce.
  List<ManualPending> pendingBefore(
    int next, {
    required Map<String, int> lastKm,
    required int sinceKm,
  }) {
    final tolerance = periodKm ~/ 2;
    bool done(Iterable<String> types, int km) =>
        types.any((t) => (lastKm[t] ?? -1) >= km - tolerance);
    int? lastWhere(ManualItem item, bool Function(ManualAction) test) {
      for (var k = next - 1; k >= 0; k--) {
        if (actionsAt(item, k).any(test)) return k;
      }
      return null;
    }

    final result = <ManualPending>[];
    for (final item in items) {
      // Un reemplazo pendiente ya incluye revisarlo.
      final r = lastWhere(item, (a) => a == ManualAction.replace);
      if (r != null &&
          serviceKm(r) >= sinceKm &&
          !done(item.types.isEmpty ? generalTypes : item.types, serviceKm(r))) {
        result.add(ManualPending(item, const [ManualAction.replace], r));
        continue;
      }
      final o = lastWhere(item, (a) => a != ManualAction.replace);
      if (o != null &&
          serviceKm(o) >= sinceKm &&
          !done([...item.types, ...generalTypes], serviceKm(o))) {
        result.add(ManualPending(
          item,
          [
            for (final a in actionsAt(item, o))
              if (a != ManualAction.replace) a,
          ],
          o,
        ));
      }
    }
    return result;
  }

  /// Repuestos de los reemplazos pendientes.
  List<ManualPart> partsFor(List<ManualPending> pending) {
    final ids = {
      for (final p in pending)
        if (p.isReplace) ...p.item.parts,
    };
    return parts.where((p) => ids.contains(p.id)).toList();
  }

  /// Tareas más frecuentes que los services (ej. lubricar la cadena).
  List<(ManualItem, ManualTask)> get betweenServices => [
        for (final item in items)
          for (final t in item.tasks)
            if (t.every != null && t.every! < periodKm) (item, t),
      ];

  /// Tareas que además vencen por tiempo.
  List<(ManualItem, ManualTask)> get byTime => [
        for (final item in items)
          for (final t in item.tasks)
            if (t.days != null) (item, t),
      ];

  /// Cuántos services muestra la tabla completa: hasta que se repite el
  /// reemplazo más espaciado, entre 4 y 12 columnas además del 1ro.
  int get tableServices {
    var maxEvery = periodKm;
    for (final item in items) {
      for (final t in item.tasks) {
        final e = (t.start ?? 0) + (t.every ?? 0);
        if (e > maxEvery) maxEvery = e;
      }
    }
    return (maxEvery / periodKm).ceil().clamp(4, 12);
  }
}

// ─── Atajos para escribir las tablas ──────────────────────────────────────────

const _rv = ManualAction.inspect;
const _rg = ManualAction.adjust;
const _lm = ManualAction.clean;
const _re = ManualAction.replace;
const _lb = ManualAction.lubricate;
const _ap = ManualAction.tighten;
const _rll = ManualAction.refill;

class ManualSchedules {
  static const all = <ManualSchedule>[_dominar400, _pulsar125];

  static ManualSchedule? byId(String? id) =>
      all.where((s) => s.id == id).firstOrNull;
}

// Manual de servicio Bajaj Dominar 400: cuadro de mantenimiento p. 26-27,
// especificaciones p. 15 y 17, bujías p. 139 (sistema eléctrico).
const _dominar400 = ManualSchedule(
  id: 'bajaj_dominar_400',
  name: 'Bajaj Dominar 400',
  source: 'Manual de servicio Bajaj Dominar 400, p. 15-17 y 26-27',
  aliases: ['dominar'],
  noteEs: 'Service cada 2.500 km; el 1° entre los 450 y 500 km.',
  noteEn: 'Service every 2,500 km; the first one at 450-500 km.',
  firstServiceKm: 500,
  periodKm: 2500,
  items: [
    ManualItem(
        'Aceite de motor y filtro de aceite', 'Engine oil and oil filter', [
      ManualTask(_re, first: true, every: 2500),
    ],
        types: [
          'moto_oil_change',
          'moto_oil_filter'
        ],
        parts: [
          'oil',
          'oil_filter'
        ]),
    ManualItem('Colador de aceite', 'Oil strainer', [
      ManualTask(_lm, first: true, every: 2500),
    ]),
    ManualItem('Bujías', 'Spark plugs', [
      ManualTask(_lm, every: 5000),
      ManualTask(_rg, every: 5000),
      ManualTask(_re, every: 20000),
    ], types: [
      'moto_spark_plug'
    ], parts: [
      'spark_plugs'
    ]),
    ManualItem(
        'Filtro de aire',
        'Air filter',
        [
          ManualTask(_re, every: 10000),
        ],
        types: ['moto_air_filter'],
        parts: ['air_filter'],
        noteEs: 'No hace falta limpiarlo.',
        noteEn: 'No need to clean it.'),
    ManualItem('Filtro de combustible en línea', 'In-line fuel filter', [
      ManualTask(_re, every: 10000),
    ], types: [
      'moto_fuel_filter'
    ], parts: [
      'fuel_filter'
    ]),
    ManualItem('Tubería de combustible', 'Fuel line', [
      ManualTask(_rv, every: 10000),
    ]),
    ManualItem('Luz de válvulas', 'Valve clearance', [
      ManualTask(_rv, every: 10000),
      ManualTask(_rg, every: 10000),
    ], types: [
      'moto_valve_clearance'
    ]),
    ManualItem(
        'Cadena de arrastre (sellada)',
        'Drive chain (sealed)',
        [
          ManualTask(_lm, first: true, every: 2500),
          ManualTask(_rg, first: true, every: 2500),
          ManualTask(_lb, first: true, every: 500),
        ],
        types: ['moto_chain_adjust', 'moto_chain_lube'],
        parts: ['chain_lube'],
        noteEs: 'Lubricar cada 500 km con spray OKS (lo hace el dueño).',
        noteEn: 'Lubricate every 500 km with OKS spray (owner task).'),
    ManualItem('Zapatas o pastillas de freno', 'Brake shoes or pads', [
      ManualTask(_rv, first: true, every: 2500),
      ManualTask(_re, every: 15000),
    ], types: [
      'moto_brake_pads_front',
      'moto_brake_pads_rear'
    ], parts: [
      'brake_pads'
    ]),
    ManualItem('Líquido de frenos', 'Brake fluid', [
      ManualTask(_rv, every: 7500),
      ManualTask(_rll, every: 7500),
      ManualTask(_re, every: 30000),
    ], types: [
      'moto_brake_fluid'
    ], parts: [
      'brake_fluid'
    ]),
    ManualItem('Disco de freno: funcionamiento y fugas',
        'Brake disc: operation and leaks', [
      ManualTask(_rv, first: true, every: 2500),
    ],
        types: [
          'moto_brake_discs'
        ]),
    ManualItem(
        'Pasador del pivote del pedal de freno', 'Brake pedal pivot pin', [
      ManualTask(_rv, first: true, every: 2500),
      ManualTask(_lb, every: 2500),
    ]),
    ManualItem('Juego libre de los cables', 'Cable free play', [
      ManualTask(_rv, first: true, every: 2500),
      ManualTask(_rg, first: true, every: 2500),
    ], types: [
      'moto_cables'
    ]),
    ManualItem('Ramal eléctrico y conexiones de la batería',
        'Wiring and battery terminals', [
      ManualTask(_rv, first: true, every: 2500),
      ManualTask(_rg, first: true, every: 2500),
      ManualTask(_ap, first: true, every: 2500),
    ]),
    ManualItem('Juego de la dirección', 'Steering play', [
      ManualTask(_rv, first: true, every: 2500),
      ManualTask(_ap, first: true, every: 2500),
    ]),
    ManualItem(
        'Rodamiento del vástago de dirección',
        'Steering stem bearing',
        [
          ManualTask(_rv, first: true, every: 2500),
          ManualTask(_lm, first: true, every: 2500),
          ManualTask(_lb, first: true, every: 2500),
        ],
        types: ['moto_steering_bearings'],
        noteEs: 'Reemplazar si está dañado. Grasa HP Lithon RR3.',
        noteEn: 'Replace if damaged. HP Lithon RR3 grease.'),
    ManualItem(
        'Cerradura de contacto y comandos',
        'Ignition switch and handlebar switches',
        [
          ManualTask(_rv, first: true, every: 2500),
          ManualTask(_lm, first: true, every: 2500),
        ],
        noteEs: 'Limpiar con WD-40.',
        noteEn: 'Clean with WD-40.'),
    ManualItem('Lubricación de manijas de embrague y freno',
        'Clutch and brake lever lubrication', [
      ManualTask(_lb, first: true, every: 2500),
    ]),
    ManualItem('Nivel de refrigerante', 'Coolant level', [
      ManualTask(_rv, first: true, every: 2500),
      ManualTask(_rll, first: true, every: 2500),
    ], types: [
      'moto_coolant'
    ]),
    ManualItem('Mangueras de refrigeración y aletas del radiador',
        'Coolant hoses and radiator fins', [
      ManualTask(_rv, every: 2500),
    ]),
    ManualItem('Pasador del parador lateral', 'Side stand pivot', [
      ManualTask(_lm, every: 5000),
      ManualTask(_lb, every: 5000),
    ]),
    ManualItem('Tubo de drenaje del filtro de aire', 'Air filter drain tube', [
      ManualTask(_lm, every: 10000),
    ]),
    ManualItem(
        'Drenaje y extremo del silenciador', 'Muffler drain and tail end', [
      ManualTask(_lm, every: 2500),
    ]),
    ManualItem('Ajuste de todos los sujetadores', 'Tighten all fasteners', [
      ManualTask(_rv, first: true, every: 2500),
      ManualTask(_ap, first: true, every: 2500),
    ]),
  ],
  parts: [
    ManualPart('oil', 'Aceite de motor', 'Engine oil',
        specEs:
            'Bajaj DTS-i 10000 SAE 10W50 sintético (API SJ / JASO MA2) · 1,5 L',
        specEn:
            'Bajaj DTS-i 10000 SAE 10W50 synthetic (API SJ / JASO MA2) · 1.5 L'),
    ManualPart('oil_filter', 'Filtro de aceite', 'Oil filter'),
    ManualPart('spark_plugs', 'Bujías (3)', 'Spark plugs (3)',
        specEs:
            '2 Champion RG6HCC (izq. y der.) + 1 Champion RER6YCA (central) · luz 0,8-0,9 mm',
        specEn:
            '2 Champion RG6HCC (left and right) + 1 Champion RER6YCA (center) · gap 0.8-0.9 mm'),
    ManualPart('air_filter', 'Filtro de aire', 'Air filter'),
    ManualPart(
        'fuel_filter', 'Filtro de combustible en línea', 'In-line fuel filter'),
    ManualPart('brake_pads', 'Pastillas de freno', 'Brake pads',
        specEs: 'Delanteras y traseras', specEn: 'Front and rear'),
    ManualPart('brake_fluid', 'Líquido de frenos', 'Brake fluid',
        specEs: 'DOT 4', specEn: 'DOT 4'),
    ManualPart('chain_lube', 'Lubricante de cadena', 'Chain lube',
        specEs: 'Spray OKS para cadena sellada',
        specEn: 'OKS spray for sealed chain'),
    ManualPart('coolant', 'Refrigerante', 'Coolant',
        specEs: 'Castrol Radicool o Motul Motocool Expert · 1 L',
        specEn: 'Castrol Radicool or Motul Motocool Expert · 1 L'),
    ManualPart('fork_oil', 'Aceite de horquilla', 'Fork oil',
        specEs: 'SAE 10W20 · 420 ml por barra',
        specEn: 'SAE 10W20 · 420 ml per leg'),
    ManualPart('battery', 'Batería', 'Battery',
        specEs: '12 V 8 Ah VRLA', specEn: '12 V 8 Ah VRLA'),
    ManualPart('tires', 'Neumáticos', 'Tires',
        specEs: 'Del. 110/70-17 · Tras. 150/60-17, sin cámara',
        specEn: 'Front 110/70-17 · Rear 150/60-17, tubeless'),
  ],
  intervals: {
    'moto_oil_change': ManualInterval(km: 2500),
    'moto_oil_filter': ManualInterval(km: 2500),
    'moto_general_service': ManualInterval(km: 2500),
    'moto_chain_adjust': ManualInterval(km: 2500),
    'moto_chain_lube': ManualInterval(km: 500),
    'moto_cables': ManualInterval(km: 2500),
    'moto_air_filter': ManualInterval(km: 10000),
    'moto_fuel_filter': ManualInterval(km: 10000),
    'moto_valve_clearance': ManualInterval(km: 10000),
    'moto_spark_plug': ManualInterval(km: 20000),
    'moto_brake_pads_front': ManualInterval(km: 15000),
    'moto_brake_pads_rear': ManualInterval(km: 15000),
    'moto_brake_fluid': ManualInterval(km: 30000),
  },
);

// Manual de servicio Bajaj Pulsar 125 Carburada: cuadro de mantenimiento p. 11,
// especificaciones p. 7-8.
const _pulsar125 = ManualSchedule(
  id: 'bajaj_pulsar_125',
  name: 'Bajaj Pulsar 125',
  source: 'Manual de servicio Bajaj Pulsar 125 Carburada, p. 7-11',
  aliases: ['pulsar125', 'ns125', '125ns'],
  noteEs: 'Service cada 2.500 km; el 1° entre los 450 y 500 km.',
  noteEn: 'Service every 2,500 km; the first one at 450-500 km.',
  firstServiceKm: 500,
  periodKm: 2500,
  items: [
    ManualItem('Luz de válvulas', 'Valve clearance', [
      ManualTask(_rg, first: true, every: 2500),
    ], types: [
      'moto_valve_clearance'
    ]),
    ManualItem('Aceite del motor', 'Engine oil', [
      ManualTask(_re, first: true, every: 2500),
    ], types: [
      'moto_oil_change'
    ], parts: [
      'oil'
    ]),
    ManualItem('Colador de aceite', 'Oil strainer', [
      ManualTask(_lm, first: true, every: 2500),
    ]),
    ManualItem('Filtro de aceite', 'Oil filter', [
      ManualTask(_re, first: true, every: 2500),
    ], types: [
      'moto_oil_filter'
    ], parts: [
      'oil_filter'
    ]),
    ManualItem('Bujías', 'Spark plugs', [
      ManualTask(_lm, every: 5000),
      ManualTask(_rg, every: 5000),
      ManualTask(_re, every: 10000),
    ], types: [
      'moto_spark_plug'
    ], parts: [
      'spark_plugs'
    ]),
    ManualItem('Filtro de aire', 'Air filter', [
      ManualTask(_lm, first: true, every: 2500),
      ManualTask(_re, every: 10000),
    ], types: [
      'moto_air_filter'
    ], parts: [
      'air_filter'
    ]),
    ManualItem(
        'Junta tórica de la caja del filtro de aire', 'Air filter box O-ring', [
      ManualTask(_re, every: 10000),
    ],
        types: [
          'moto_air_filter'
        ],
        parts: [
          'air_box_oring'
        ]),
    ManualItem('Filtro de combustible', 'Fuel filter', [
      ManualTask(_re, every: 15000),
    ], types: [
      'moto_fuel_filter'
    ], parts: [
      'fuel_filter'
    ]),
    ManualItem('Tuberías de combustible', 'Fuel lines', [
      ManualTask(_rv, first: true, every: 2500),
      ManualTask(_re, every: 20000),
    ]),
    ManualItem('Juego de manija de embrague, acelerador y CBS',
        'Clutch lever, throttle and CBS play', [
      ManualTask(_rv, first: true, every: 2500),
      ManualTask(_rg, first: true, every: 2500),
    ],
        types: [
          'moto_cables'
        ]),
    ManualItem('Pastillas o zapatas de freno', 'Brake pads or shoes', [
      ManualTask(_lm, every: 2500),
      ManualTask(_re, every: 15000),
    ], types: [
      'moto_brake_pads_front',
      'moto_brake_pads_rear'
    ], parts: [
      'brake_pads'
    ]),
    ManualItem('Nivel de líquido de freno', 'Brake fluid level', [
      ManualTask(_rv, every: 7500),
      ManualTask(_rll, every: 7500),
    ], types: [
      'moto_brake_fluid'
    ], parts: [
      'brake_fluid'
    ]),
    ManualItem(
        'Leva de freno y pivote del pedal', 'Brake cam and pedal pivot', [
      ManualTask(_lm, first: true, every: 2500),
      ManualTask(_lb, first: true, every: 2500),
    ]),
    ManualItem('Juego de la dirección', 'Steering play', [
      ManualTask(_rv, first: true, every: 2500),
      ManualTask(_ap, first: true, every: 2500),
    ]),
    ManualItem('Rodamientos de la dirección', 'Steering bearings', [
      ManualTask(_rv, every: 5000),
      ManualTask(_lb, every: 5000),
      ManualTask(_re, every: 10000),
    ], types: [
      'moto_steering_bearings'
    ]),
    ManualItem('Sujetadores (incluida la corona)',
        'Fasteners (including rear sprocket)', [
      ManualTask(_rv, first: true, every: 2500),
      ManualTask(_ap, first: true, every: 2500),
    ]),
    ManualItem('Pasador del parador lateral y central',
        'Side and center stand pivot', [
      ManualTask(_lm, every: 2500),
      ManualTask(_lb, every: 2500),
    ]),
    ManualItem('Agujero de drenaje del silenciador', 'Muffler drain hole', [
      ManualTask(_lm, first: true, every: 2500),
    ]),
    ManualItem('Tubo del respiradero del motor', 'Engine breather tube', [
      ManualTask(_rv, first: true, every: 2500),
      ManualTask(_re, every: 20000),
    ]),
    ManualItem('Cadena de arrastre', 'Drive chain', [
      ManualTask(_rv, first: true, every: 2500),
      ManualTask(_rg, first: true, every: 2500),
      ManualTask(_lb, first: true, every: 2500),
    ], types: [
      'moto_chain_adjust',
      'moto_chain_lube'
    ]),
    ManualItem('Ramal eléctrico y conexiones de la batería',
        'Wiring and battery terminals', [
      ManualTask(_rv, first: true, every: 2500),
      ManualTask(_ap, first: true, every: 2500),
    ]),
    ManualItem('Lubricación general', 'General lubrication', [
      ManualTask(_lb, first: true, every: 2500),
    ]),
    ManualItem(
        'Mangueras EVAP y SAI',
        'EVAP and SAI hoses',
        [
          ManualTask(_rv, first: true, every: 2500),
        ],
        noteEs: 'Reemplazar si están cortadas o dañadas.',
        noteEn: 'Replace if cut or damaged.'),
  ],
  parts: [
    ManualPart('oil', 'Aceite de motor', 'Engine oil',
        specEs: 'Bajaj DTS-i SAE 20W50 (API SL, JASO MA) · 1 L',
        specEn: 'Bajaj DTS-i SAE 20W50 (API SL, JASO MA) · 1 L'),
    ManualPart('oil_filter', 'Filtro de aceite', 'Oil filter'),
    ManualPart('spark_plugs', 'Bujías (2)', 'Spark plugs (2)',
        specEs: 'Bosch UR4AC o Champion PRZ9HC · luz 0,7-0,8 mm',
        specEn: 'Bosch UR4AC or Champion PRZ9HC · gap 0.7-0.8 mm'),
    ManualPart('air_filter', 'Filtro de aire', 'Air filter'),
    ManualPart('air_box_oring', 'Junta tórica de la caja del filtro',
        'Air box O-ring'),
    ManualPart('fuel_filter', 'Filtro de combustible', 'Fuel filter'),
    ManualPart('brake_pads', 'Pastilla delantera / zapatas traseras',
        'Front pads / rear shoes',
        specEs: 'Disco 240 mm adelante, tambor 130 mm atrás',
        specEn: '240 mm front disc, 130 mm rear drum'),
    ManualPart('brake_fluid', 'Líquido de frenos', 'Brake fluid',
        specEs: 'DOT 3 o DOT 4', specEn: 'DOT 3 or DOT 4'),
    ManualPart('fork_oil', 'Aceite de horquilla', 'Fork oil',
        specEs: 'SAE 10W20 · 140 ml por barra',
        specEn: 'SAE 10W20 · 140 ml per leg'),
    ManualPart('battery', 'Batería', 'Battery',
        specEs: '12 V 5 Ah libre mantenimiento',
        specEn: '12 V 5 Ah maintenance-free'),
    ManualPart('tires', 'Neumáticos', 'Tires',
        specEs: 'Del. 2.75-17 · Tras. 100/90-17, con cámara',
        specEn: 'Front 2.75-17 · Rear 100/90-17, tube type'),
  ],
  intervals: {
    'moto_oil_change': ManualInterval(km: 2500),
    'moto_oil_filter': ManualInterval(km: 2500),
    'moto_general_service': ManualInterval(km: 2500),
    'moto_valve_clearance': ManualInterval(km: 2500),
    'moto_chain_adjust': ManualInterval(km: 2500),
    'moto_cables': ManualInterval(km: 2500),
    'moto_spark_plug': ManualInterval(km: 10000),
    'moto_air_filter': ManualInterval(km: 10000),
    'moto_steering_bearings': ManualInterval(km: 10000),
    'moto_fuel_filter': ManualInterval(km: 15000),
    'moto_brake_pads_front': ManualInterval(km: 15000),
    'moto_brake_pads_rear': ManualInterval(km: 15000),
  },
);
