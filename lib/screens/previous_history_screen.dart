import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vehiculos_app/l10n/app_localizations.dart';

import '../models/km_reading.dart';
import '../models/maintenance_baseline.dart';
import '../models/maintenance_type.dart';
import '../models/vehicle.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'appointments/appointment_edit_screen.dart';

/// "Ponelo al día": para un vehículo usado, qué se sabe de cada mantenimiento
/// que todavía no tiene registros. Devuelve true si se guardó.
class PreviousHistoryScreen extends StatefulWidget {
  final Vehicle vehicle;

  const PreviousHistoryScreen({super.key, required this.vehicle});

  @override
  State<PreviousHistoryScreen> createState() => _PreviousHistoryScreenState();
}

class _Answer {
  BaselineMode mode;
  final TextEditingController km;
  DateTime? date;

  _Answer({required this.mode, int? km, this.date})
      : km = TextEditingController(text: km?.toString() ?? '');
}

class _PreviousHistoryScreenState extends State<PreviousHistoryScreen> {
  final DatabaseService _db = DatabaseService();
  final DateFormat _df = DateFormat('dd/MM/yyyy');

  List<MaintenanceType> _types = [];
  final Map<String, _Answer> _answers = {};
  bool _loading = true;
  bool _saving = false;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final a in _answers.values) {
      a.km.dispose();
    }
    super.dispose();
  }

  /// Los mantenimientos que se recomiendan para este vehículo y todavía no
  /// tienen registros: los que ya tienen, se calculan desde ahí.
  Future<void> _load() async {
    final v = widget.vehicle;
    final types = await _db.getMaintenanceTypes(
        vehicleTypeId: v.vehicleTypeId, onlyActive: true);
    final overrides = await _db.getIntervalOverrides(v.id!);
    final records = await _db.getLastRecordsByType(v.id!);
    final baselines = await _db.getBaselines(v.id!);

    final pending = types.where((t) {
      final o = overrides[t.id];
      if (o?.hidden == true || records.containsKey(t.id)) return false;
      return (o?.intervalKm ?? t.intervalKm) > 0 ||
          (o?.intervalDays ?? t.intervalDays) > 0;
    }).toList();

    if (!mounted) return;
    setState(() {
      _types = pending;
      for (final t in pending) {
        final b = baselines[t.id];
        _answers[t.id] = _Answer(
          mode: b?.mode ?? MaintenanceBaseline.defaultModeFor(t.priority),
          km: b?.km,
          date: b?.date,
        );
      }
      _loading = false;
    });
  }

  Future<void> _pickDate(_Answer answer) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: answer.date ?? widget.vehicle.acquiredDate,
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) setState(() => answer.date = picked);
  }

  Future<void> _save() async {
    final l10n = _l10n;
    final baselines = <MaintenanceBaseline>[];
    for (final t in _types) {
      final a = _answers[t.id]!;
      var mode = a.mode;
      int? km;
      DateTime? date;
      if (mode == BaselineMode.known) {
        final text = a.km.text.trim();
        km = text.isEmpty ? null : parseKm(text);
        if (text.isNotEmpty &&
            (km == null || km > widget.vehicle.currentKm)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${t.icon} ${t.name}: ${l10n.kmInvalid}'),
          ));
          return;
        }
        date = a.date;
        // Sin ningún dato es lo mismo que asumirlo hecho al comprarlo.
        if (km == null && date == null) mode = BaselineMode.assumed;
      }
      baselines.add(MaintenanceBaseline(
        vehicleId: widget.vehicle.id!,
        maintenanceTypeId: t.id,
        mode: mode,
        km: km,
        date: date,
      ));
    }

    setState(() => _saving = true);
    await _db.saveBaselines(baselines);
    NotificationService().dataChanged.value++;

    final toCheck = {
      for (final b in baselines)
        if (b.mode == BaselineMode.check) b.maintenanceTypeId,
    };
    if (toCheck.isNotEmpty && mounted) await _offerAppointment(toCheck);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _offerAppointment(Set<String> toCheck) async {
    final l10n = _l10n;
    final book = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.onboardingScheduleTitle),
        content: Text(l10n.onboardingScheduleBody(toCheck.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.notNow),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.scheduleNow),
          ),
        ],
      ),
    );
    if (book != true || !mounted) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentEditScreen(
          vehicle: widget.vehicle,
          types: _types,
          preselected: toCheck,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  l10n.onboardingIntro,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                for (final t in _types) _buildItem(t, _answers[t.id]!),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _saving ? null : () => Navigator.pop(context, false),
                        child: Text(l10n.onboardingLater),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: Text(l10n.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildItem(MaintenanceType type, _Answer answer) {
    final l10n = _l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(type.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    type.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<BaselineMode>(
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
              ),
              segments: [
                ButtonSegment(
                    value: BaselineMode.known, label: Text(l10n.modeKnown)),
                ButtonSegment(
                    value: BaselineMode.check, label: Text(l10n.modeCheck)),
                ButtonSegment(
                    value: BaselineMode.assumed,
                    label: Text(l10n.modeAssumed)),
              ],
              selected: {answer.mode},
              onSelectionChanged: (s) =>
                  setState(() => answer.mode = s.first),
            ),
            if (answer.mode == BaselineMode.known) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: answer.km,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.knownKmLabel,
                        suffixText: l10n.unitKm,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(answer),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.knownDateLabel,
                          isDense: true,
                          suffixIcon: answer.date == null
                              ? const Icon(Icons.event_outlined, size: 18)
                              : IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () =>
                                      setState(() => answer.date = null),
                                ),
                        ),
                        child: Text(
                          answer.date == null
                              ? l10n.noDate
                              : _df.format(answer.date!),
                          style: answer.date == null
                              ? TextStyle(color: Colors.grey.shade600)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.knownHint,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
            if (answer.mode == BaselineMode.check)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.needsCheckText,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.checkColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
