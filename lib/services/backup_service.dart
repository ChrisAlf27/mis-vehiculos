import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'database_service.dart';
import 'notification_service.dart';

enum BackupError { invalidFile, notOurs, tooNew }

class BackupException implements Exception {
  final BackupError error;
  const BackupException(this.error);
}

/// Backup de TODOS los datos en un archivo JSON, para cambiar de teléfono o
/// guardar una copia.
class BackupService {
  static const _appKey = 'mis_vehiculos_backup';

  final DatabaseService _db = DatabaseService();

  Future<void> exportAndShare({required String subject}) async {
    final data = {
      'app': _appKey,
      'schema_version': DatabaseService.schemaVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'tables': await _db.dumpAllData(),
    };
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${dir.path}/mis_vehiculos_backup_$stamp.json');
    await file.writeAsString(jsonEncode(data));
    await Share.shareXFiles([XFile(file.path)], subject: subject);
  }

  /// Deja elegir un archivo y lo lee. Null si se canceló. No toca los datos:
  /// el llamador confirma y después llama a [restore].
  Future<Map<String, dynamic>?> pickBackup() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = result?.files.single.path;
    if (path == null) return null;

    final Object? decoded;
    try {
      decoded = jsonDecode(await File(path).readAsString());
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

  Future<void> restore(Map<String, dynamic> backup) async {
    final tables = (backup['tables'] as Map<String, dynamic>).map(
      (table, rows) => MapEntry(
        table,
        (rows as List).map((r) => Map<String, dynamic>.from(r as Map)).toList(),
      ),
    );
    upgradeTables(tables, backup['schema_version'] as int);
    await _db.replaceAllData(tables);

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
