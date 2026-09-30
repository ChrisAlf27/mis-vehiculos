import 'dart:ui' show PlatformDispatcher;

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/default_catalog.dart';
import '../models/app_settings.dart';
import '../models/appointment.dart';
import '../models/interval_override.dart';
import '../models/maintenance_type.dart';
import '../models/mechanic.dart';
import '../models/vehicle.dart';
import '../models/vehicle_type.dart';
import '../models/maintenance_record.dart';
import '../models/km_reading.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const schemaVersion = 5;

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
  /// haya vehículos de ese tipo.
  Future<void> deleteVehicleType(int id) async {
    final database = await db;
    await database.delete('vehicle_types', where: 'id = ?', whereArgs: [id]);
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
