import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vehiculos_app/l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/vehicle_detail_screen.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/update_service.dart';
import 'widgets/update_dialog.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService();
  final notifications = NotificationService();
  ({int vehicleId, bool askKm})? launchTarget;
  String? launchUpdateUrl;
  // Una falla de notificaciones no puede impedir que la app abra: sin este
  // try, cualquier error acá deja la pantalla en negro.
  try {
    await notifications.initialize();
    await notifications.syncKmReminders(await db.getVehicles());
    notifications.onVehicleNotificationOpened = _openVehicle;
    notifications.onUpdateNotificationOpened = openUpdateDownload;
    launchTarget = await notifications.targetFromLaunch();
    launchUpdateUrl = await notifications.updateUrlFromLaunch();
    // Sin await: no hace falta demorar el arranque por esto.
    notifications.rescheduleMaintenanceReminders().catchError(
        (Object e) => debugPrint('No se pudieron programar los avisos: $e'));
  } catch (e) {
    debugPrint('No se pudieron inicializar las notificaciones: $e');
  }
  final settings = await db.getSettings();

  runApp(VehiculosApp(initialLocale: settings.locale));

  final target = launchTarget;
  if (target != null) {
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openVehicle(target.vehicleId, target.askKm));
  }
  final updateUrl = launchUpdateUrl;
  if (updateUrl != null) {
    openUpdateDownload(updateUrl);
  } else {
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }
}

/// Avisa una sola vez por versión: notificación y diálogo. Después queda
/// visible en Ajustes → Acerca de.
Future<void> _checkForUpdate() async {
  final updates = UpdateService();
  final info = await updates.check();
  if (info == null || !await updates.markNotified(info.version)) return;
  try {
    await NotificationService()
        .showUpdateAvailable(info.version, info.downloadUrl);
  } catch (e) {
    debugPrint('No se pudo mostrar el aviso de versión nueva: $e');
  }
  final context = navigatorKey.currentContext;
  if (context != null && context.mounted) await showUpdateDialog(context, info);
}

Future<void> _openVehicle(int vehicleId, bool askKm) async {
  final vehicle = await DatabaseService().getVehicle(vehicleId);
  final navigator = navigatorKey.currentState;
  if (vehicle == null || navigator == null) return;
  navigator.push(MaterialPageRoute(
    builder: (_) => VehicleDetailScreen(vehicle: vehicle, askKmOnOpen: askKm),
  ));
}

class VehiculosApp extends StatefulWidget {
  final String? initialLocale;

  const VehiculosApp({super.key, this.initialLocale});

  static _VehiculosAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_VehiculosAppState>();

  @override
  State<VehiculosApp> createState() => _VehiculosAppState();
}

class _VehiculosAppState extends State<VehiculosApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    final code =
        widget.initialLocale ?? PlatformDispatcher.instance.locale.languageCode;
    _locale = Locale(code == 'en' ? 'en' : 'es');
  }

  Future<void> setLocale(Locale locale) async {
    setState(() => _locale = locale);
    final db = DatabaseService();
    await db.saveSettings(
        (await db.getSettings()).copyWith(locale: locale.languageCode));
    final notifications = NotificationService();
    await notifications.syncKmReminders(await db.getVehicles());
    await notifications.rescheduleMaintenanceReminders();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      home: const HomeScreen(),
    );
  }
}
