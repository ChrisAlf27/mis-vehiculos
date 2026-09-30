import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vehiculos_app/l10n/app_localizations.dart';

import '../../models/appointment.dart';
import '../../models/maintenance_type.dart';
import '../../models/mechanic.dart';
import '../../models/vehicle.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

/// Crea o edita un turno del vehículo. Devuelve true si se guardó o borró.
class AppointmentEditScreen extends StatefulWidget {
  final Vehicle vehicle;
  final Appointment? appointment;

  /// Los mantenimientos que se ofrecen para tildar.
  final List<MaintenanceType> types;

  /// Tildados de entrada en un turno nuevo.
  final Set<String> preselected;

  const AppointmentEditScreen({
    super.key,
    required this.vehicle,
    required this.types,
    this.appointment,
    this.preselected = const {},
  });

  @override
  State<AppointmentEditScreen> createState() => _AppointmentEditScreenState();
}

class _AppointmentEditScreenState extends State<AppointmentEditScreen> {
  final DatabaseService _db = DatabaseService();

  late DateTime _date;
  late TimeOfDay _time;
  late int _remind;
  late final Set<String> _selected;
  late final TextEditingController _mechanicCtrl;
  late final TextEditingController _notesCtrl;
  List<Mechanic> _mechanics = [];
  bool _saving = false;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    final a = widget.appointment;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final base = a?.scheduledAt ??
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
    _date = DateTime(base.year, base.month, base.day);
    _time = TimeOfDay(hour: base.hour, minute: base.minute);
    _remind = a?.remindMinutesBefore ?? 1440;
    _selected = {...(a?.maintenanceTypeIds ?? widget.preselected)};
    _mechanicCtrl = TextEditingController(text: a?.mechanic ?? '');
    _notesCtrl = TextEditingController(text: a?.notes ?? '');
    _loadMechanics();
  }

  Future<void> _loadMechanics() async {
    final mechanics = await _db.getMechanics();
    final last = widget.appointment == null
        ? await _db.getLastMechanicForVehicle(widget.vehicle.id!)
        : null;
    if (!mounted) return;
    setState(() {
      _mechanics = mechanics;
      if (last != null && _mechanicCtrl.text.isEmpty) _mechanicCtrl.text = last;
    });
  }

  @override
  void dispose() {
    _mechanicCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  DateTime get _scheduledAt =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _save() async {
    final l10n = _l10n;
    if (_selected.isEmpty) return _snack(l10n.appointmentSelectAtLeastOne);
    if (!_scheduledAt.isAfter(DateTime.now())) {
      return _snack(l10n.appointmentInPast);
    }
    setState(() => _saving = true);

    final granted = await NotificationService().requestPermissions();
    if (!granted && mounted) _snack(l10n.notificationPermissionDenied);

    final mechanic = _mechanicCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    await _db.saveAppointment(Appointment(
      id: widget.appointment?.id,
      vehicleId: widget.vehicle.id!,
      scheduledAt: _scheduledAt,
      mechanic: mechanic.isEmpty ? null : mechanic,
      notes: notes.isEmpty ? null : notes,
      remindMinutesBefore: _remind,
      // En el orden del catálogo, no en el orden en que se tildaron.
      maintenanceTypeIds: [
        for (final t in widget.types)
          if (_selected.contains(t.id)) t.id,
      ],
    ));
    if (mechanic.isNotEmpty) await _db.ensureMechanic(mechanic);
    NotificationService().dataChanged.value++;
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final l10n = _l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAppointmentQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _db.deleteAppointment(widget.appointment!.id!);
    NotificationService().dataChanged.value++;
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final remindLabels = {
      0: l10n.remindAtTime,
      60: l10n.remindHourBefore,
      1440: l10n.remindDayBefore,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appointment == null
            ? l10n.newAppointment
            : l10n.actionEditAppointment),
        actions: [
          if (widget.appointment != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.appointmentDelete,
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            widget.vehicle.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.appointmentHelp,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: Text(l10n.date),
                  trailing: Text(DateFormat('dd/MM/yyyy').format(_date),
                      style: const TextStyle(fontSize: 15)),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date.isBefore(now) ? now : _date,
                      firstDate: DateTime(now.year, now.month, now.day),
                      lastDate: now.add(const Duration(days: 730)),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text(l10n.timeLabel),
                  trailing: Text(_time.format(context),
                      style: const TextStyle(fontSize: 15)),
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: _time);
                    if (picked != null) setState(() => _time = picked);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(l10n.remindMe),
                  trailing: DropdownButton<int>(
                    value: _remind,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final m in Appointment.remindOptions)
                        DropdownMenuItem(
                            value: m, child: Text(remindLabels[m]!)),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _remind = v);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _mechanicCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.mechanic,
              prefixIcon: const Icon(Icons.build_outlined),
              suffixIcon: _mechanics.isEmpty
                  ? null
                  : PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      tooltip: l10n.pickFromList,
                      onSelected: (name) =>
                          setState(() => _mechanicCtrl.text = name),
                      itemBuilder: (_) => [
                        for (final m in _mechanics)
                          PopupMenuItem(value: m.name, child: Text(m.name)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.notesLabel,
              prefixIcon: const Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.appointmentWhatToDo,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          if (widget.appointment == null && widget.preselected.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                l10n.appointmentSuggested,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final t in widget.types)
                  CheckboxListTile(
                    value: _selected.contains(t.id),
                    secondary:
                        Text(t.icon, style: const TextStyle(fontSize: 22)),
                    title: Text(t.name),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selected.add(t.id);
                      } else {
                        _selected.remove(t.id);
                      }
                    }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
