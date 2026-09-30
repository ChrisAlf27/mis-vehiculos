import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../app_info.dart';
import 'database_service.dart';

class UpdateInfo {
  final String version;

  /// El .apk del release; si el release no trae uno, la página del release.
  final String downloadUrl;
  final String? notes;

  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    this.notes,
  });
}

/// Consulta el último release publicado en GitHub.
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  static const _notifiedKey = 'update_notified_version';

  /// La última versión nueva encontrada en esta sesión, para Ajustes.
  final ValueNotifier<UpdateInfo?> available = ValueNotifier(null);

  /// null si no hay nada más nuevo o no se pudo consultar (sin internet).
  Future<UpdateInfo?> check() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(Uri.parse(
          'https://api.github.com/repos/${AppInfo.githubRepo}/releases/latest'));
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
        ..set(HttpHeaders.userAgentHeader, 'MisVehiculos/${AppInfo.version}');
      final response =
          await request.close().timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(await response.transform(utf8.decoder).join())
          as Map<String, dynamic>;

      final version = (json['tag_name'] as String? ?? '')
          .replaceFirst(RegExp(r'^[vV]'), '');
      if (compareVersions(version, AppInfo.version) <= 0) {
        available.value = null;
        return null;
      }
      final apk = (json['assets'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .where((a) => (a['name'] as String? ?? '').endsWith('.apk'))
          .firstOrNull;
      final info = UpdateInfo(
        version: version,
        downloadUrl: (apk?['browser_download_url'] ??
            json['html_url'] ??
            AppInfo.releasesUrl) as String,
        notes: (json['body'] as String?)?.trim(),
      );
      available.value = info;
      return info;
    } catch (e) {
      debugPrint('No se pudo buscar actualizaciones: $e');
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// true la primera vez que se pregunta por [version]: para avisar una sola
  /// vez por versión y no en cada arranque.
  Future<bool> markNotified(String version) async {
    final db = await DatabaseService().db;
    final rows = await db.query('settings',
        where: 'key = ?', whereArgs: [_notifiedKey], limit: 1);
    if (rows.isNotEmpty && rows.first['value'] == version) return false;
    await db.insert('settings', {'key': _notifiedKey, 'value': version},
        conflictAlgorithm: ConflictAlgorithm.replace);
    return true;
  }
}

/// Compara "1.10.0" con "1.9.2" por número, no como texto. Lo que no es
/// número (un "-beta") se ignora.
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .split(RegExp(r'[.+-]'))
      .take(3)
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final pa = parts(a), pb = parts(b);
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}
