import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../data/default_catalog.dart';
import 'database_service.dart';
import 'notification_service.dart';

enum BackupError { invalidFile, notOurs, tooNew }

class BackupException implements Exception {
  final BackupError error;
  const BackupException(this.error);
}

class BackupFile {
  final String uri;
  final String name;
  final DateTime modified;

  const BackupFile(
      {required this.uri, required this.name, required this.modified});
}

/// Backup de TODOS los datos en un archivo JSON, para cambiar de teléfono o
/// guardar una copia.
class BackupService {
  static const _appKey = 'mis_vehiculos_backup';

  final DatabaseService _db = DatabaseService();

  static const _channel = MethodChannel('mis_vehiculos/backups');

  /// Guarda un backup nuevo en la carpeta de backups y devuelve el archivo,
  /// por si además se quiere compartir.
  Future<File> export() async {
    final data = {
      'app': _appKey,
      'schema_version': DatabaseService.schemaVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'tables': await _db.dumpAllData(),
    };
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final name = 'mis_vehiculos_backup_$stamp.json';
    final bytes = utf8.encode(jsonEncode(data));
    await _withStoragePermission(() => _channel
        .invokeMethod('save', {'name': name, 'bytes': bytes}));

    final file = File('${(await getTemporaryDirectory()).path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> share(File file, {required String subject}) =>
      Share.shareXFiles([XFile(file.path)], subject: subject);

  /// Los backups de la carpeta, del más nuevo al más viejo.
  Future<List<BackupFile>> list() async {
    final rows = await _withStoragePermission(
        () => _channel.invokeListMethod<Map>('list'));
    return [
      for (final r in rows ?? const <Map>[])
        if ((r['name'] as String).toLowerCase().endsWith('.json'))
          BackupFile(
            uri: r['uri'] as String,
            name: r['name'] as String,
            modified:
                DateTime.fromMillisecondsSinceEpoch(r['modified'] as int),
          ),
    ];
  }

  /// Lee y valida un backup de la carpeta. No toca los datos: el llamador
  /// confirma y después llama a [restore].
  Future<Map<String, dynamic>> read(BackupFile file) async {
    final bytes =
        await _channel.invokeMethod<Uint8List>('read', {'uri': file.uri});
    return decode(bytes);
  }

  /// Deja elegir un archivo de cualquier lado (arranca en la carpeta de
  /// backups). Null si se canceló.
  Future<Map<String, dynamic>?> pickOther() async {
    final bytes = await _channel.invokeMethod<Uint8List>('pick');
    return bytes == null ? null : decode(bytes);
  }

  /// En Android 9 o anterior hace falta permiso de almacenamiento: se pide la
  /// primera vez que el sistema lo rechaza.
  Future<T> _withStoragePermission<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PlatformException catch (e) {
      if (e.code != 'permission' || !await Permission.storage.request().isGranted) {
        rethrow;
      }
      return action();
    }
  }

  static Map<String, dynamic> decode(List<int>? bytes) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes!));
    } catch (_) {
      throw const BackupException(BackupError.invalidFile);
    }
    if (decoded is! Map<String, dynamic> || decoded['app'] != _appKey) {
      throw const BackupException(BackupError.notOurs);
    }
    final version = decoded['schema_version'];
    if (version is! int || version < DatabaseService.oldestImportableSchema) {
      throw const BackupException(BackupError.invalidFile);
    }
    if (version > DatabaseService.schemaVersion) {
      throw const BackupException(BackupError.tooNew);
    }
    return decoded;
  }

  /// Las tablas del backup, ya llevadas al esquema actual.
  static Map<String, List<Map<String, dynamic>>> tablesOf(
      Map<String, dynamic> backup) {
    final tables = (backup['tables'] as Map<String, dynamic>).map(
      (table, rows) => MapEntry(
        table,
        (rows as List).map((r) => Map<String, dynamic>.from(r as Map)).toList(),
      ),
    );
    upgradeTables(tables, backup['schema_version'] as int);
    return tables;
  }

  /// Reemplaza TODOS los datos por los del backup.
  Future<void> restore(Map<String, dynamic> backup) async {
    await _db.replaceAllData(tablesOf(backup));
    if ((backup['schema_version'] as int) < 7) {
      await DatabaseService.upgradeCatalogToV7(await _db.db);
    }
    await _afterImport();
  }

  /// Suma a los datos actuales sólo los vehículos elegidos del backup. Un
  /// vehículo que ya estaba (ver [BackupMatch.find]) se reemplaza.
  Future<void> importSelected(
    Map<String, dynamic> backup, {
    required Set<int> vehicleIds,
    required bool history,
    required bool mechanics,
  }) async {
    final tables = tablesOf(backup);
    await _db.importVehicles(
      tables,
      vehicleIds: vehicleIds,
      typeKeys: builtInTypeKeys(tables),
      history: history,
      mechanics: mechanics,
    );
    await _afterImport();
  }

  /// Los tipos de vehículo de fábrica del backup (id → clave). Los backups
  /// anteriores a la v7 no tienen la clave: se deduce por los mantenimientos
  /// de fábrica que tiene cada tipo, igual que en la migración.
  static Map<int, String> builtInTypeKeys(
      Map<String, List<Map<String, dynamic>>> tables) {
    final keys = <int, String>{
      for (final t in tables['vehicle_types'] ?? const <Map<String, dynamic>>[])
        if (t['key'] != null) t['id'] as int: t['key'] as String,
    };
    for (final def in DefaultCatalog.vehicleTypes) {
      if (keys.containsValue(def.key)) continue;
      final defaultIds = {
        for (final m in DefaultCatalog.maintenanceTypes)
          if (m.vehicleKey == def.key && m.since < 7) m.id,
      };
      final counts = <int, int>{};
      for (final m in tables['maintenance_types'] ?? const []) {
        final typeId = m['vehicle_type_id'] as int;
        if (defaultIds.contains(m['id']) && !keys.containsKey(typeId)) {
          counts[typeId] = (counts[typeId] ?? 0) + 1;
        }
      }
      if (counts.isEmpty) continue;
      final best =
          counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
      keys[best] = def.key;
    }
    return keys;
  }

  Future<void> _afterImport() async {
    final notifications = NotificationService();
    await notifications.cancelAll();
    await notifications.syncKmReminders(await _db.getVehicles());
    await notifications.rescheduleMaintenanceReminders();
    notifications.dataChanged.value++;
  }

  /// Lleva las tablas de un backup viejo al esquema actual, igual que las
  /// migraciones de la base.
  static void upgradeTables(
      Map<String, List<Map<String, dynamic>>> tables, int version) {
    if (version < 5) {
      // En la v4 había un turno por mantenimiento; ahora un turno tiene ítems.
      final old = tables.remove('appointments') ?? const [];
      final appointments = <Map<String, dynamic>>[];
      final items = <Map<String, dynamic>>[];
      var id = 1;
      for (final o in old) {
        appointments.add({
          'id': id,
          'vehicle_id': o['vehicle_id'],
          'scheduled_at': o['scheduled_at'],
          'mechanic': o['mechanic'],
          'notes': o['notes'],
          'remind_minutes_before': o['remind_minutes_before'] ?? 1440,
        });
        items.add({
          'appointment_id': id,
          'maintenance_type_id': o['maintenance_type_id'],
        });
        id++;
      }
      tables['appointments'] = appointments;
      tables['appointment_items'] = items;
    }
  }

  static int countVehicles(Map<String, dynamic> backup) =>
      ((backup['tables'] as Map?)?['vehicles'] as List?)?.length ?? 0;
}
