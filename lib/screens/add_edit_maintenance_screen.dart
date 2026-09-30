import 'package:flutter/material.dart';
import 'package:vehiculos_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/maintenance_type.dart';
import '../models/mechanic.dart';
import '../services/database_service.dart';

class AddEditMaintenanceScreen extends StatefulWidget {
  final Vehicle vehicle;
  final MaintenanceRecord? record;
  final String? preselectedTypeId;

  const AddEditMaintenanceScreen({
    super.key,
    required this.vehicle,
    this.record,
    this.preselectedTypeId,
  });

  @override
  State<AddEditMaintenanceScreen> createState() =>
      _AddEditMaintenanceScreenState();
}

class _AddEditMaintenanceScreenState extends State<AddEditMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _db = DatabaseService();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  String? _selectedTypeId;
  late TextEditingController _kmCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _mechanicCtrl;
  late TextEditingController _productsCtrl;
  late TextEditingController _notesCtrl;
  late DateTime _selectedDate;

  bool _saving = false;
  bool get _isEditing => widget.record != null;

  List<MaintenanceType> _types = [];
  List<Mechanic> _mechanics = [];
  String _vehicleIcon = '🚘';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _selectedTypeId = r?.maintenanceTypeId ?? widget.preselectedTypeId;
    _selectedDate = r?.date ?? DateTime.now();
    _kmCtrl = TextEditingController(
        text: r?.kmAtService.toString() ?? widget.vehicle.currentKm.toString());
    _costCtrl = TextEditingController(
        text: r?.cost != null ? r!.cost!.toStringAsFixed(0) : '');
    _mechanicCtrl = TextEditingController(text: r?.mechanic ?? '');
    _productsCtrl = TextEditingController(text: r?.productsUsed ?? '');
    _notesCtrl = TextEditingController(text: r?.notes ?? '');
    _loadCatalogs();
  }

  Future<void> _loadCatalogs() async {
    final active = await _db.getMaintenanceTypes(
      vehicleTypeId: widget.vehicle.vehicleTypeId,
      onlyActive: true,
    );
    // Al editar, el tipo del registro se ofrece aunque ya esté desactivado.
    final all = await _db.getMaintenanceTypesById();
    final own =
        widget.record == null ? null : all[widget.record!.maintenanceTypeId];
    final types = [
      ...active,
      if (own != null && !active.any((t) => t.id == own.id)) own,
    ];
    final mechanics = await _db.getMechanics();
    final vehicleTypes = await _db.getVehicleTypes();
    final lastMechanic = widget.record == null
        ? await _db.getLastMechanicForVehicle(widget.vehicle.id!)
        : null;
    if (!mounted) return;
    setState(() {
      _types = types;
      _mechanics = mechanics;
      _vehicleIcon = vehicleTypes
              .where((t) => t.id == widget.vehicle.vehicleTypeId)
              .map((t) => t.icon)
              .firstOrNull ??
          '🚘';
      if (_selectedTypeId == null ||
          !types.any((t) => t.id == _selectedTypeId)) {
        _selectedTypeId = types.isEmpty ? null : types.first.id;
      }
      if (lastMechanic != null && _mechanicCtrl.text.isEmpty) {
        _mechanicCtrl.text = lastMechanic;
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _kmCtrl.dispose();
    _costCtrl.dispose();
    _mechanicCtrl.dispose();
    _productsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypeId == null) return;
    setState(() => _saving = true);

    final record = MaintenanceRecord(
      id: widget.record?.id,
      vehicleId: widget.vehicle.id!,
      maintenanceTypeId: _selectedTypeId!,
      date: _selectedDate,
      kmAtService: int.parse(_kmCtrl.text),
      cost: _costCtrl.text.isNotEmpty ? double.tryParse(_costCtrl.text) : null,
      mechanic: _mechanicCtrl.text.trim().isNotEmpty
          ? _mechanicCtrl.text.trim()
          : null,
      productsUsed: _productsCtrl.text.trim().isNotEmpty
          ? _productsCtrl.text.trim()
          : null,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
    );

    if (_isEditing) {
      await _db.updateMaintenanceRecord(record);
    } else {
      await _db.insertMaintenanceRecord(record);
    }
    if (record.mechanic != null) await _db.ensureMechanic(record.mechanic!);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? l10n.editMaintenance : l10n.addMaintenance),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_types.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.addMaintenance)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              l10n.noActiveMaintenance,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final selectedType = _types.firstWhere((t) => t.id == _selectedTypeId,
        orElse: () => _types.first);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editMaintenance : l10n.addMaintenance),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Vehicle badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(_vehicleIcon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    widget.vehicle.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '· ${widget.vehicle.currentKm} km',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tipo de mantenimiento
            DropdownButtonFormField<String>(
              value: _selectedTypeId,
              decoration: InputDecoration(
                labelText: l10n.maintenanceType,
                prefixIcon: Text(
                  selectedType.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              items: _types
                  .map(
                    (t) => DropdownMenuItem(
                      value: t.id,
                      child: Row(
                        children: [
                          Text(t.icon),
                          const SizedBox(width: 8),
                          Text(t.name),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedTypeId = val);
              },
            ),
            const SizedBox(height: 12),

            // Fecha
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: l10n.date,
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  controller: TextEditingController(
                    text: _dateFormat.format(_selectedDate),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Km
            TextFormField(
              controller: _kmCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.kmAtService,
                prefixIcon: const Icon(Icons.speed_outlined),
                suffixText: 'km',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.fieldRequired;
                if (int.tryParse(v) == null) return l10n.invalidNumber;
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Costo
            TextFormField(
              controller: _costCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.cost,
                prefixIcon: const Icon(Icons.attach_money_outlined),
                prefixText: '\$ ',
                hintText: '0',
              ),
            ),
            const SizedBox(height: 12),

            // Taller
            TextFormField(
              controller: _mechanicCtrl,
              decoration: InputDecoration(
                labelText: l10n.mechanic,
                prefixIcon: const Icon(Icons.build_outlined),
                hintText: l10n.mechanicHint,
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

            // Productos
            TextFormField(
              controller: _productsCtrl,
              decoration: InputDecoration(
                labelText: l10n.productsUsed,
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                hintText: l10n.productsHint,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Notas
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: l10n.notes,
                prefixIcon: const Icon(Icons.notes_outlined),
                hintText: l10n.notesHint,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
