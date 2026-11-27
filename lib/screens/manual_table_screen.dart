import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:vehiculos_app/l10n/app_localizations.dart';
import '../data/manual_schedules.dart';
import '../theme/app_theme.dart';

/// La tabla de mantenimiento del manual de fábrica: qué toca en cada service,
/// qué comprar, y la tabla completa como en el manual.
class ManualTableScreen extends StatefulWidget {
  final ManualSchedule schedule;
  final int currentKm;

  /// Km del último registro de cada tipo de mantenimiento del vehículo.
  final Map<String, int> lastKmByType;

  /// Desde qué km conoce la app al vehículo: antes no se marcan pendientes.
  final int? knownSinceKm;

  const ManualTableScreen({
    super.key,
    required this.schedule,
    required this.currentKm,
    this.lastKmByType = const {},
    this.knownSinceKm,
  });

  @override
  State<ManualTableScreen> createState() => _ManualTableScreenState();
}

class _ManualTableScreenState extends State<ManualTableScreen> {
  late final int _next = widget.schedule.nextServiceIndex(widget.currentKm);
  late int _selected = _next;
  late final List<ManualPending> _pending = _s.pendingBefore(
    _next,
    lastKm: widget.lastKmByType,
    sinceKm: widget.knownSinceKm ?? widget.currentKm,
  );
  final _chipsController = ScrollController();
  final _nextChipKey = GlobalKey();

