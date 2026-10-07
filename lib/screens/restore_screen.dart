import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vehiculos_app/l10n/app_localizations.dart';

import '../services/backup_match.dart';
import '../services/backup_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Qué traer de un backup ya leído: algunos vehículos (sumándolos a los datos
/// actuales) o todo (reemplazándolos).
class RestoreScreen extends StatefulWidget {
  final Map<String, dynamic> backup;

  const RestoreScreen({super.key, required this.backup});

  @override
  State<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends State<RestoreScreen> {
  final BackupService _backup = BackupService();

  late final List<Map<String, dynamic>> _vehicles;
  late final Map<int, String> _typeIcons;
  final Set<int> _selected = {};
  Set<int> _replacing = {};
  bool _history = true;
  bool _mechanics = true;
  bool _busy = false;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    final tables = BackupService.tablesOf(widget.backup);
    _vehicles = [...?tables['vehicles']]
      ..sort((a, b) => (a['name'] as String)
          .toLowerCase()
          .compareTo((b['name'] as String).toLowerCase()));
    _typeIcons = {
      for (final t in tables['vehicle_types'] ?? const [])
        t['id'] as int: t['icon'] as String,
    };
    _selected.addAll(_vehicles.map((v) => v['id'] as int));
    _findReplacements();
  }

  Future<void> _findReplacements() async {
    final local = (await DatabaseService().getVehicles())
        .map((v) => v.toMap())
        .toList();
    if (!mounted) return;
    setState(() {
      _replacing = {
        for (final v in _vehicles)
          if (BackupMatch.find(v, local) != null) v['id'] as int,
      };
    });
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = _l10n.restoreFailed;
    setState(() => _busy = true);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importSelected() async {
    final l10n = _l10n;
    final replaced = _selected.intersection(_replacing).length;
    if (replaced > 0) {
      final ok = await _confirm(
        l10n.restoreReplaceSome(replaced),
        l10n.importAction,
      );
      if (!ok) return;
    }
    await _run(
      () => _backup.importSelected(
        widget.backup,
        vehicleIds: _selected,
        history: _history,
        mechanics: _mechanics,
      ),
      l10n.importDone,
    );
  }

  Future<void> _replaceAll() async {
    final l10n = _l10n;
    final ok = await _confirm(
      '${l10n.restoreConfirmVehicles(_vehicles.length)} '
      '${l10n.restoreConfirmWarning}',
      l10n.replaceAll,
      danger: true,
    );
    if (ok) await _run(() => _backup.restore(widget.backup), l10n.restoreDone);
  }

  Future<bool> _confirm(String text, String action,
      {bool danger = false}) async {
    final l10n = _l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.restoreConfirmTitle),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: danger
                ? TextButton.styleFrom(foregroundColor: AppTheme.dangerColor)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final exported = DateTime.tryParse(widget.backup['exported_at'] as String? ?? '');
    final secondary = TextStyle(fontSize: 12, color: Colors.grey.shade600);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.restoreChooseTitle)),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (_busy) const LinearProgressIndicator(),
            if (exported != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  l10n.restoreFrom(
                      DateFormat('dd/MM/yyyy HH:mm').format(exported.toLocal())),
                  style: secondary,
                ),
              ),
            _Header(l10n.vehicles),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final v in _vehicles)
                    CheckboxListTile(
                      value: _selected.contains(v['id']),
                      onChanged: (on) => setState(() => on == true
                          ? _selected.add(v['id'] as int)
                          : _selected.remove(v['id'])),
                      secondary: Text(
                        _typeIcons[v['vehicle_type_id']] ?? '🚘',
                        style: const TextStyle(fontSize: 26),
                      ),
                      title: Text(v['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [
                              '${v['brand']} ${v['model']} ${v['year']}',
                              if ((v['license_plate'] as String? ?? '')
                                  .isNotEmpty)
                                v['license_plate'],
                            ].join(' · '),
                            style: secondary,
                          ),
                          if (_replacing.contains(v['id']))
                            Text(
                              l10n.restoreAlreadyHave,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.warningColor),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _Header(l10n.restoreAlsoSection),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.history),
                    title: Text(l10n.restoreHistory),
                    subtitle: Text(l10n.restoreHistorySub),
                    value: _history,
                    onChanged: (v) => setState(() => _history = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.store_outlined),
                    title: Text(l10n.restoreMechanics),
                    subtitle: Text(l10n.restoreMechanicsSub),
                    value: _mechanics,
                    onChanged: (v) => setState(() => _mechanics = v),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: ElevatedButton(
                onPressed: _selected.isEmpty ? null : _importSelected,
                child: Text(l10n.restoreImportSelected(_selected.length)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                style:
                    TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
                onPressed: _replaceAll,
                child: Text(l10n.restoreReplaceAll),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;

  const _Header(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppTheme.primaryColor,
          ),
        ),
      );
}
