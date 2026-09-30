import 'package:flutter/material.dart';
import 'package:vehiculos_app/l10n/app_localizations.dart';
import '../models/vehicle.dart';
import '../models/vehicle_type.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

String weekdayName(AppLocalizations l10n, int weekday) => switch (weekday) {
      DateTime.monday => l10n.weekday1,
      DateTime.tuesday => l10n.weekday2,
      DateTime.wednesday => l10n.weekday3,
      DateTime.thursday => l10n.weekday4,
      DateTime.friday => l10n.weekday5,
      DateTime.saturday => l10n.weekday6,
      _ => l10n.weekday7,
    };

class AddEditVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const AddEditVehicleScreen({super.key, this.vehicle});

  @override
  State<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends State<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _db = DatabaseService();

  late TextEditingController _nameCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _plateCtrl;
  late TextEditingController _kmCtrl;

  List<VehicleType> _types = [];
  int? _typeId;
  bool _saving = false;

  bool _kmReminderEnabled = false;
  int _kmReminderWeekday = DateTime.sunday;
  TimeOfDay _kmReminderTime = const TimeOfDay(hour: 20, minute: 0);

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _nameCtrl = TextEditingController(text: v?.name ?? '');
    _brandCtrl = TextEditingController(text: v?.brand ?? '');
    _modelCtrl = TextEditingController(text: v?.model ?? '');
    _yearCtrl = TextEditingController(
        text: v?.year.toString() ?? DateTime.now().year.toString());
    _plateCtrl = TextEditingController(text: v?.licensePlate ?? '');
    _kmCtrl = TextEditingController(text: v?.currentKm.toString() ?? '0');
    _loadTypes();
    if (v != null) {
      _typeId = v.vehicleTypeId;
      _kmReminderEnabled = v.kmReminderEnabled;
      _kmReminderWeekday = v.kmReminderWeekday;
      _kmReminderTime =
          TimeOfDay(hour: v.kmReminderHour, minute: v.kmReminderMinute);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _plateCtrl.dispose();
    _kmCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    final types = await _db.getVehicleTypes();
    if (!mounted) return;
    setState(() {
      _types = types;
      if (_typeId == null && types.isNotEmpty) _typeId = types.first.id;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_typeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.chooseVehicleType),
      ));
      return;
    }
    setState(() => _saving = true);

    final vehicle = Vehicle(
      id: widget.vehicle?.id,
      name: _nameCtrl.text.trim(),
      vehicleTypeId: _typeId!,
      brand: _brandCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      year: int.parse(_yearCtrl.text),
      licensePlate: _plateCtrl.text.trim(),
      currentKm: int.parse(_kmCtrl.text),
      createdAt: widget.vehicle?.createdAt,
      kmReminderEnabled: _kmReminderEnabled,
      kmReminderWeekday: _kmReminderWeekday,
      kmReminderHour: _kmReminderTime.hour,
      kmReminderMinute: _kmReminderTime.minute,
    );

    final Vehicle saved;
    if (_isEditing) {
      await _db.updateVehicle(vehicle);
      saved = vehicle;
    } else {
      saved = vehicle.copyWith(id: await _db.insertVehicle(vehicle));
    }
    await NotificationService().scheduleKmReminder(saved);

    if (mounted) Navigator.pop(context);
  }

  Future<void> _toggleKmReminder(bool enabled) async {
    if (enabled) {
      final granted = await NotificationService().requestPermissions();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.notificationPermissionDenied),
          ),
        );
      }
    }
    setState(() => _kmReminderEnabled = enabled);
  }

  Future<void> _pickKmReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _kmReminderTime,
    );
    if (picked != null) setState(() => _kmReminderTime = picked);
  }

  Widget _buildKmReminderCard() => Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.notifications_active_outlined),
              title: Text(AppLocalizations.of(context)!.kmReminderTitle),
              subtitle: Text(AppLocalizations.of(context)!.kmReminderSubtitle),
              value: _kmReminderEnabled,
              onChanged: _toggleKmReminder,
            ),
            if (_kmReminderEnabled) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.calendar_view_week_outlined),
                title: Text(AppLocalizations.of(context)!.dayLabel),
                trailing: DropdownButton<int>(
                  value: _kmReminderWeekday,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (var d = DateTime.monday; d <= DateTime.sunday; d++)
                      DropdownMenuItem(
                        value: d,
                        child:
                            Text(weekdayName(AppLocalizations.of(context)!, d)),
                      ),
                  ],
                  onChanged: (d) {
                    if (d != null) setState(() => _kmReminderWeekday = d);
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: Text(AppLocalizations.of(context)!.timeLabel),
                trailing: Text(
                  _kmReminderTime.format(context),
                  style: const TextStyle(fontSize: 16),
                ),
                onTap: _pickKmReminderTime,
              ),
            ],
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editVehicle : l10n.addVehicle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tipo
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.vehicleType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_types.isEmpty)
                      Text(
                        l10n.noVehicleTypes,
                        style: TextStyle(color: Colors.grey.shade600),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = (constraints.maxWidth - 12) / 2;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final type in _types)
                                SizedBox(
                                  width: width,
                                  child: _TypeButton(
                                    label: type.name,
                                    icon: type.icon,
                                    selected: _typeId == type.id,
                                    onTap: () =>
                                        setState(() => _typeId = type.id),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _nameCtrl,
              label: l10n.vehicleName,
              hint: l10n.hintVehicleName,
              icon: Icons.label_outline,
              required: true,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _brandCtrl,
              label: l10n.brand,
              hint: l10n.hintBrand,
              icon: Icons.business_outlined,
              required: true,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _modelCtrl,
              label: l10n.model,
              hint: l10n.hintModel,
              icon: Icons.directions_car_outlined,
              required: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _yearCtrl,
                    label: l10n.year,
                    hint: '2020',
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                    required: true,
                    validator: (v) {
                      final y = int.tryParse(v ?? '');
                      if (y == null ||
                          y < 1900 ||
                          y > DateTime.now().year + 1) {
                        return l10n.invalidYear;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _plateCtrl,
                    label: l10n.licensePlate,
                    hint: l10n.hintPlate,
                    icon: Icons.credit_card_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _kmCtrl,
              label: l10n.currentKm,
              hint: '45000',
              icon: Icons.speed_outlined,
              keyboardType: TextInputType.number,
              suffixText: 'km',
              required: true,
              validator: (v) {
                if (int.tryParse(v ?? '') == null) return l10n.invalidNumber;
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildKmReminderCard(),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? suffixText,
    bool required = false,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixText: suffixText,
        ),
        validator: validator ??
            (required
                ? (v) {
                    if (v == null || v.trim().isEmpty) {
                      return AppLocalizations.of(context)!.fieldRequired;
                    }
                    return null;
                  }
                : null),
      );
}

class _TypeButton extends StatelessWidget {
  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
