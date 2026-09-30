import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../l10n/app_localizations.dart';
import '../l10n/l10n_helper.dart';
import '../models/km_reading.dart';
import '../models/maintenance_record.dart';
import '../models/maintenance_type.dart';
import '../models/vehicle.dart';
import 'database_service.dart';
import 'recommendation_service.dart';

/// Responde el botón "Cargar km" cuando la app está cerrada o en segundo plano.
/// Corre en un isolate aparte: por eso es una función de nivel superior.
@pragma('vm:entry-point')
Future<void> onBackgroundNotificationResponse(
    NotificationResponse response) async {
  DartPluginRegistrant.ensureInitialized();
  await NotificationService().handleKmReply(response);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const _kmPayloadPrefix = 'km:';
  static const _vehiclePayloadPrefix = 'vehicle:';
  static const _updatePayloadPrefix = 'update:';
  static const _kmInputActionId = 'km_input';

  /// Ícono blanco de la barra de estado (res/drawable/ic_notification.xml).
  static const _smallIcon = '@drawable/ic_notification';

  // Rangos de ids por tipo, para que no se pisen entre vehículos.
  static const _kmReminderIdBase = 100000;
  static const _kmResultIdBase = 200000;
  static const _maintenanceIdBase = 1000000;
  static const _appointmentIdBase = 2000000;
  static const _scheduledIdEnd = 3000000;
  static const _updateId = 3000001;

  /// Se dispara al tocar una notificación con la app viva: abre el vehículo,
  /// con el diálogo de km si [askKm].
  void Function(int vehicleId, bool askKm)? onVehicleNotificationOpened;

  /// Se dispara al tocar el aviso de versión nueva, con el link de descarga.
  void Function(String url)? onUpdateNotificationOpened;

  /// Avisa a las pantallas abiertas que cambiaron los datos.
  final ValueNotifier<int> dataChanged = ValueNotifier(0);

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (_) {
      // Sin zona conocida los horarios se interpretarían en UTC.
      tz.setLocalLocation(tz.getLocation('America/Argentina/Buenos_Aires'));
    }

    const androidSettings = AndroidInitializationSettings(_smallIcon);
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );

    _initialized = true;
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    if (await handleKmReply(response)) {
      dataChanged.value++;
      return;
    }
    final url = updateUrlFromPayload(response.payload);
    if (url != null) {
      onUpdateNotificationOpened?.call(url);
      return;
    }
    final target = _targetFromPayload(response.payload);
    if (target != null) {
      onVehicleNotificationOpened?.call(target.vehicleId, target.askKm);
    }
  }

  /// Si la app se abrió tocando el aviso de versión nueva, el link.
  Future<String?> updateUrlFromLaunch() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return updateUrlFromPayload(details!.notificationResponse?.payload);
  }

  String? updateUrlFromPayload(String? payload) =>
      payload != null && payload.startsWith(_updatePayloadPrefix)
          ? payload.substring(_updatePayloadPrefix.length)
          : null;

  Future<void> showUpdateAvailable(String version, String url) async {
    final l10n = await currentL10n();
    await _plugin.show(
      _updateId,
      l10n.updateNotifTitle,
      l10n.updateNotifBody(version),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'update_channel',
          l10n.updateChannelName,
          channelDescription: l10n.updateChannelDescription,
          icon: _smallIcon,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      payload: '$_updatePayloadPrefix$url',
    );
  }

  /// Si la app se abrió tocando una notificación, a qué vehículo ir.
  Future<({int vehicleId, bool askKm})?> targetFromLaunch() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    final response = details!.notificationResponse;
    if (response == null || response.actionId != null) return null;
    return _targetFromPayload(response.payload);
  }

  ({int vehicleId, bool askKm})? _targetFromPayload(String? payload) {
    if (payload == null) return null;
    for (final (prefix, askKm) in [
      (_kmPayloadPrefix, true),
      (_vehiclePayloadPrefix, false),
    ]) {
      if (payload.startsWith(prefix)) {
        final id = int.tryParse(payload.substring(prefix.length));
        return id == null ? null : (vehicleId: id, askKm: askKm);
      }
    }
    return null;
  }

  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  AndroidNotificationDetails _kmChannel(
    AppLocalizations l10n, {
    Importance importance = Importance.high,
    Priority priority = Priority.high,
    List<AndroidNotificationAction>? actions,
    int? timeoutAfter,
  }) =>
      AndroidNotificationDetails(
        'km_channel',
        l10n.channelKm,
        channelDescription: l10n.channelKmDesc,
        importance: importance,
        priority: priority,
        icon: _smallIcon,
        actions: actions,
        timeoutAfter: timeoutAfter,
      );

  AndroidNotificationDetails _maintenanceChannel(
    AppLocalizations l10n, {
    StyleInformation? style,
  }) =>
      AndroidNotificationDetails(
        'maintenance_channel',
        l10n.channelMaintenance,
        channelDescription: l10n.channelMaintenanceDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: _smallIcon,
        styleInformation: style,
      );

  // ─── RECORDATORIO DE KM ─────────────────────────────────────────────────

  Future<void> scheduleKmReminder(Vehicle vehicle) async {
    await initialize();
    final id = _kmReminderIdBase + vehicle.id!;
    await _plugin.cancel(id);
    if (!vehicle.kmReminderEnabled) return;

    final l10n = await currentL10n();
    await _plugin.zonedSchedule(
      id,
      l10n.kmPromptTitle(vehicle.name),
      l10n.kmPromptBody,
      _nextWeekly(
        vehicle.kmReminderWeekday,
        vehicle.kmReminderHour,
        vehicle.kmReminderMinute,
      ),
      NotificationDetails(
        android: _kmChannel(
          l10n,
          actions: [
            AndroidNotificationAction(
              _kmInputActionId,
              l10n.kmActionLabel,
              inputs: [
                AndroidNotificationActionInput(label: l10n.kmInputLabel)
              ],
            ),
          ],
        ),
      ),
      payload: '$_kmPayloadPrefix${vehicle.id}',
      // Inexacta a propósito: unos minutos de diferencia no importan y así no
      // hace falta el permiso de alarmas exactas de Android 14.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancelKmReminder(int vehicleId) =>
      _plugin.cancel(_kmReminderIdBase + vehicleId);

  /// Reprograma todos los recordatorios; se llama al abrir la app y al
  /// cambiar de idioma (el texto queda fijo al programarlos).
  Future<void> syncKmReminders(List<Vehicle> vehicles) async {
    for (final v in vehicles) {
      await scheduleKmReminder(v);
    }
  }

  tz.TZDateTime _nextWeekly(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var date =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (date.weekday != weekday || !date.isAfter(now)) {
      date = tz.TZDateTime(
          tz.local, date.year, date.month, date.day + 1, hour, minute);
    }
    return date;
  }

  /// Procesa el km escrito en la notificación. Devuelve true si la respuesta
  /// era una carga de km (válida o no).
  Future<bool> handleKmReply(NotificationResponse response) async {
    if (response.actionId != _kmInputActionId) return false;
    final target = _targetFromPayload(response.payload);
    if (target == null) return false;
    final vehicleId = target.vehicleId;

    await initialize();
    final l10n = await currentL10n();
    final db = DatabaseService();
    final vehicle = await db.getVehicle(vehicleId);
    final name = vehicle?.name ?? l10n.genericVehicle;
    final km = parseKm(response.input);

    String message;
    var saved = false;
    if (km == null) {
      message = l10n.kmNotValid(response.input ?? '');
    } else {
      switch (await db.registerCurrentKm(vehicleId, km)) {
        case KmUpdateResult.saved:
          message = l10n.kmSaved('$km');
          saved = true;
          break;
        case KmUpdateResult.lowerThanCurrent:
          message = l10n.kmLowerThanCurrent('$km', '${vehicle!.currentKm}');
          break;
        case KmUpdateResult.vehicleNotFound:
          message = l10n.kmVehicleGone;
          break;
      }
    }

    await _plugin.show(
      _kmResultIdBase + vehicleId,
      name,
      message,
      NotificationDetails(
        android: _kmChannel(
          l10n,
          importance: Importance.low,
          priority: Priority.low,
          timeoutAfter: 10000,
        ),
      ),
    );
    // El km nuevo mueve la fecha estimada de cada servicio.
    if (saved) await rescheduleMaintenanceReminders();
    return true;
  }

  // ─── AVISOS DE MANTENIMIENTO Y TURNOS ───────────────────────────────────

  /// Vuelve a calcular y programar todos los avisos de mantenimiento y de
  /// turnos. Es idempotente: se puede llamar después de cualquier cambio.
  Future<void> rescheduleMaintenanceReminders() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= _maintenanceIdBase && p.id < _scheduledIdEnd) {
        await _plugin.cancel(p.id);
      }
    }

    final l10n = await currentL10n();
    final db = DatabaseService();
    final settings = await db.getSettings();
    final now = tz.TZDateTime.now(tz.local);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
    final vehicles = {for (final v in await db.getVehicles()) v.id!: v};
    final types = await db.getMaintenanceTypesById();

    // Los turnos avisan siempre, aunque los avisos automáticos estén apagados:
    // los programó el usuario a propósito.
    var nextId = _appointmentIdBase;
    for (final a in await db.getAppointments()) {
      final vehicle = vehicles[a.vehicleId];
      if (vehicle == null) continue;
      final when = tz.TZDateTime.from(a.remindAt, tz.local);
      if (!when.isAfter(now)) continue;
      final at = dateTimeFormat.format(a.scheduledAt);
      final items = a.maintenanceTypeIds
          .map((id) => types[id])
          .whereType<MaintenanceType>()
          .map((t) => t.name)
          .join(', ');
      final body = a.mechanic?.isNotEmpty == true
          ? l10n.appointmentNotifBodyShop(at, a.mechanic!, items)
          : l10n.appointmentNotifBody(at, items);
      await _plugin.zonedSchedule(
        nextId++,
        l10n.appointmentNotifTitle(vehicle.name),
        body,
        when,
        NotificationDetails(
          android:
              _maintenanceChannel(l10n, style: BigTextStyleInformation(body)),
        ),
        payload: '$_vehiclePayloadPrefix${vehicle.id}',
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      if (nextId >= _scheduledIdEnd) break;
    }

    if (!settings.maintenanceRemindersEnabled) return;

    final recService = RecommendationService();
    nextId = _maintenanceIdBase;
    for (final vehicle in vehicles.values) {
      final recs =
          await recService.getRecommendations(vehicle, settings: settings);
      for (final rec in recs) {
        // Un turno reemplaza al aviso automático de ese mantenimiento.
        if (rec.appointment != null) continue;
        if (rec.status == RecommendationStatus.overdue ||
            rec.status == RecommendationStatus.pendingRecord) {
          continue;
        }
        final due = rec.expectedDate;
        if (due == null) continue;

        final day = due.subtract(Duration(days: settings.reminderDaysBefore));
        final when = tz.TZDateTime(
            tz.local, day.year, day.month, day.day, settings.reminderHour);
        if (!when.isAfter(now)) continue;

        final byUsage = rec.estimatedKmDate != null &&
            (rec.intervalDays <= 0 ||
                rec.estimatedKmDate!.isBefore(rec.nextDueDate));
        final detail = byUsage
            ? l10n.maintenanceDueUsage(
                '${rec.nextDueKm}', dateFormat.format(due))
            : l10n.maintenanceDueDate(dateFormat.format(due));

        await _plugin.zonedSchedule(
          nextId++,
          '${rec.icon} ${rec.maintenanceTypeName} · ${vehicle.name}',
          detail,
          when,
          NotificationDetails(android: _maintenanceChannel(l10n)),
          payload: '$_vehiclePayloadPrefix${vehicle.id}',
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        if (nextId >= _appointmentIdBase) return;
      }
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
