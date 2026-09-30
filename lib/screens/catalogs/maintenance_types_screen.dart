import 'package:flutter/material.dart';
import 'package:vehiculos_app/l10n/app_localizations.dart';

import '../../models/maintenance_type.dart';
import '../../models/vehicle_type.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/emoji_picker_field.dart';

class MaintenanceTypesScreen extends StatefulWidget {
  final VehicleType vehicleType;

  const MaintenanceTypesScreen({super.key, required this.vehicleType});

  @override
  State<MaintenanceTypesScreen> createState() => _MaintenanceTypesScreenState();
}

class _MaintenanceTypesScreenState extends State<MaintenanceTypesScreen> {
  final DatabaseService _db = DatabaseService();
  List<MaintenanceType> _types = [];
  bool _loading = true;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final types =
        await _db.getMaintenanceTypes(vehicleTypeId: widget.vehicleType.id);
    if (!mounted) return;
    setState(() {
      _types = types;
      _loading = false;
    });
  }

  void _changed() {
    NotificationService().dataChanged.value++;
    _load();
  }

  Future<void> _edit([MaintenanceType? type]) async {
    final result = await Navigator.push<MaintenanceType>(
      context,
      MaterialPageRoute(
        builder: (_) => MaintenanceTypeEditScreen(
          type: type,
          vehicleTypeId: widget.vehicleType.id!,
          nextSortOrder: _types.isEmpty ? 0 : _types.last.sortOrder + 1,
        ),
      ),
    );
    if (result == null) return;
    await _db.saveMaintenanceType(result);
    _changed();
  }

  Future<void> _delete(MaintenanceType type) async {
    final l10n = _l10n;
    final records = await _db.countRecordsOfMaintenanceType(type.id);
    if (!mounted) return;
    if (records > 0) {
      final deactivate = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.hasHistoryTitle),
          content: Text(l10n.hasHistoryBody(records, type.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            TextButton(
              style:
                  TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.deleteAnyway),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.deactivate),
            ),
          ],
        ),
      );
      if (deactivate == null) return;
      if (deactivate) {
        await _db.saveMaintenanceType(type.copyWith(active: false));
        _changed();
        return;
      }
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.deleteQuestion(type.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              style:
                  TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.delete),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await _db.deleteMaintenanceType(type.id);
    _changed();
  }

  Future<void> _copyFromOtherType() async {
    final others = (await _db.getVehicleTypes())
        .where((t) => t.id != widget.vehicleType.id)
        .toList();
    if (!mounted || others.isEmpty) return;
    final source = await showDialog<VehicleType>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(_l10n.copyMaintenanceFrom),
        children: [
          for (final t in others)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t),
              child: Text('${t.icon}  ${t.name}',
                  style: const TextStyle(fontSize: 16)),
            ),
        ],
      ),
    );
    if (source == null) return;
    final toCopy = await _db.getMaintenanceTypes(vehicleTypeId: source.id);
    var order = _types.isEmpty ? 0 : _types.last.sortOrder + 1;
    for (final m in toCopy) {
      await _db.saveMaintenanceType(MaintenanceType(
        id: MaintenanceType.newId(),
        vehicleTypeId: widget.vehicleType.id!,
        name: m.name,
        description: m.description,
        icon: m.icon,
        intervalKm: m.intervalKm,
        intervalDays: m.intervalDays,
        priority: m.priority,
        active: m.active,
        sortOrder: order++,
      ));
      // Los ids se generan por microsegundo: sin esta pausa dos seguidos
      // podrían coincidir.
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    _changed();
  }

  String _intervalText(MaintenanceType t) {
    final l10n = _l10n;
    final parts = [
      if (t.intervalKm > 0) l10n.everyKm('${t.intervalKm}'),
      if (t.intervalDays > 0) l10n.everyDays('${t.intervalDays}'),
    ];
    if (parts.isEmpty) return l10n.noInterval;
    return l10n.whicheverFirst(parts.join(l10n.orSeparator));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicleType.icon} ${widget.vehicleType.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: l10n.copyFromOtherType,
            onPressed: _copyFromOtherType,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _types.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.noMaintenanceForType,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.content_copy),
                          label: Text(l10n.copyFromOtherType),
                          onPressed: _copyFromOtherType,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  children: [
                    for (final type in _types)
                      Card(
                        child: ListTile(
                          leading: Opacity(
                            opacity: type.active ? 1 : 0.4,
                            child: Text(type.icon,
                                style: const TextStyle(fontSize: 26)),
                          ),
                          title: Text(
                            type.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: type.active ? null : Colors.grey,
                            ),
                          ),
                          subtitle: Text(_intervalText(type)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: type.active,
                                onChanged: (v) async {
                                  await _db.saveMaintenanceType(
                                      type.copyWith(active: v));
                                  _changed();
                                },
                              ),
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') _edit(type);
                                  if (v == 'delete') _delete(type);
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                      value: 'edit', child: Text(l10n.edit)),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(l10n.delete,
                                        style:
                                            const TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => _edit(type),
                        ),
                      ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: Text(l10n.newItem),
      ),
    );
  }
}

