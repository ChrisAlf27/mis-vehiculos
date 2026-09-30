import 'package:flutter/material.dart';
import 'package:vehiculos_app/l10n/app_localizations.dart';

import '../../models/vehicle_type.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/emoji_picker_field.dart';
import 'maintenance_types_screen.dart';

class VehicleTypesScreen extends StatefulWidget {
  const VehicleTypesScreen({super.key});

  @override
  State<VehicleTypesScreen> createState() => _VehicleTypesScreenState();
}

class _VehicleTypesScreenState extends State<VehicleTypesScreen> {
  final DatabaseService _db = DatabaseService();
  List<VehicleType> _types = [];
  Map<int, int> _maintenanceCount = {};
  bool _loading = true;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final types = await _db.getVehicleTypes();
    final all = await _db.getMaintenanceTypes(onlyActive: true);
    final counts = <int, int>{};
    for (final m in all) {
      counts[m.vehicleTypeId] = (counts[m.vehicleTypeId] ?? 0) + 1;
    }
    if (!mounted) return;
    setState(() {
      _types = types;
      _maintenanceCount = counts;
      _loading = false;
    });
  }

  Future<void> _edit([VehicleType? type]) async {
    final result = await showDialog<VehicleType>(
      context: context,
      builder: (_) => _VehicleTypeDialog(type: type),
    );
    if (result == null) return;
    if (result.id == null) {
      await _db.insertVehicleType(result);
    } else {
      await _db.updateVehicleType(result);
    }
    NotificationService().dataChanged.value++;
    _load();
  }

  Future<void> _delete(VehicleType type) async {
    final l10n = _l10n;
    final inUse = await _db.countVehiclesOfType(type.id!);
    if (!mounted) return;
    if (inUse > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.cannotDelete),
          content: Text(l10n.typeInUse(inUse, type.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.understood),
            ),
          ],
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteQuestion(type.name)),
        content: Text(l10n.deleteTypeAlsoMaintenance),
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
    await _db.deleteVehicleType(type.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleTypesTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    l10n.vehicleTypesHelp,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
                for (final type in _types)
                  Card(
                    child: ListTile(
                      leading:
                          Text(type.icon, style: const TextStyle(fontSize: 28)),
                      title: Text(type.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(l10n.activeMaintenanceCount(
                          _maintenanceCount[type.id] ?? 0)),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _edit(type);
                          if (v == 'delete') _delete(type);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(l10n.delete,
                                style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MaintenanceTypesScreen(vehicleType: type),
                          ),
                        );
                        _load();
                      },
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: Text(l10n.newType),
      ),
    );
  }
}

class _VehicleTypeDialog extends StatefulWidget {
  final VehicleType? type;

  const _VehicleTypeDialog({this.type});

  @override
  State<_VehicleTypeDialog> createState() => _VehicleTypeDialogState();
}

class _VehicleTypeDialogState extends State<_VehicleTypeDialog> {
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.type?.name ?? '');
  late String _icon = widget.type?.icon ?? '🚗';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.type == null ? l10n.newType : l10n.editType),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              autofocus: widget.type == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.nameLabel,
                hintText: l10n.typeNameHint,
              ),
            ),
            const SizedBox(height: 16),
            EmojiPickerField(
              value: _icon,
              suggestions: EmojiPickerField.vehicleSuggestions,
              onChanged: (e) => _icon = e,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              (widget.type ?? VehicleType(name: name, icon: _icon))
                  .copyWith(name: name, icon: _icon),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
