import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vehiculos_app/l10n/app_localizations.dart';
import '../app_info.dart';
import '../main.dart';
import '../models/app_settings.dart';
import '../services/backup_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import '../theme/app_theme.dart';
import 'catalogs/mechanics_screen.dart';
import 'catalogs/vehicle_types_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _db = DatabaseService();
  final BackupService _backup = BackupService();
  AppSettings _settings = const AppSettings();
  bool _busy = false;
  bool _checkingUpdate = false;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _load();
    NotificationService().dataChanged.addListener(_load);
  }

  @override
  void dispose() {
    NotificationService().dataChanged.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final s = await _db.getSettings();
    if (mounted) setState(() => _settings = s);
  }

  Future<void> _update(AppSettings s) async {
    setState(() => _settings = s);
    await _db.saveSettings(s);
    await NotificationService().rescheduleMaintenanceReminders();
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _toggleReminders(bool enabled) async {
    if (enabled) {
      final granted = await NotificationService().requestPermissions();
      if (!granted && mounted) _snack(_l10n.notificationPermissionDenied);
    }
    await _update(_settings.copyWith(maintenanceRemindersEnabled: enabled));
  }

  Future<int?> _askNumber({
    required String title,
    required int current,
    required String suffix,
  }) async {
    final ctrl = TextEditingController(text: '$current');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(suffixText: suffix),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final n = int.tryParse(ctrl.text.trim());
              if (n != null && n >= 0) Navigator.pop(ctx, n);
            },
            child: Text(_l10n.save),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  Future<void> _exportBackup() async {
    setState(() => _busy = true);
    try {
      await _backup.exportAndShare(subject: _l10n.backupShareSubject);
    } catch (_) {
      if (mounted) _snack(_l10n.backupError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _backupErrorText(BackupError e) => switch (e) {
        BackupError.invalidFile => _l10n.backupInvalidFile,
        BackupError.notOurs => _l10n.backupNotOurs,
        BackupError.tooNew => _l10n.backupTooNew,
      };

  Future<void> _importBackup() async {
    Map<String, dynamic>? backup;
    try {
      backup = await _backup.pickBackup();
    } on BackupException catch (e) {
      if (mounted) _snack(_backupErrorText(e.error));
      return;
    }
    if (backup == null || !mounted) return;

    final l10n = _l10n;
    final vehicles = BackupService.countVehicles(backup);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.restoreConfirmTitle),
        content: Text(
            '${l10n.restoreConfirmVehicles(vehicles)} ${l10n.restoreConfirmWarning}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.replaceAll),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await _backup.restore(backup);
      if (mounted) _snack(l10n.restoreDone);
    } catch (_) {
      if (mounted) _snack(l10n.restoreFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkUpdate() async {
    final l10n = _l10n;
    final known = UpdateService().available.value;
    if (known != null) return showUpdateDialog(context, known);
    setState(() => _checkingUpdate = true);
    final info = await UpdateService().check();
    if (!mounted) return;
    setState(() => _checkingUpdate = false);
    if (info != null) return showUpdateDialog(context, info);
    // check() no distingue "al día" de "sin conexión": se pregunta aparte.
    final online = await _hasInternet();
    if (mounted) _snack(online ? l10n.upToDate : l10n.updateCheckFailed);
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('api.github.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _openInstagram() async {
    final ok = await launchUrl(Uri.parse(AppInfo.instagramUrl),
        mode: LaunchMode.externalApplication);
    if (!ok && mounted) _snack(_l10n.instagramOpenError);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final appState = VehiculosApp.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;
    final s = _settings;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            if (_busy) const LinearProgressIndicator(),
            _SectionHeader(title: l10n.catalogsSection),
            _card([
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(l10n.vehicleTypesAndMaintenance),
                subtitle: Text(l10n.vehicleTypesSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VehicleTypesScreen()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.build_outlined),
                title: Text(l10n.mechanicsTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MechanicsScreen()),
                ),
              ),
            ]),
            _SectionHeader(title: l10n.maintenanceRemindersSection),
            _card([
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: Text(l10n.remindBeforeService),
                subtitle: Text(l10n.remindBeforeServiceSub),
                value: s.maintenanceRemindersEnabled,
                onChanged: _toggleReminders,
              ),
              if (s.maintenanceRemindersEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: Text(l10n.advance),
                  trailing: Text(
                      s.reminderDaysBefore == 0
                          ? l10n.sameDay
                          : l10n.daysBefore(s.reminderDaysBefore),
                      style: const TextStyle(fontSize: 15)),
                  onTap: () async {
                    final n = await _askNumber(
                        title: l10n.howManyDaysBefore,
                        current: s.reminderDaysBefore,
                        suffix: l10n.unitDays);
                    if (n != null) {
                      await _update(_settings.copyWith(reminderDaysBefore: n));
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text(l10n.reminderTime),
                  trailing: Text(
                      TimeOfDay(hour: s.reminderHour, minute: 0)
                          .format(context),
                      style: const TextStyle(fontSize: 15)),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: s.reminderHour, minute: 0),
                    );
                    if (t != null) {
                      await _update(_settings.copyWith(reminderHour: t.hour));
                    }
                  },
                ),
              ],
            ]),
            _SectionHeader(title: l10n.dueSoonSection),
            _card([
              ListTile(
                leading: const Icon(Icons.speed_outlined),
                title: Text(l10n.lessThan),
                trailing: Text('${s.dueSoonKm} ${l10n.unitKm}',
                    style: const TextStyle(fontSize: 15)),
                onTap: () async {
                  final n = await _askNumber(
                      title: l10n.kmAdvance,
                      current: s.dueSoonKm,
                      suffix: l10n.unitKm);
                  if (n != null) {
                    await _update(_settings.copyWith(dueSoonKm: n));
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(l10n.orLessThan),
                trailing: Text('${s.dueSoonDays} ${l10n.unitDays}',
                    style: const TextStyle(fontSize: 15)),
                onTap: () async {
                  final n = await _askNumber(
                      title: l10n.daysAdvance,
                      current: s.dueSoonDays,
                      suffix: l10n.unitDays);
                  if (n != null) {
                    await _update(_settings.copyWith(dueSoonDays: n));
                  }
                },
              ),
            ]),
            _SectionHeader(title: l10n.dataSection),
            _card([
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: Text(l10n.exportBackup),
                subtitle: Text(l10n.exportBackupSub),
                onTap: _exportBackup,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: Text(l10n.restoreBackup),
                subtitle: Text(l10n.restoreBackupSub),
                onTap: _importBackup,
              ),
            ]),
            _SectionHeader(title: l10n.language),
            _card([
              RadioListTile<String>(
                value: 'es',
                groupValue: currentLocale,
                title: Text('🇦🇷  ${l10n.spanish}'),
                onChanged: (_) => appState?.setLocale(const Locale('es')),
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                value: 'en',
                groupValue: currentLocale,
                title: Text('🇺🇸  ${l10n.english}'),
                onChanged: (_) => appState?.setLocale(const Locale('en')),
              ),
            ]),
            _SectionHeader(title: l10n.aboutSection),
            _card([
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.appTitle),
                trailing: const Text('v${AppInfo.version}',
                    style: TextStyle(color: Colors.grey)),
              ),
              const Divider(height: 1),
              ValueListenableBuilder<UpdateInfo?>(
                valueListenable: UpdateService().available,
                builder: (context, update, _) => ListTile(
                  leading: Icon(Icons.system_update_outlined,
                      color: update == null ? null : AppTheme.primaryColor),
                  title: Text(l10n.checkUpdates),
                  subtitle: update == null
                      ? null
                      : Text(l10n.updateAvailableShort(update.version),
                          style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600)),
                  trailing: _checkingUpdate
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                  onTap: _checkingUpdate ? null : _checkUpdate,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(l10n.developedBy),
                subtitle: const Text(AppInfo.author),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Instagram'),
                subtitle: const Text(AppInfo.instagramHandle),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: _openInstagram,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.storage_outlined),
                title: Text(l10n.storage),
                subtitle: Text(l10n.storageText),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: children),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
            letterSpacing: 1.2,
          ),
        ),
      );
}
