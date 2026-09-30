import 'package:flutter/material.dart';
import 'package:vehiculos_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../models/interval_override.dart';
import 'appointments/appointment_complete_screen.dart';
import 'appointments/appointment_edit_screen.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/maintenance_type.dart';
import '../models/km_reading.dart';
import '../services/database_service.dart';
import '../services/recommendation_service.dart';
import '../services/export_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'add_edit_maintenance_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;

  /// Abre el diálogo de km apenas carga (se llega desde la notificación).
  final bool askKmOnOpen;

  const VehicleDetailScreen({
    super.key,
    required this.vehicle,
    this.askKmOnOpen = false,
  });

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final DatabaseService _db = DatabaseService();
  final RecommendationService _rec = RecommendationService();
  final ExportService _export = ExportService();

  late TabController _tabController;
  late Vehicle _vehicle;

  List<MaintenanceRecord> _records = [];
  List<MaintenanceRecommendation> _recommendations = [];
  List<Appointment> _appointments = [];
  Map<String, MaintenanceType> _types = {};
  Map<String, IntervalOverride> _overrides = {};
  String _vehicleIcon = '🚘';
  double _totalCost = 0;
  UsageEstimate? _usage;
  bool _loading = true;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  List<MaintenanceType> get _hiddenTypes => _overrides.values
      .where((o) => o.hidden && _types.containsKey(o.maintenanceTypeId))
      .map((o) => _types[o.maintenanceTypeId]!)
      .toList();

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    NotificationService().dataChanged.addListener(_load);
    _load().then((_) {
      if (widget.askKmOnOpen && mounted) _showUpdateKmDialog();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService().dataChanged.removeListener(_load);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final fresh = await _db.getVehicle(_vehicle.id!);
    if (fresh != null) _vehicle = fresh;
    final records = await _db.getRecordsForVehicle(_vehicle.id!);
    final usage = await _rec.getUsage(_vehicle);
    final recs = await _rec.getRecommendations(_vehicle, usage: usage);
    final cost = await _db.getTotalCostForVehicle(_vehicle.id!);
    final types = await _db.getMaintenanceTypesById();
    final overrides = await _db.getIntervalOverrides(_vehicle.id!);
    final vehicleTypes = await _db.getVehicleTypes();
    final appointments = await _db.getAppointments(vehicleId: _vehicle.id);
    NotificationService().rescheduleMaintenanceReminders();
    if (mounted) {
      setState(() {
        _records = records;
        _recommendations = recs;
        _totalCost = cost;
        _usage = usage;
        _types = types;
        _overrides = overrides;
        _appointments = appointments;
        _vehicleIcon = vehicleTypes
                .where((t) => t.id == _vehicle.vehicleTypeId)
                .map((t) => t.icon)
                .firstOrNull ??
            '🚘';
        _loading = false;
      });
    }
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(_vehicle.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenu,
            itemBuilder: (_) => [
              _menuItem('update_km', Icons.speed, l10n.updateKm),
              _menuItem('schedule', Icons.event_outlined, l10n.actionSchedule),
              _menuItem('csv', Icons.table_chart_outlined, l10n.exportCSV),
              _menuItem('pdf', Icons.picture_as_pdf_outlined, l10n.exportPDF),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppTheme.accentColor,
          tabs: [
            Tab(text: l10n.recommendations),
            Tab(text: l10n.maintenanceHistory),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildVehicleHeader(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRecommendationsTab(),
                      _buildHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openMaintenanceForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String text) =>
      PopupMenuItem(
        value: value,
        child: Row(children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(text),
        ]),
      );

  Future<void> _openMaintenanceForm({
    String? typeId,
    MaintenanceRecord? record,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditMaintenanceScreen(
          vehicle: _vehicle,
          record: record,
          preselectedTypeId: typeId,
        ),
      ),
    );
    _load();
  }

  Widget _buildVehicleHeader() => Container(
        color: AppTheme.primaryColor,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            Text(_vehicleIcon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_vehicle.brand} ${_vehicle.model} ${_vehicle.year}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _headerChip(
                          '${_formatKm(_vehicle.currentKm)} km', Icons.speed),
                      if (_usage != null)
                        _headerChip(
                            _l10n.kmPerWeek('${_usage!.kmPerWeek.round()}'),
                            Icons.trending_up),
                      _headerChip(
                          _l10n.recordsCount(_records.length), Icons.history),
                      if (_totalCost > 0)
                        _headerChip(_currencyFormat.format(_totalCost),
                            Icons.attach_money),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _headerChip(String label, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      );

  Widget _buildRecommendationsTab() {
    final l10n = _l10n;
    final hidden = _hiddenTypes;
    final showUsageHint = _usage == null && _recommendations.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      children: [
        if (showUsageHint)
          Card(
            color: AppTheme.primaryColor.withOpacity(0.06),
            child: ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: Text(l10n.usageHintTitle),
              subtitle: Text(_vehicle.kmReminderEnabled
                  ? l10n.usageHintWithReminder
                  : l10n.usageHintWithoutReminder),
            ),
          ),
        if (_appointments.isNotEmpty) ...[
          _SectionTitle(text: l10n.appointmentsSection),
          for (final a in _appointments)
            _AppointmentCard(
              appointment: a,
              types: _types,
              onEdit: () => _openAppointment(a),
              onComplete: () => _completeAppointment(a),
            ),
          _SectionTitle(text: l10n.recommendations),
        ],
        if (_recommendations.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              l10n.noRecommendations,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        for (final rec in _recommendations)
          _RecommendationCard(
            rec: rec,
            onAddRecord: () =>
                _openMaintenanceForm(typeId: rec.maintenanceTypeId),
            onCustomize: () => _showOverrideDialog(rec.maintenanceTypeId),
            onSchedule: () => rec.appointment != null
                ? _openAppointment(rec.appointment)
                : _openAppointment(null, preselected: {rec.maintenanceTypeId}),
          ),
        if (hidden.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.visibility_off_outlined),
              label: Text(l10n.hiddenCount(hidden.length)),
              onPressed: () => _showHiddenDialog(hidden),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    if (_records.isEmpty) {
      return Center(
        child: Text(
          _l10n.noHistory,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _records.length,
      itemBuilder: (ctx, i) => _HistoryCard(
        record: _records[i],
        type: _types[_records[i].maintenanceTypeId],
        dateFormat: _dateFormat,
        currencyFormat: _currencyFormat,
        onEdit: () => _openMaintenanceForm(record: _records[i]),
        onDelete: () => _confirmDeleteRecord(_records[i]),
      ),
    );
  }

  Future<void> _handleMenu(String val) async {
    switch (val) {
      case 'update_km':
        await _showUpdateKmDialog();
        break;
      case 'schedule':
        await _openAppointment(null, preselected: {
          for (final r in _recommendations)
            if (r.appointment == null && r.status != RecommendationStatus.ok)
              r.maintenanceTypeId,
        });
        break;
      case 'csv':
      case 'pdf':
        try {
          final path = val == 'csv'
              ? await _export.exportVehicleToCSV(_vehicle)
              : await _export.exportVehicleToPDF(_vehicle);
          await _export.shareFile(path);
        } catch (e) {
          if (mounted) _snack(_l10n.exportError);
        }
        break;
    }
  }

  Future<void> _showUpdateKmDialog() async {
    final l10n = _l10n;
    final controller =
        TextEditingController(text: _vehicle.currentKm.toString());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.updateKm),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration:
              InputDecoration(labelText: l10n.currentKm, suffixText: 'km'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newKm = parseKm(controller.text);
      if (newKm == null) {
        if (mounted) _snack(l10n.kmInvalid);
        return;
      }
      final result = await _db.registerCurrentKm(_vehicle.id!, newKm);
      if (result == KmUpdateResult.lowerThanCurrent && mounted) {
        _snack(l10n.kmLowerThanCurrent('$newKm', '${_vehicle.currentKm}'));
      }
      _load();
    }
  }

  /// Mantenimientos que se pueden poner en un turno: los activos del tipo de
  /// vehículo que no están ocultos, más los que ya estén en el turno.
  List<MaintenanceType> _schedulableTypes(Appointment? appointment) {
    final inAppointment = {...?appointment?.maintenanceTypeIds};
    return _types.values
        .where((t) =>
            inAppointment.contains(t.id) ||
            (t.vehicleTypeId == _vehicle.vehicleTypeId &&
                t.active &&
                _overrides[t.id]?.hidden != true))
        .toList()
      ..sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
      });
  }

  Future<void> _openAppointment(
    Appointment? appointment, {
    Set<String> preselected = const {},
  }) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentEditScreen(
          vehicle: _vehicle,
          appointment: appointment,
          types: _schedulableTypes(appointment),
          preselected: preselected,
        ),
      ),
    );
    _load();
  }

  Future<void> _completeAppointment(Appointment appointment) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentCompleteScreen(
          vehicle: _vehicle,
          appointment: appointment,
          types: _types,
        ),
      ),
    );
    _load();
  }

  /// Intervalo propio de este vehículo para un mantenimiento, u ocultarlo.
  Future<void> _showOverrideDialog(String typeId) async {
    final l10n = _l10n;
    final type = _types[typeId];
    if (type == null) return;
    final current = _overrides[typeId];
    final kmCtrl =
        TextEditingController(text: current?.intervalKm?.toString() ?? '');
    final daysCtrl =
        TextEditingController(text: current?.intervalDays?.toString() ?? '');

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${type.icon} ${type.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.overrideHelp(_vehicle.name),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: kmCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.everyKmLabel,
                  hintText: type.intervalKm > 0
                      ? l10n.fromType('${type.intervalKm}')
                      : l10n.fromTypeNoKm,
                  suffixText: l10n.unitKm,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: daysCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.everyDaysLabel,
                  hintText: type.intervalDays > 0
                      ? l10n.fromType('${type.intervalDays}')
                      : l10n.fromTypeNoDays,
                  suffixText: l10n.unitDays,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.zeroDisables,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'hide'),
            child: Text(l10n.hide),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (action == 'hide') {
      await _db.saveIntervalOverride(IntervalOverride(
        vehicleId: _vehicle.id!,
        maintenanceTypeId: typeId,
        intervalKm: current?.intervalKm,
        intervalDays: current?.intervalDays,
        hidden: true,
      ));
    } else if (action == 'save') {
      await _db.saveIntervalOverride(IntervalOverride(
        vehicleId: _vehicle.id!,
        maintenanceTypeId: typeId,
        intervalKm: int.tryParse(kmCtrl.text.trim()),
        intervalDays: int.tryParse(daysCtrl.text.trim()),
      ));
    } else {
      return;
    }
    _load();
  }

  Future<void> _showHiddenDialog(List<MaintenanceType> hidden) async {
    final l10n = _l10n;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.hiddenTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final type in hidden)
                ListTile(
                  leading:
                      Text(type.icon, style: const TextStyle(fontSize: 22)),
                  title: Text(type.name),
                  trailing: TextButton(
                    child: Text(l10n.show),
                    onPressed: () async {
                      final o = _overrides[type.id]!;
                      await _db.saveIntervalOverride(IntervalOverride(
                        vehicleId: o.vehicleId,
                        maintenanceTypeId: o.maintenanceTypeId,
                        intervalKm: o.intervalKm,
                        intervalDays: o.intervalDays,
                      ));
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
    _load();
  }

  Future<void> _confirmDeleteRecord(MaintenanceRecord record) async {
    final l10n = _l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteMaintenance),
        content: Text(l10n.confirmDeleteMaintenance),
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
    if (confirmed == true) {
      await _db.deleteMaintenanceRecord(record.id!);
      _load();
    }
  }

  String _formatKm(int km) {
    if (km >= 1000) {
      return '${(km / 1000).toStringAsFixed(1)}k';
    }
    return km.toString();
  }
}