  ManualSchedule get _s => widget.schedule;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealNext());
  }

  @override
  void dispose() {
    _chipsController.dispose();
    super.dispose();
  }

  /// Centra el chip del próximo service en la fila (sin mover la pantalla).
  void _revealNext() {
    final box = _nextChipKey.currentContext?.findRenderObject();
    if (box == null || !_chipsController.hasClients) return;
    final target = RenderAbstractViewport.of(box).getOffsetToReveal(box, 0.5);
    final position = _chipsController.position;
    _chipsController.jumpTo(target.offset
        .clamp(position.minScrollExtent, position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final numbers = NumberFormat.decimalPattern(locale);
    String km(int value) => numbers.format(value);
    String chip(int index) =>
        l10n.serviceChip('${index + 1}', km(_s.serviceKm(index)));

    final chips = [
      for (var i = 0; i <= _s.tableServices || i <= _next + 3; i++) i,
    ];
    final tasks = _s.tasksAt(_selected);
    final showPending = _selected == _next && _pending.isNotEmpty;
    final due = _s.partsAt(_selected);
    final pendingParts = [
      if (showPending)
        for (final p in _s.partsFor(_pending))
          if (!due.contains(p)) p,
    ];
    final parts = [...due, ...pendingParts];
    final replacePending = [
      for (final p in _pending)
        if (p.isReplace) p
    ];
    final checksPending = [
      for (final p in _pending)
        if (!p.isReplace) p
    ];
    final diff = _s.serviceKm(_selected) - widget.currentKm;
    final note = _s.getNote(locale);

    return Scaffold(
      appBar: AppBar(title: Text(_s.name)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.isNotEmpty)
                  Text(note, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 2),
                Text(_s.source,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),

          // Selector de service.
          SizedBox(
            height: 52,
            // Todos los chips se arman de una vez para poder ubicar el próximo.
            child: SingleChildScrollView(
              controller: _chipsController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  for (final i in chips)
                    Padding(
                      key: i == _next ? _nextChipKey : null,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(chip(i)),
                        selected: i == _selected,
                        avatar: i == _next
                            ? const Icon(Icons.flag_outlined, size: 16)
                            : null,
                        onSelected: (_) => setState(() => _selected = i),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // El service elegido.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selected == _next
                              ? '${l10n.nextService} · ${chip(_selected)}'
                              : chip(_selected),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    diff >= 0 ? l10n.kmToGo(km(diff)) : l10n.kmPast(km(-diff)),
                    style: TextStyle(
                      fontSize: 13,
                      color: diff >= 0
                          ? AppTheme.primaryColor
                          : Colors.grey.shade600,
                    ),
                  ),
                  if (showPending)
                    _PendingBox(
                      title: l10n.pendingTitle,
                      hint: l10n.pendingHint,
                      children: [
                        for (final p in replacePending)
                          _TaskRow(
                            title: p.item.name(locale),
                            actions: [
                              ManualAction.replace.label(locale),
                              l10n.pendingSince(chip(p.service)),
                            ],
                            highlight: true,
                          ),
                        if (checksPending.isNotEmpty)
                          _TaskRow(
                            title: l10n.pendingChecks(checksPending.length),
                            actions: [
                              for (final p in checksPending)
                                p.item.name(locale),
                            ],
                          ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  for (final (item, actions) in tasks)
                    _TaskRow(
                      title: item.name(locale),
                      actions: [for (final a in actions) a.label(locale)],
                      highlight: actions.contains(ManualAction.replace),
                      note: item.note(locale),
                    ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.shopping_cart_outlined,
                          size: 20, color: AppTheme.accentColor),
                      const SizedBox(width: 8),
                      Text(l10n.toBuy,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (parts.isEmpty)
                    Text(l10n.nothingToBuy,
                        style: TextStyle(color: Colors.grey.shade600))
                  else
                    for (final p in parts)
                      _PartRow(
                        part: p,
                        locale: locale,
                        tag: pendingParts.contains(p) ? l10n.pendingTag : null,
                      ),
                ],
              ),
            ),
          ),

          if (_s.betweenServices.isNotEmpty)
            _Section(
              icon: Icons.repeat,
              title: l10n.betweenServices,
              children: [
                for (final (item, task) in _s.betweenServices)
                  _TaskRow(
                    title: item.name(locale),
                    actions: [
                      '${task.action.label(locale)} '
                          '${l10n.everyKm(km(task.every!))}',
                    ],
                  ),
              ],
            ),

          if (_s.byTime.isNotEmpty)
            _Section(
              icon: Icons.schedule,
              title: l10n.byTime,
              children: [
                for (final (item, task) in _s.byTime)
                  _TaskRow(
                    title: item.name(locale),
                    actions: [
                      '${task.action.label(locale)} '
                          '${l10n.everyYears((task.days! / 365).round())}',
                    ],
                  ),
              ],
            ),

          _Section(
            icon: Icons.grid_on,
            title: l10n.fullTable,
            children: [
              _FullTable(
                schedule: _s,
                locale: locale,
                next: _next,
                itemHeader: l10n.tableItem,
                km: km,
              ),
              const SizedBox(height: 8),
              Text(
                [
                  for (final a in ManualAction.values)
                    '${a.abbr(locale)}: ${a.label(locale)}',
                ].join('   '),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),

          _Section(
            icon: Icons.inventory_2_outlined,
            title: l10n.partsAndSpecs,
            children: [
              for (final p in _s.parts) _PartRow(part: p, locale: locale),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      );
}

/// Recuadro con lo que quedó sin hacer de services anteriores.
class _PendingBox extends StatelessWidget {
  final String title;
  final String hint;
  final List<Widget> children;

  const _PendingBox({
    required this.title,
    required this.hint,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withValues(alpha: 0.10),
          border:
              Border.all(color: AppTheme.warningColor.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 20, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warningColor)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...children,
            const SizedBox(height: 4),
            Text(hint,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      );
}

class _TaskRow extends StatelessWidget {
  final String title;
  final List<String> actions;
  final bool highlight;
  final String note;

  const _TaskRow({
    required this.title,
    required this.actions,
    this.highlight = false,
    this.note = '',
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                highlight ? Icons.autorenew : Icons.check_circle_outline,
                size: 18,
                color: highlight ? AppTheme.accentColor : Colors.grey.shade500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    actions.join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      color: highlight
                          ? AppTheme.accentColor
                          : Colors.grey.shade600,
                    ),
                  ),
                  if (note.isNotEmpty)
                    Text(note,
                        style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _PartRow extends StatelessWidget {
  final ManualPart part;
  final String locale;

  /// Etiqueta junto al nombre, ej. "pendiente".
  final String? tag;

  const _PartRow({required this.part, required this.locale, this.tag});

  @override
  Widget build(BuildContext context) {
    final spec = part.spec(locale);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.label_outline, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: part.name(locale),
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  if (tag != null)
                    TextSpan(
                        text: '  · $tag',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.warningColor)),
                ])),
                if (spec.isNotEmpty)
                  Text(spec,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ítems × services, con las abreviaturas del manual.
class _FullTable extends StatelessWidget {
  final ManualSchedule schedule;
  final String locale;
  final int next;
  final String itemHeader;
  final String Function(int) km;

  const _FullTable({
    required this.schedule,
    required this.locale,
    required this.next,
    required this.itemHeader,
    required this.km,
  });

  @override
  Widget build(BuildContext context) {
    final services = [for (var i = 0; i <= schedule.tableServices; i++) i];
    final border = BorderSide(color: Theme.of(context).dividerColor);
    const cellPadding = EdgeInsets.symmetric(horizontal: 4, vertical: 6);
    final nextColor = AppTheme.primaryColor.withValues(alpha: 0.12);

    Widget cell(String text,
            {bool bold = false, Color? color, TextAlign? align}) =>
        Padding(
          padding: cellPadding,
          child: Text(
            text,
            textAlign: align ?? TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: bold ? FontWeight.bold : null,
              color: color,
            ),
          ),
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder(
          horizontalInside: border,
          verticalInside: border,
          top: border,
          bottom: border,
          left: border,
          right: border,
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: {
          0: const FixedColumnWidth(170),
          for (final i in services) i + 1: const FixedColumnWidth(52),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest),
            children: [
              cell(itemHeader, bold: true, align: TextAlign.left),
              for (final i in services)
                Container(
                  color: i == next ? nextColor : null,
                  child: cell('${i + 1}°\n${km(schedule.serviceKm(i))}',
                      bold: true),
                ),
            ],
          ),
          for (final item in schedule.items)
            TableRow(
              children: [
                cell(item.name(locale), align: TextAlign.left),
                for (final i in services)
                  Container(
                    color: i == next ? nextColor : null,
                    child: () {
                      final actions = schedule.actionsAt(item, i);
                      return cell(
                        actions.map((a) => a.abbr(locale)).join(', '),
                        bold: actions.contains(ManualAction.replace),
                        color: actions.contains(ManualAction.replace)
                            ? AppTheme.accentColor
                            : null,
                      );
                    }(),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
