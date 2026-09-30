import 'dart:ui' show Locale, PlatformDispatcher;

import '../services/database_service.dart';
import 'app_localizations.dart';

/// El idioma elegido en la app, o el del teléfono. Es para el código que no
/// tiene un BuildContext: las notificaciones (que pueden correr con la app
/// cerrada) y los archivos exportados.
Future<AppLocalizations> currentL10n() async {
  final settings = await DatabaseService().getSettings();
  final code =
      settings.locale ?? PlatformDispatcher.instance.locale.languageCode;
  return lookupAppLocalizations(Locale(code == 'en' ? 'en' : 'es'));
}
