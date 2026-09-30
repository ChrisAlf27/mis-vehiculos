import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vehiculos_app/l10n/app_localizations.dart';

import '../../models/mechanic.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';

class MechanicsScreen extends StatefulWidget {
  const MechanicsScreen({super.key});

  @override
  State<MechanicsScreen> createState() => _MechanicsScreenState();
}

class _MechanicsScreenState extends State<MechanicsScreen> {
  final DatabaseService _db = DatabaseService();
  List<Mechanic> _mechanics = [];
  bool _loading = true;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _db.getMechanics();
    if (!mounted) return;
    setState(() {
      _mechanics = list;
      _loading = false;
    });
  }

  Future<void> _edit([Mechanic? mechanic]) async {
    final result = await showDialog<Mechanic>(
      context: context,
      builder: (_) => _MechanicDialog(mechanic: mechanic),
    );
    if (result == null) return;
    await _db.saveMechanic(result);
    _load();
  }

  Future<void> _delete(Mechanic mechanic) async {
    final l10n = _l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteQuestion(mechanic.name)),
        content: Text(l10n.deleteMechanicBody),
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
    await _db.deleteMechanic(mechanic.id!);
    _load();
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s'), ''));
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_l10n.callError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mechanicsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _mechanics.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l10n.mechanicsEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  children: [
                    for (final m in _mechanics)
                      Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.build_outlined),
                          ),
                          title: Text(m.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (m.address?.isNotEmpty == true)
                                Text(m.address!),
                              if (m.notes?.isNotEmpty == true)
                                Text(m.notes!,
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12)),
                            ],
                          ),
                          isThreeLine: m.address?.isNotEmpty == true &&
                              m.notes?.isNotEmpty == true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (m.phone?.isNotEmpty == true)
                                IconButton(
                                  icon: const Icon(Icons.phone_outlined),
                                  color: AppTheme.primaryColor,
                                  tooltip: m.phone,
                                  onPressed: () => _call(m.phone!),
                                ),
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') _edit(m);
                                  if (v == 'delete') _delete(m);
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
                          onTap: () => _edit(m),
                        ),
                      ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: Text(l10n.newMechanic),
      ),
    );
  }
}

class _MechanicDialog extends StatefulWidget {
  final Mechanic? mechanic;

  const _MechanicDialog({this.mechanic});

  @override
  State<_MechanicDialog> createState() => _MechanicDialogState();
}

class _MechanicDialogState extends State<_MechanicDialog> {
  late final _name = TextEditingController(text: widget.mechanic?.name ?? '');
  late final _phone = TextEditingController(text: widget.mechanic?.phone ?? '');
  late final _address =
      TextEditingController(text: widget.mechanic?.address ?? '');
  late final _notes = TextEditingController(text: widget.mechanic?.notes ?? '');

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _opt(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title:
          Text(widget.mechanic == null ? l10n.newMechanic : l10n.editMechanic),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: widget.mechanic == null,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.nameLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.phone),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.address),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.notesLabel),
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
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              Mechanic(
                id: widget.mechanic?.id,
                name: name,
                phone: _opt(_phone),
                address: _opt(_address),
                notes: _opt(_notes),
              ),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