// ─── Turnos ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
            letterSpacing: 1.2,
          ),
        ),
      );
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final Map<String, MaintenanceType> types;
  final VoidCallback onEdit;
  final VoidCallback onComplete;

  const _AppointmentCard({
    required this.appointment,
    required this.types,
    required this.onEdit,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final past = appointment.isPast;
    final color = past ? AppTheme.dangerColor : AppTheme.primaryColor;
    final when = DateFormat('dd/MM/yyyy HH:mm').format(appointment.scheduledAt);
    final items = appointment.maintenanceTypeIds
        .map((id) => types[id])
        .whereType<MaintenanceType>()
        .toList();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.mechanic?.isNotEmpty == true
                          ? '$when · ${appointment.mechanic}'
                          : when,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: color),
                    ),
                  ),
                  Icon(Icons.edit_outlined,
                      size: 18, color: Colors.grey.shade500),
                ],
              ),
              if (past)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(l10n.appointmentPast,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.dangerColor)),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in items)
                    Chip(
                      avatar: Text(t.icon),
                      label: Text(t.name, style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
              if (appointment.notes?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('📝 ${appointment.notes}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.task_alt),
                  label: Text(l10n.completeAppointment),
                  onPressed: onComplete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Recommendation Card ──────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final MaintenanceRecommendation rec;
  final VoidCallback onAddRecord;
  final VoidCallback onCustomize;
  final VoidCallback onSchedule;

  const _RecommendationCard({
    required this.rec,
    required this.onAddRecord,
    required this.onCustomize,
    required this.onSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = AppTheme.statusColor(rec.status);
    final df = DateFormat('dd/MM/yyyy');
    final dtf = DateFormat('dd/MM/yyyy HH:mm');
    final secondary = TextStyle(fontSize: 12, color: Colors.grey.shade600);
    final appointment = rec.appointment;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(rec.icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rec.maintenanceTypeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      _StatusChip(color: color, status: rec.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (appointment != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (appointment.isPast
                                ? AppTheme.dangerColor
                                : AppTheme.primaryColor)
                            .withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.mechanic?.isNotEmpty == true
                                ? l10n.appointmentLineShop(
                                    dtf.format(appointment.scheduledAt),
                                    appointment.mechanic!)
                                : l10n.appointmentLine(
                                    dtf.format(appointment.scheduledAt)),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: appointment.isPast
                                  ? AppTheme.dangerColor
                                  : AppTheme.primaryColor,
                            ),
                          ),
                          if (appointment.isPast)
                            Text(l10n.appointmentPast,
                                style: const TextStyle(
                                    fontSize: 11, color: AppTheme.dangerColor)),
                        ],
                      ),
                    ),
                  if (rec.pendingRecord)
                    Text(l10n.pendingRecordText, style: secondary)
                  else ...[
                    Text(
                      rec.lastDate != null
                          ? l10n.lastService(
                              df.format(rec.lastDate!), '${rec.lastKm}')
                          : l10n.firstServiceNoRecord,
                      style: secondary.copyWith(
                        fontStyle:
                            rec.lastDate == null ? FontStyle.italic : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (rec.intervalKm > 0)
                      Text(_kmLabel(l10n),
                          style: TextStyle(fontSize: 12, color: color)),
                    if (rec.intervalDays > 0)
                      Text(_dateLabel(l10n, df),
                          style: TextStyle(fontSize: 12, color: color)),
                    if (rec.estimatedKmDate != null)
                      Text(
                        _estimatedLabel(l10n, df),
                        style: TextStyle(
                          fontSize: 12,
                          color: rec.isDueSoonByUsage
                              ? color
                              : Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                  if (rec.hasOverride)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        l10n.ownInterval,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.primaryColor),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppTheme.primaryColor,
                  onPressed: onAddRecord,
                  tooltip: l10n.actionRegister,
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                  onSelected: (v) {
                    if (v == 'register') onAddRecord();
                    if (v == 'schedule') onSchedule();
                    if (v == 'customize') onCustomize();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'register',
                      child: _menuRow(
                          Icons.add_circle_outline, l10n.actionRegister),
                    ),
                    PopupMenuItem(
                      value: 'schedule',
                      child: _menuRow(
                          Icons.event_outlined,
                          appointment == null
                              ? l10n.actionSchedule
                              : l10n.actionEditAppointment),
                    ),
                    PopupMenuItem(
                      value: 'customize',
                      child: _menuRow(Icons.tune, l10n.actionCustomize),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _menuRow(IconData icon, String text) => Row(children: [
        Icon(icon),
        const SizedBox(width: 8),
        Text(text),
      ]);

  String _kmLabel(AppLocalizations l10n) {
    final remaining = rec.kmRemaining;
    if (remaining < 0) return l10n.kmOverdue('${remaining.abs()}');
    return l10n.kmRemainingNext('$remaining', '${rec.nextDueKm}');
  }

  String _dateLabel(AppLocalizations l10n, DateFormat df) {
    final days = rec.daysRemaining;
    if (days < 0) return l10n.daysOverdue('${days.abs()}');
    return l10n.daysRemainingDate('$days', df.format(rec.nextDueDate));
  }

  String _estimatedLabel(AppLocalizations l10n, DateFormat df) {
    final days = rec.estimatedDaysRemaining!;
    if (days <= 0) return l10n.usageAlreadyNear('${rec.nextDueKm}');
    if (days == 1) return l10n.usageTomorrow('${rec.nextDueKm}');
    return l10n.usageInDays(
        '${rec.nextDueKm}', '$days', df.format(rec.estimatedKmDate!));
  }
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final RecommendationStatus status;

  const _StatusChip({required this.color, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (status) {
      RecommendationStatus.overdue => l10n.statusOverdue,
      RecommendationStatus.dueSoon => l10n.statusDueSoon,
      RecommendationStatus.pendingRecord => l10n.statusPending,
      RecommendationStatus.ok => l10n.statusOk,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ─── History Card ─────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final MaintenanceRecord record;

  /// Null si el mantenimiento se eliminó del catálogo.
  final MaintenanceType? type;
  final DateFormat dateFormat;
  final NumberFormat currencyFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.record,
    required this.type,
    required this.dateFormat,
    required this.currencyFormat,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(type?.icon ?? '🔧', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    type?.name ?? l10n.unknownMaintenance,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        const Icon(Icons.edit_outlined),
                        const SizedBox(width: 8),
                        Text(l10n.edit),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(l10n.delete,
                            style: const TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _chip(Icons.calendar_today, dateFormat.format(record.date),
                    Colors.blue),
                _chip(Icons.speed, '${record.kmAtService} km', Colors.indigo),
                if (record.cost != null && record.cost! > 0)
                  _chip(Icons.attach_money, currencyFormat.format(record.cost!),
                      Colors.green),
                if (record.mechanic?.isNotEmpty == true)
                  _chip(Icons.build_outlined, record.mechanic!, Colors.orange),
              ],
            ),
            if (record.productsUsed?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(
                '📦 ${record.productsUsed}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
            if (record.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                '📝 ${record.notes}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      );
}
