import 'dart:ui' show PlatformDispatcher;

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/default_catalog.dart';
import '../models/app_settings.dart';
import '../models/appointment.dart';
import '../models/interval_override.dart';
import '../models/maintenance_baseline.dart';
import '../models/maintenance_type.dart';
import '../models/mechanic.dart';
import '../models/vehicle.dart';
import '../models/vehicle_type.dart';
import '../models/maintenance_record.dart';
import '../models/km_reading.dart';
import 'backup_match.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const schemaVersion = 8;

  /// La versión más vieja de backup que se puede importar. Una versión nueva
  /// que sólo agrega tablas no la sube: las tablas que faltan quedan vacías.
  static const oldestImportableSchema = 3;

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vehiculos_mantenimiento.db');

    return openDatabase(
      path,
      version: schemaVersion,
      // Sin esto SQLite ignora el ON DELETE CASCADE.
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Una base nueva arranca con el esquema de la versión 1 y pasa por las
  // mismas migraciones que una existente: así hay un único camino.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        license_plate TEXT,
        current_km INTEGER NOT NULL DEFAULT 0,
        photo_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE maintenance_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        maintenance_type_id TEXT NOT NULL,
        date TEXT NOT NULL,
        km_at_service INTEGER NOT NULL,
        cost REAL,
        mechanic TEXT,
        products_used TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');

    await _onUpgrade(db, 1, version);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _migrateToV2(db);
    if (oldVersion < 3) await _migrateToV3(db);
    if (oldVersion < 4) await _migrateToV4(db);
    if (oldVersion < 5) await _migrateToV5(db);
    if (oldVersion < 6) await _migrateToV6(db);
    if (oldVersion < 7) await _migrateToV7(db);
    if (oldVersion < 8) await _migrateToV8(db);
  }

  /// Intervalos por vehículo tomados de un manual de fábrica.
  Future<void> _migrateToV8(Database db) async {
    await db
        .execute('ALTER TABLE interval_overrides ADD COLUMN manual_id TEXT');
  }

  Future<void> _migrateToV7(Database db) async {
    await db.execute('ALTER TABLE vehicle_types ADD COLUMN key TEXT');
    await upgradeCatalogToV7(db);
  }

  /// Marca los tipos de fábrica (auto, moto), los vuelve a crear si se habían
  /// borrado y les suma los mantenimientos nuevos de la v7. También se usa al
  /// restaurar un backup anterior a la v7.
  static Future<void> upgradeCatalogToV7(DatabaseExecutor db) async {
    final locale = PlatformDispatcher.instance.locale.languageCode;
    final typeIdByKey = <String, int>{};
    for (final t in DefaultCatalog.vehicleTypes) {
      final ids = [
        for (final m in DefaultCatalog.maintenanceTypes)
          if (m.vehicleKey == t.key && m.since < 7) m.id,
      ];
      // El tipo de vehículo que tiene más mantenimientos de fábrica de ese
      // tipo: los nombres se pudieron cambiar, los ids no.
      final rows = await db.rawQuery('''
        SELECT mt.vehicle_type_id AS id FROM maintenance_types mt
        JOIN vehicle_types vt ON vt.id = mt.vehicle_type_id
        WHERE vt.key IS NULL AND mt.id IN (${List.filled(ids.length, '?').join(',')})
        GROUP BY mt.vehicle_type_id ORDER BY COUNT(*) DESC LIMIT 1
      ''', ids);
      if (rows.isNotEmpty) {
        final id = rows.first['id'] as int;
        await db.update('vehicle_types', {'key': t.key},
            where: 'id = ?', whereArgs: [id]);
        typeIdByKey[t.key] = id;
      } else {
        final maxOrder = Sqflite.firstIntValue(await db
                .rawQuery('SELECT MAX(sort_order) FROM vehicle_types')) ??
            0;
        typeIdByKey[t.key] = await db.insert('vehicle_types', {
          'name': t.getName(locale),
          'icon': t.icon,
          'sort_order': maxOrder + 1,
          'key': t.key,
        });
      }
    }

    var order = Sqflite.firstIntValue(await db
            .rawQuery('SELECT MAX(sort_order) FROM maintenance_types')) ??
        0;
    // Un tipo recreado recibe todo su catálogo; uno existente, sólo lo nuevo
    // (lo que el usuario borró a propósito no vuelve).
    for (final m in DefaultCatalog.maintenanceTypes) {
      final exists = Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COUNT(*) FROM maintenance_types WHERE id = ?', [m.id])) !=
          0;
      if (exists) continue;
      final typeId = typeIdByKey[m.vehicleKey]!;
      final hasOthers = Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COUNT(*) FROM maintenance_types WHERE vehicle_type_id = ?',
              [typeId])) !=
          0;
      if (m.since < 7 && hasOthers) continue;
      await db.insert('maintenance_types', {
        'id': m.id,
        'vehicle_type_id': typeId,
        'name': m.getName(locale),
        'description': m.getDescription(locale),
        'icon': m.icon,
        'interval_km': m.intervalKm,
        'interval_days': m.intervalDays,
        'priority': m.priority,
        'sort_order': ++order,
      });
    }

    // El cambio de aceite ya no incluye el filtro: se corrige la descripción
    // si nadie la tocó.
    for (final e in DefaultCatalog.oldOilChangeDescriptions.entries) {
      for (final (old, now) in [
        (e.value.es, DefaultCatalog.oilChangeDescriptionEs),
        (e.value.en, DefaultCatalog.oilChangeDescriptionEn),
      ]) {
        await db.update('maintenance_types', {'description': now},
            where: 'id = ? AND description = ?', whereArgs: [e.key, old]);
      }
    }
  }

  /// Vehículos usados: datos de la compra y el punto de partida de cada
  /// mantenimiento cuando no se conoce su historial.
  Future<void> _migrateToV6(Database db) async {
    for (final col in const [
      'used INTEGER NOT NULL DEFAULT 0',
      'acquired_at TEXT',
      'acquired_km INTEGER',
    ]) {
      await db.execute('ALTER TABLE vehicles ADD COLUMN $col');
    }
    await db.execute('''
      CREATE TABLE maintenance_baselines (
        vehicle_id INTEGER NOT NULL,
        maintenance_type_id TEXT NOT NULL,
        mode TEXT NOT NULL,
        km INTEGER,
        date TEXT,
        PRIMARY KEY (vehicle_id, maintenance_type_id),
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');
  }

  /// Un turno pasa a ser del vehículo y a tener varios mantenimientos. Cada
  /// turno de la versión 4 (uno por mantenimiento) queda como un turno con un
  /// solo ítem.
  Future<void> _migrateToV5(Database db) async {
    await db.execute('ALTER TABLE appointments RENAME TO appointments_v4');
    await db.execute('''
      CREATE TABLE appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        scheduled_at TEXT NOT NULL,
        mechanic TEXT,
        notes TEXT,
        remind_minutes_before INTEGER NOT NULL DEFAULT 1440,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE appointment_items (
        appointment_id INTEGER NOT NULL,
        maintenance_type_id TEXT NOT NULL,
        PRIMARY KEY (appointment_id, maintenance_type_id),
        FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE CASCADE
      )
    ''');
    for (final old in await db.query('appointments_v4')) {
      final id = await db.insert('appointments', {
        'vehicle_id': old['vehicle_id'],
        'scheduled_at': old['scheduled_at'],
        'mechanic': old['mechanic'],
        'notes': old['notes'],
        'remind_minutes_before': old['remind_minutes_before'],
      });
      await db.insert('appointment_items', {
        'appointment_id': id,
        'maintenance_type_id': old['maintenance_type_id'],
      });
    }
    await db.execute('DROP TABLE appointments_v4');
  }

  /// Turnos con el mecánico: uno por vehículo y mantenimiento.
  Future<void> _migrateToV4(Database db) async {
    await db.execute('''
      CREATE TABLE appointments (
        vehicle_id INTEGER NOT NULL,
        maintenance_type_id TEXT NOT NULL,
        scheduled_at TEXT NOT NULL,
        mechanic TEXT,
        notes TEXT,
        remind_minutes_before INTEGER NOT NULL DEFAULT 1440,
        PRIMARY KEY (vehicle_id, maintenance_type_id),
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _migrateToV2(Database db) async {
    for (final col in const [
      'km_reminder_enabled INTEGER NOT NULL DEFAULT 0',
      'km_reminder_weekday INTEGER NOT NULL DEFAULT 7',
      'km_reminder_hour INTEGER NOT NULL DEFAULT 20',
      'km_reminder_minute INTEGER NOT NULL DEFAULT 0',
    ]) {
      await db.execute('ALTER TABLE vehicles ADD COLUMN $col');
    }
    await db.execute('''
      CREATE TABLE km_readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        km INTEGER NOT NULL,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');
    // El km actual de cada vehículo pasa a ser su primera lectura.
    await db.execute('''
      INSERT INTO km_readings (vehicle_id, date, km)
      SELECT id, ?, current_km FROM vehicles
    ''', [DateTime.now().toIso8601String()]);
  }

  /// Catálogos configurables: tipos de vehículo, mantenimientos, talleres,
  /// intervalos por vehículo y configuración general.
  Future<void> _migrateToV3(Database db) async {
    await db.execute('''
      CREATE TABLE vehicle_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE maintenance_types (
        id TEXT PRIMARY KEY,
        vehicle_type_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        icon TEXT NOT NULL DEFAULT '🔧',
        interval_km INTEGER NOT NULL DEFAULT 0,
        interval_days INTEGER NOT NULL DEFAULT 0,
        priority TEXT NOT NULL DEFAULT 'medium',
        active INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (vehicle_type_id) REFERENCES vehicle_types(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE mechanics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        notes TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE interval_overrides (
        vehicle_id INTEGER NOT NULL,
        maintenance_type_id TEXT NOT NULL,
        interval_km INTEGER,
        interval_days INTEGER,
        hidden INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (vehicle_id, maintenance_type_id),
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('ALTER TABLE vehicles ADD COLUMN vehicle_type_id INTEGER');

    // Los nombres de fábrica se crean en el idioma del teléfono; después se
    // editan libremente.
    final locale = PlatformDispatcher.instance.locale.languageCode;
    final typeIdByKey = <String, int>{};
    var order = 0;
    for (final t in DefaultCatalog.vehicleTypes) {
      typeIdByKey[t.key] = await db.insert('vehicle_types', {
        'name': t.getName(locale),
        'icon': t.icon,
        'sort_order': order++,
      });
    }
    order = 0;
    for (final m in DefaultCatalog.maintenanceTypes) {
      await db.insert('maintenance_types', {
        'id': m.id,
        'vehicle_type_id': typeIdByKey[m.vehicleKey],
        'name': m.getName(locale),
        'description': m.getDescription(locale),
        'icon': m.icon,
        'interval_km': m.intervalKm,
        'interval_days': m.intervalDays,
        'priority': m.priority,
        'sort_order': order++,
      });
    }

    for (final entry in typeIdByKey.entries) {
      await db.update('vehicles', {'vehicle_type_id': entry.value},
          where: 'type = ?', whereArgs: [entry.key]);
    }
    await db.update(
        'vehicles', {'vehicle_type_id': typeIdByKey[DefaultCatalog.carKey]},
        where: 'vehicle_type_id IS NULL');

    // Los talleres ya usados pasan a la lista.
    await db.execute('''
      INSERT INTO mechanics (name)
      SELECT DISTINCT TRIM(mechanic) FROM maintenance_records
      WHERE mechanic IS NOT NULL AND TRIM(mechanic) <> ''
    ''');
  }

  /// Borra todo y vuelve a cargar lo que viene de un backup, en una sola
  /// transacción: si algo falla, los datos anteriores quedan intactos.
  Future<void> replaceAllData(
      Map<String, List<Map<String, dynamic>>> tables) async {
    final database = await db;
    await database.transaction((txn) async {
      for (final table in _tablesChildrenFirst) {
        await txn.delete(table);
      }
      for (final table in _tablesChildrenFirst.reversed) {
        for (final row in tables[table] ?? const <Map<String, dynamic>>[]) {
          await txn.insert(table, row);
        }
      }
    });
  }

  /// Suma los vehículos [vehicleIds] de un backup a los datos actuales, en una
  /// sola transacción. Un vehículo que ya estaba (misma patente o, sin
  /// patente, mismo nombre, marca y modelo) se reemplaza. [typeKeys] son los
  /// tipos de fábrica del backup (id → clave).
  Future<void> importVehicles(
    Map<String, List<Map<String, dynamic>>> tables, {
    required Set<int> vehicleIds,
    required Map<int, String> typeKeys,
    required bool history,
    required bool mechanics,
  }) async {
    List<Map<String, dynamic>> rows(String table,
            {bool Function(Map)? where}) =>
        [
          for (final r in tables[table] ?? const <Map<String, dynamic>>[])
            if (where == null || where(r)) r,
        ];
    bool ofChosen(Map r) => vehicleIds.contains(r['vehicle_id']);
    Map<String, dynamic> without(Map<String, dynamic> r, String key) =>
        Map.of(r)..remove(key);

    final backupTypes = {
      for (final t in rows('vehicle_types')) t['id'] as int: t,
    };
    final backupMaintenance = {
      for (final m in rows('maintenance_types')) m['id'] as String: m,
    };
    final vehicles =
        rows('vehicles', where: (v) => vehicleIds.contains(v['id']));
    final chosenAppointments =
        history ? rows('appointments', where: ofChosen) : const <Map>[];
    final appointmentIds = {for (final a in chosenAppointments) a['id']};

    final database = await db;
    await database.transaction((txn) async {
      final localTypes = await txn.query('vehicle_types');
      final createdTypes = <int>{};
      final typeMap = <int, int>{};

      /// El tipo local que corresponde a uno del backup: el de fábrica con la
      /// misma clave, o uno con el mismo nombre; si no hay, se crea.
      Future<int> mapType(int backupId) async {
        if (typeMap[backupId] case final id?) return id;
        final key = typeKeys[backupId];
        final source = backupTypes[backupId];
        final name = (source?['name'] as String? ?? '').trim().toLowerCase();
        final local = localTypes
            .where((t) => key != null
                ? t['key'] == key
                : (t['name'] as String).trim().toLowerCase() == name)
            .firstOrNull;
        final int id;
        if (local != null) {
          id = local['id'] as int;
        } else {
          final maxOrder = Sqflite.firstIntValue(await txn
                  .rawQuery('SELECT MAX(sort_order) FROM vehicle_types')) ??
              0;
          id = await txn.insert('vehicle_types', {
            'name': source?['name'] ?? '?',
            'icon': source?['icon'] ?? '🚘',
            'sort_order': maxOrder + 1,
            'key': key,
          });
          createdTypes.add(id);
        }
        return typeMap[backupId] = id;
      }

      final localMaintenance = {
        for (final m in await txn.query('maintenance_types', columns: ['id']))
          m['id'] as String,
      };
      Future<void> ensureMaintenance(String id) async {
        if (localMaintenance.contains(id)) return;
        final m = backupMaintenance[id];
        if (m == null) return;
        await txn.insert('maintenance_types', {
          ...m,
          'vehicle_type_id': await mapType(m['vehicle_type_id'] as int),
        });
        localMaintenance.add(id);
      }

      // Los mantenimientos que usan los vehículos traídos.
      for (final v in vehicles) {
        await mapType(v['vehicle_type_id'] as int);
      }
      final used = <String>{
        for (final r in rows('interval_overrides', where: ofChosen))
          r['maintenance_type_id'] as String,
        for (final r in rows('maintenance_baselines', where: ofChosen))
          r['maintenance_type_id'] as String,
        if (history) ...[
          for (final r in rows('maintenance_records', where: ofChosen))
            r['maintenance_type_id'] as String,
          for (final r in rows('appointment_items',
              where: (i) => appointmentIds.contains(i['appointment_id'])))
            r['maintenance_type_id'] as String,
        ],
      };
      // Un tipo de vehículo que no existía viene con todo su catálogo.
      for (final m in backupMaintenance.values) {
        if (used.contains(m['id']) ||
            createdTypes.contains(typeMap[m['vehicle_type_id']])) {
          await ensureMaintenance(m['id'] as String);
        }
      }

      final localVehicles = List.of(await txn.query('vehicles'));
      final vehicleMap = <int, int>{};
      for (final v in vehicles) {
        final match = BackupMatch.find(v, localVehicles);
        if (match != null) {
          await txn
              .delete('vehicles', where: 'id = ?', whereArgs: [match['id']]);
          localVehicles.remove(match);
        }
        vehicleMap[v['id'] as int] = await txn.insert('vehicles', {
          ...without(v, 'id'),
          'vehicle_type_id': typeMap[v['vehicle_type_id']],
        });
      }

      Future<void> copy(String table, {bool keepId = false}) async {
        for (final r in rows(table, where: ofChosen)) {
          if (!localMaintenance.contains(r['maintenance_type_id']) &&
              r.containsKey('maintenance_type_id')) {
            continue;
          }
          await txn.insert(table, {
            ...(keepId ? r : without(r, 'id')),
            'vehicle_id': vehicleMap[r['vehicle_id']],
          });
        }
      }

      await copy('km_readings');
      await copy('interval_overrides', keepId: true);
      await copy('maintenance_baselines', keepId: true);
      if (history) {
        await copy('maintenance_records');
        for (final a in chosenAppointments) {
          final id = await txn.insert('appointments', {
            ...without(Map<String, dynamic>.from(a), 'id'),
            'vehicle_id': vehicleMap[a['vehicle_id']],
          });
          for (final i in rows('appointment_items',
              where: (i) => i['appointment_id'] == a['id'])) {
            if (!localMaintenance.contains(i['maintenance_type_id'])) continue;
            await txn.insert('appointment_items', {...i, 'appointment_id': id});
          }
        }
        await _deleteEmptyAppointments(txn);
      }

      if (mechanics) {
        final names = {
          for (final m in await txn.query('mechanics', columns: ['name']))
            (m['name'] as String).trim().toLowerCase(),
        };
        for (final m in rows('mechanics')) {
          final name = (m['name'] as String? ?? '').trim();
          if (name.isEmpty || !names.add(name.toLowerCase())) continue;
          await txn.insert('mechanics', without(m, 'id'));
        }
      }
    });
  }

  Future<Map<String, List<Map<String, dynamic>>>> dumpAllData() async {
    final database = await db;
    return {
      for (final table in _tablesChildrenFirst.reversed)
        table: await database.query(table),
    };
  }

  // Orden para borrar sin violar claves foráneas; al revés, para insertar.
  static const _tablesChildrenFirst = [
    'settings',
    'appointment_items',
    'appointments',
    'interval_overrides',
    'maintenance_baselines',
    'km_readings',
    'maintenance_records',
    'vehicles',
    'mechanics',
    'maintenance_types',
    'vehicle_types',
  ];

  // ─── SETTINGS ─────────────────────────────────────────────────────────────

  Future<AppSettings> getSettings() async {
    final database = await db;
    final rows = await database.query('settings');
    return AppSettings.fromKeyValues({
      for (final r in rows) r['key'] as String: r['value'] as String,
    });
  }

  Future<void> saveSettings(AppSettings settings) async {
    final database = await db;
    final batch = database.batch();
    settings.toKeyValues().forEach((key, value) {
      batch.insert('settings', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
    await batch.commit(noResult: true);
  }

  // ─── VEHICLE TYPES ────────────────────────────────────────────────────────

  Future<List<VehicleType>> getVehicleTypes() async {
    final database = await db;
    final maps =
        await database.query('vehicle_types', orderBy: 'sort_order, name');
    return maps.map(VehicleType.fromMap).toList();
  }

  Future<int> insertVehicleType(VehicleType type) async {
    final database = await db;
    final maxOrder = Sqflite.firstIntValue(await database
            .rawQuery('SELECT MAX(sort_order) FROM vehicle_types')) ??
        0;
    return database.insert('vehicle_types',
        type.copyWith(sortOrder: maxOrder + 1).toMap()..remove('id'));
  }

  Future<void> updateVehicleType(VehicleType type) async {
    final database = await db;
    await database.update('vehicle_types', type.toMap(),
        where: 'id = ?', whereArgs: [type.id]);
  }

  Future<int> countVehiclesOfType(int vehicleTypeId) async {
    final database = await db;
    return Sqflite.firstIntValue(await database.rawQuery(
            'SELECT COUNT(*) FROM vehicles WHERE vehicle_type_id = ?',
            [vehicleTypeId])) ??
        0;
  }

  /// Borra el tipo y sus mantenimientos. El llamador verifica antes que no
  /// haya vehículos de ese tipo. Los de fábrica (auto, moto) no se borran.
  Future<void> deleteVehicleType(int id) async {
    final database = await db;
    await database.delete('vehicle_types',
        where: 'id = ? AND key IS NULL', whereArgs: [id]);
  }

  // ─── MAINTENANCE TYPES ────────────────────────────────────────────────────

  Future<List<MaintenanceType>> getMaintenanceTypes({
    int? vehicleTypeId,
    bool onlyActive = false,
  }) async {
    final database = await db;
    final where = <String>[
      if (vehicleTypeId != null) 'vehicle_type_id = ?',
      if (onlyActive) 'active = 1',
    ];
    final maps = await database.query(
      'maintenance_types',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: [if (vehicleTypeId != null) vehicleTypeId],
      orderBy: 'sort_order, name',
    );
    return maps.map(MaintenanceType.fromMap).toList();
  }

  Future<Map<String, MaintenanceType>> getMaintenanceTypesById() async => {
        for (final t in await getMaintenanceTypes()) t.id: t,
      };

  Future<void> saveMaintenanceType(MaintenanceType type) async {
    final database = await db;
    await database.insert('maintenance_types', type.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> countRecordsOfMaintenanceType(String id) async {
    final database = await db;
    return Sqflite.firstIntValue(await database.rawQuery(
            'SELECT COUNT(*) FROM maintenance_records WHERE maintenance_type_id = ?',
            [id])) ??
        0;
  }

  Future<void> deleteMaintenanceType(String id) async {
    final database = await db;
    await database.delete('appointment_items',
        where: 'maintenance_type_id = ?', whereArgs: [id]);
    await _deleteEmptyAppointments(database);
    await database.delete('interval_overrides',
        where: 'maintenance_type_id = ?', whereArgs: [id]);
    await database.delete('maintenance_baselines',
        where: 'maintenance_type_id = ?', whereArgs: [id]);
    await database
        .delete('maintenance_types', where: 'id = ?', whereArgs: [id]);
  }

  // ─── MECHANICS ────────────────────────────────────────────────────────────

  Future<List<Mechanic>> getMechanics() async {
    final database = await db;
    final maps =
        await database.query('mechanics', orderBy: 'name COLLATE NOCASE');
    return maps.map(Mechanic.fromMap).toList();
  }

  Future<void> saveMechanic(Mechanic mechanic) async {
    final database = await db;
    if (mechanic.id == null) {
      await database.insert('mechanics', mechanic.toMap()..remove('id'));
    } else {
      await database.update('mechanics', mechanic.toMap(),
          where: 'id = ?', whereArgs: [mechanic.id]);
    }
  }

  /// Suma a la lista un taller escrito a mano, si no estaba.
  Future<void> ensureMechanic(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final database = await db;
    final existing = await database.query('mechanics',
        where: 'name = ? COLLATE NOCASE', whereArgs: [trimmed], limit: 1);
    if (existing.isEmpty) {
      await database.insert('mechanics', {'name': trimmed});
    }
  }

  Future<void> deleteMechanic(int id) async {
    final database = await db;
    await database.delete('mechanics', where: 'id = ?', whereArgs: [id]);
  }

  /// El taller del último servicio de este vehículo, para sugerirlo.
  Future<String?> getLastMechanicForVehicle(int vehicleId) async {
    final database = await db;
    final maps = await database.query(
      'maintenance_records',
      columns: ['mechanic'],
      where: "vehicle_id = ? AND mechanic IS NOT NULL AND mechanic <> ''",
      whereArgs: [vehicleId],
      orderBy: _newestFirst,
      limit: 1,
    );
    return maps.isEmpty ? null : maps.first['mechanic'] as String?;
  }

  // ─── APPOINTMENTS ─────────────────────────────────────────────────────────

  /// Turnos del vehículo (o de todos, sin [vehicleId]), del más cercano al
  /// más lejano, cada uno con sus mantenimientos.
  Future<List<Appointment>> getAppointments({int? vehicleId}) async {
    final database = await db;
    final rows = await database.query(
      'appointments',
      where: vehicleId == null ? null : 'vehicle_id = ?',
      whereArgs: vehicleId == null ? null : [vehicleId],
      orderBy: 'scheduled_at',
    );
    final items = await database.query('appointment_items');
    final byAppointment = <int, List<String>>{};
    for (final i in items) {
      byAppointment
          .putIfAbsent(i['appointment_id'] as int, () => [])
          .add(i['maintenance_type_id'] as String);
    }
    return [
      for (final r in rows)
        Appointment.fromMap(r,
            maintenanceTypeIds: byAppointment[r['id'] as int] ?? const []),
    ];
  }

  Future<int> saveAppointment(Appointment appointment) async {
    final database = await db;
    return database.transaction((txn) async {
      final int id;
      if (appointment.id == null) {
        id =
            await txn.insert('appointments', appointment.toMap()..remove('id'));
      } else {
        id = appointment.id!;
        await txn.update('appointments', appointment.toMap(),
            where: 'id = ?', whereArgs: [id]);
        await txn.delete('appointment_items',
            where: 'appointment_id = ?', whereArgs: [id]);
      }
      for (final typeId in appointment.maintenanceTypeIds) {
        await txn.insert('appointment_items', {
          'appointment_id': id,
          'maintenance_type_id': typeId,
        });
      }
      return id;
    });
  }

  Future<void> deleteAppointment(int id) async {
    final database = await db;
    await database.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  /// Saca un mantenimiento de los turnos del vehículo (ya se hizo) y borra
  /// los turnos que quedan vacíos.
  Future<void> _removeFromAppointments(
      DatabaseExecutor database, int vehicleId, String typeId) async {
    await database.rawDelete('''
      DELETE FROM appointment_items
      WHERE maintenance_type_id = ?
        AND appointment_id IN (SELECT id FROM appointments WHERE vehicle_id = ?)
    ''', [typeId, vehicleId]);
    await _deleteEmptyAppointments(database);
  }

  Future<void> _deleteEmptyAppointments(DatabaseExecutor database) =>
      database.rawDelete('''
        DELETE FROM appointments
        WHERE id NOT IN (SELECT appointment_id FROM appointment_items)
      ''');

  // ─── INTERVAL OVERRIDES ───────────────────────────────────────────────────

  Future<Map<String, IntervalOverride>> getIntervalOverrides(
      int vehicleId) async {
    final database = await db;
    final maps = await database.query('interval_overrides',
        where: 'vehicle_id = ?', whereArgs: [vehicleId]);
    return {
      for (final m in maps.map(IntervalOverride.fromMap))
        m.maintenanceTypeId: m,
    };
  }

  /// Un override vacío se borra: vuelve a valer el intervalo del tipo.
  Future<void> saveIntervalOverride(IntervalOverride override) async {
    final database = await db;
    if (override.isEmpty) {
      await database.delete('interval_overrides',
          where: 'vehicle_id = ? AND maintenance_type_id = ?',
          whereArgs: [override.vehicleId, override.maintenanceTypeId]);
    } else {
      await database.insert('interval_overrides', override.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // ─── MAINTENANCE BASELINES ────────────────────────────────────────────────

  Future<Map<String, MaintenanceBaseline>> getBaselines(int vehicleId) async {
    final database = await db;
    final maps = await database.query('maintenance_baselines',
        where: 'vehicle_id = ?', whereArgs: [vehicleId]);
    return {
      for (final b in maps.map(MaintenanceBaseline.fromMap))
        b.maintenanceTypeId: b,
    };
  }

  Future<void> saveBaselines(List<MaintenanceBaseline> baselines) async {
    final database = await db;
    final batch = database.batch();
    for (final b in baselines) {
      batch.insert('maintenance_baselines', b.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // ─── VEHICLES ─────────────────────────────────────────────────────────────

  Future<int> insertVehicle(Vehicle vehicle) async {
    final database = await db;
    final id = await database.insert('vehicles', vehicle.toMap()..remove('id'));
    await _insertKmReading(database, id, vehicle.currentKm);
    return id;
  }

  Future<List<Vehicle>> getVehicles() async {
    final database = await db;
    final maps = await database.query('vehicles', orderBy: 'name ASC');
    return maps.map(Vehicle.fromMap).toList();
  }

  Future<Vehicle?> getVehicle(int id) async {
    final database = await db;
    final maps = await database.query(
      'vehicles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Vehicle.fromMap(maps.first);
  }

  Future<int> updateVehicle(Vehicle vehicle) async {
    final database = await db;
    final previous = await getVehicle(vehicle.id!);
    final result = await database.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
    if (previous != null && previous.currentKm != vehicle.currentKm) {
      await _insertKmReading(database, vehicle.id!, vehicle.currentKm);
    }
    return result;
  }

  Future<int> updateVehicleKm(int vehicleId, int newKm) async {
    final database = await db;
    final result = await database.update(
      'vehicles',
      {'current_km': newKm},
      where: 'id = ?',
      whereArgs: [vehicleId],
    );
    await _insertKmReading(database, vehicleId, newKm);
    return result;
  }

  /// Carga el km actual que informa el usuario. Un km menor al registrado se
  /// rechaza: el odómetro no retrocede, así que es casi seguro un error de tipeo.
  Future<KmUpdateResult> registerCurrentKm(int vehicleId, int km) async {
    final vehicle = await getVehicle(vehicleId);
    if (vehicle == null) return KmUpdateResult.vehicleNotFound;
    if (km < vehicle.currentKm) return KmUpdateResult.lowerThanCurrent;
    await updateVehicleKm(vehicleId, km);
    return KmUpdateResult.saved;
  }

  Future<int> deleteVehicle(int id) async {
    final database = await db;
    return database.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  // ─── KM READINGS ──────────────────────────────────────────────────────────

  Future<void> _insertKmReading(
          DatabaseExecutor database, int vehicleId, int km) =>
      database.insert('km_readings', {
        'vehicle_id': vehicleId,
        'date': DateTime.now().toIso8601String(),
        'km': km,
      });

  /// Todas las lecturas conocidas del odómetro, de la más vieja a la más nueva:
  /// las cargadas a mano más el km de cada mantenimiento registrado.
  Future<List<KmReading>> getKmReadings(int vehicleId) async {
    final database = await db;
    final maps = await database.rawQuery('''
      SELECT date, km FROM km_readings WHERE vehicle_id = ?
      UNION ALL
      SELECT date, km_at_service AS km FROM maintenance_records WHERE vehicle_id = ?
    ''', [vehicleId, vehicleId]);
    final readings = maps
        .map((m) => KmReading(
              date: DateTime.parse(m['date'] as String),
              km: m['km'] as int,
            ))
        .toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        return byDate != 0 ? byDate : a.km.compareTo(b.km);
      });
    return readings;
  }

  // ─── MAINTENANCE RECORDS ───────────────────────────────────────────────────

  // Orden de "más reciente primero": la fecha del servicio manda; a igual
  // fecha, el de más km; a igual km, el cargado último.
  static const _newestFirst = 'date DESC, km_at_service DESC, id DESC';

  Future<int> insertMaintenanceRecord(MaintenanceRecord record) async {
    final database = await db;
    final id = await database.insert(
      'maintenance_records',
      record.toMap()..remove('id'),
    );
    // El registro ya es una lectura de km con su propia fecha: sólo se
    // actualiza el km actual, sin sumar otra lectura con fecha de hoy.
    final vehicle = await getVehicle(record.vehicleId);
    if (vehicle != null && record.kmAtService > vehicle.currentKm) {
      await database.update(
        'vehicles',
        {'current_km': record.kmAtService},
        where: 'id = ?',
        whereArgs: [record.vehicleId],
      );
    }
    // Registrar el servicio lo saca del turno en el que estuviera.
    await _removeFromAppointments(
        database, record.vehicleId, record.maintenanceTypeId);
    return id;
  }

  Future<List<MaintenanceRecord>> getRecordsForVehicle(int vehicleId) async {
    final database = await db;
    final maps = await database.query(
      'maintenance_records',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: _newestFirst,
    );
    return maps.map(MaintenanceRecord.fromMap).toList();
  }

  Future<MaintenanceRecord?> getLastRecordForType(
    int vehicleId,
    String maintenanceTypeId,
  ) async {
    final database = await db;
    final maps = await database.query(
      'maintenance_records',
      where: 'vehicle_id = ? AND maintenance_type_id = ?',
      whereArgs: [vehicleId, maintenanceTypeId],
      orderBy: _newestFirst,
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return MaintenanceRecord.fromMap(maps.first);
  }

  /// El último registro de cada tipo por FECHA DEL SERVICIO, no por orden de
  /// carga: un servicio viejo cargado hoy no pisa a uno más reciente.
  Future<Map<String, MaintenanceRecord>> getLastRecordsByType(
    int vehicleId,
  ) async {
    final records = await getRecordsForVehicle(vehicleId);
    final last = <String, MaintenanceRecord>{};
    for (final r in records) {
      last.putIfAbsent(r.maintenanceTypeId, () => r);
    }
    return last;
  }

  Future<int> updateMaintenanceRecord(MaintenanceRecord record) async {
    final database = await db;
    return database.update(
      'maintenance_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteMaintenanceRecord(int id) async {
    final database = await db;
    return database.delete(
      'maintenance_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalCostForVehicle(int vehicleId) async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT SUM(cost) as total FROM maintenance_records WHERE vehicle_id = ?',
      [vehicleId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<MaintenanceRecord>> getAllRecords() async {
    final database = await db;
    final maps = await database.query(
      'maintenance_records',
      orderBy: _newestFirst,
    );
    return maps.map(MaintenanceRecord.fromMap).toList();
  }
}
