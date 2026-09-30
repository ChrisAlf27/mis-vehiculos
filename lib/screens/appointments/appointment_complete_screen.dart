import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vehiculos_app/l10n/app_localizations.dart';

import '../../models/appointment.dart';
import '../../models/km_reading.dart';
import '../../models/maintenance_record.dart';
import '../../models/maintenance_type.dart';
import '../../models/vehicle.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';

/// Después del turno: un registro por cada mantenimiento tildado, con la
/// fecha, el km y el taller en común, y el turno se cierra.
class AppointmentCompleteScreen extends StatefulWidget {
  final Vehicle vehicle;
  final Appointment appointment;
  final Map<String, MaintenanceType> types;

  const AppointmentCompleteScreen({
    super.key,
    required this.vehicle,
    required this.appointment,
    required this.types,
  });

  @override
  State<AppointmentCompleteScreen> createState() =>
      _AppointmentCompleteScreenState();
}

class _AppointmentCompleteScreenState extends State<AppointmentCompleteScreen> {
  final DatabaseService _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  late DateTime _date;
  late final TextEditingController _kmCtrl;
  late final TextEditingController _mechanicCtrl;
  late final TextEditingController _notesCtrl;
  late final List<String> _typeIds;
  late final Set<String> _done;
  late final Map<String, TextEditingController> _costCtrls;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.appointment;
    final now = DateTime.now();
    // Si se registra antes del día del turno, se hizo hoy.
    final day = a.scheduledAt.isAfter(now) ? now : a.scheduledAt;
    _date = DateTime(day.year, day.month, day.day);
    _kmCtrl = TextEditingController(text: '${widget.vehicle.currentKm}');
    _mechanicCtrl = TextEditingController(text: a.mechanic ?? '');
    _notesCtrl = TextEditingController(text: a.notes ?? '');
    _typeIds = [
      for (final id in a.maintenanceTypeIds)
        if (widget.types.containsKey(id)) id,
    ];
    _done = {..._typeIds};
    _costCtrls = {for (final id in _typeIds) id: TextEditingController()};
  }

  @override
  void dispose() {
    _kmCtrl.dispose();
    _mechanicCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _costCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_done.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.appointmentSelectAtLeastOne)));
      return;
    }
    setState(() => _saving = true);

    final km = parseKm(_kmCtrl.text)!;
    final mechanic = _mechanicCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    for (final id in _typeIds.where(_done.contains)) {
      final cost = double.tryParse(
          _costCtrls[id]!.text.trim().replaceAll('.', '').replaceAll(',', '.'));
      await _db.insertMaintenanceRecord(MaintenanceRecord(
        vehicleId: widget.vehicle.id!,
        maintenanceTypeId: id,
        date: _date,
        kmAtService: km,
        cost: cost,
        mechanic: mechanic.isEmpty ? null : mechanic,
        notes: notes.isEmpty ? null : notes,
      ));
    }
    if (mechanic.isNotEmpty) await _db.ensureMechanic(mechanic);
    // Lo que se destildó no se hizo: el turno se cierra igual.
    await _db.deleteAppointment(widget.appointment.id!);
    NotificationService().dataChanged.value++;
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.completeAppointmentTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              l10n.completeAppointmentHelp,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: AbsorbPointer(
                child: TextFormField(
                  key: ValueKey(_date),
                  initialValue: DateFormat('dd/MM/yyyy').format(_date),
                  decoration: InputDecoration(
                    labelText: l10n.date,
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _kmCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.kmAtService,
                prefixIcon: const Icon(Icons.speed_outlined),
                suffixText: l10n.unitKm,
              ),
              validator: (v) => parseKm(v) == null ? l10n.invalidNumber : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mechanicCtrl,
              decoration: InputDecoration(
                labelText: l10n.mechanic,
                prefixIcon: const Icon(Icons.build_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.notesLabel,
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 16),
            for (final id in _typeIds)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        contentPadding: const EdgeInsets.only(left: 8),
                        value: _done.contains(id),
                        secondary: Text(widget.types[id]!.icon,
                            style: const TextStyle(fontSize: 22)),
                        title: Text(widget.types[id]!.name),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _done.add(id);
                          } else {
                            _done.remove(id);
                          }
                        }),
                      ),
                      if (_done.contains(id))
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: TextFormField(
                            controller: _costCtrls[id],
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: l10n.costOptional,
                              prefixText: '\$ ',
                              isDense: true,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