class MaintenanceTypeEditScreen extends StatefulWidget {
  final MaintenanceType? type;
  final int vehicleTypeId;
  final int nextSortOrder;

  const MaintenanceTypeEditScreen({
    super.key,
    this.type,
    required this.vehicleTypeId,
    required this.nextSortOrder,
  });

  @override
  State<MaintenanceTypeEditScreen> createState() =>
      _MaintenanceTypeEditScreenState();
}

class _MaintenanceTypeEditScreenState extends State<MaintenanceTypeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.type?.name ?? '');
  late final _descCtrl =
      TextEditingController(text: widget.type?.description ?? '');
  late final _kmCtrl = TextEditingController(
      text: (widget.type?.intervalKm ?? 0) > 0
          ? '${widget.type!.intervalKm}'
          : '');
  late final _daysCtrl = TextEditingController(
      text: (widget.type?.intervalDays ?? 0) > 0
          ? '${widget.type!.intervalDays}'
          : '');
  late String _icon = widget.type?.icon ?? '🔧';
  late String _priority = widget.type?.priority ?? 'medium';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _kmCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  String? _validateInterval(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    return n == null || n < 0
        ? AppLocalizations.of(context)!.invalidNumber
        : null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.type ??
        MaintenanceType(
          id: MaintenanceType.newId(),
          vehicleTypeId: widget.vehicleTypeId,
          name: '',
          sortOrder: widget.nextSortOrder,
        );
    Navigator.pop(
      context,
      base.copyWith(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        icon: _icon,
        intervalKm: int.tryParse(_kmCtrl.text.trim()) ?? 0,
        intervalDays: int.tryParse(_daysCtrl.text.trim()) ?? 0,
        priority: _priority,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == null ? l10n.newMaintenance : l10n.edit),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.nameLabel,
                prefixIcon: const Icon(Icons.label_outline),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.descriptionOptional,
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 16),
            EmojiPickerField(
              value: _icon,
              suggestions: EmojiPickerField.maintenanceSuggestions,
              onChanged: (e) => _icon = e,
            ),
            const SizedBox(height: 20),
            Text(l10n.intervalLabel,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              l10n.intervalHelp,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _kmCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.everyLabel,
                      suffixText: l10n.unitKm,
                    ),
                    validator: _validateInterval,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _daysCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.everyLabel,
                      suffixText: l10n.unitDays,
                    ),
                    validator: _validateInterval,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(l10n.priorityLabel,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'high', label: Text(l10n.high)),
                ButtonSegment(value: 'medium', label: Text(l10n.medium)),
                ButtonSegment(value: 'low', label: Text(l10n.low)),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}
