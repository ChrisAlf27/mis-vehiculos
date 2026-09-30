/// Configuración general. Se guarda como clave/valor en la tabla `settings`.
class AppSettings {
  /// Un servicio pasa a PRÓXIMO cuando faltan menos de estos km…
  final int dueSoonKm;

  /// …o menos de estos días.
  final int dueSoonDays;

  final bool maintenanceRemindersEnabled;
  final int reminderDaysBefore;
  final int reminderHour;

  /// 'es' | 'en'. Null = el idioma del teléfono.
  final String? locale;

  const AppSettings({
    this.dueSoonKm = 500,
    this.dueSoonDays = 14,
    this.maintenanceRemindersEnabled = false,
    this.reminderDaysBefore = 7,
    this.reminderHour = 9,
    this.locale,
  });

  Map<String, String> toKeyValues() => {
        'due_soon_km': '$dueSoonKm',
        'due_soon_days': '$dueSoonDays',
        'maintenance_reminders_enabled':
            maintenanceRemindersEnabled ? '1' : '0',
        'reminder_days_before': '$reminderDaysBefore',
        'reminder_hour': '$reminderHour',
        'locale': locale ?? '',
      };

  factory AppSettings.fromKeyValues(Map<String, String> kv) {
    const d = AppSettings();
    int intOf(String key, int fallback) =>
        int.tryParse(kv[key] ?? '') ?? fallback;
    final locale = kv['locale'];
    return AppSettings(
      dueSoonKm: intOf('due_soon_km', d.dueSoonKm),
      dueSoonDays: intOf('due_soon_days', d.dueSoonDays),
      maintenanceRemindersEnabled: kv['maintenance_reminders_enabled'] == '1',
      reminderDaysBefore: intOf('reminder_days_before', d.reminderDaysBefore),
      reminderHour: intOf('reminder_hour', d.reminderHour),
      locale: locale == null || locale.isEmpty ? null : locale,
    );
  }

  AppSettings copyWith({
    int? dueSoonKm,
    int? dueSoonDays,
    bool? maintenanceRemindersEnabled,
    int? reminderDaysBefore,
    int? reminderHour,
    String? locale,
    bool clearLocale = false,
  }) =>
      AppSettings(
        dueSoonKm: dueSoonKm ?? this.dueSoonKm,
        dueSoonDays: dueSoonDays ?? this.dueSoonDays,
        maintenanceRemindersEnabled:
            maintenanceRemindersEnabled ?? this.maintenanceRemindersEnabled,
        reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
        reminderHour: reminderHour ?? this.reminderHour,
        locale: clearLocale ? null : (locale ?? this.locale),
      );
}
