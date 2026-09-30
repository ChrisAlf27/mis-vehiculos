import 'package:flutter/material.dart';
import 'package:vehiculos_app/l10n/app_localizations.dart';

/// Elige un emoji como ícono: una grilla de sugerencias más un campo para
/// escribir cualquier otro desde el teclado del teléfono.
class EmojiPickerField extends StatefulWidget {
  final String value;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;

  const EmojiPickerField({
    super.key,
    required this.value,
    required this.suggestions,
    required this.onChanged,
  });

  static const vehicleSuggestions = [
    '🚗',
    '🚙',
    '🛻',
    '🚕',
    '🏍️',
    '🛵',
    '🚲',
    '🛴',
    '🚚',
    '🚛',
    '🚜',
    '🚐',
    '🚌',
    '🏎️',
    '⛵',
    '🚤',
  ];

  static const maintenanceSuggestions = [
    '🛢️',
    '💨',
    '🌬️',
    '⚡',
    '🔋',
    '❄️',
    '🌡️',
    '⚙️',
    '🔗',
    '🔩',
    '🔧',
    '🛞',
    '📐',
    '🔴',
    '🟠',
    '💧',
    '🧴',
    '🧽',
    '🪛',
    '📋',
    '🔦',
    '🛡️',
  ];

  @override
  State<EmojiPickerField> createState() => _EmojiPickerFieldState();
}

class _EmojiPickerFieldState extends State<EmojiPickerField> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.value);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _select(String emoji) {
    _ctrl.text = emoji;
    widget.onChanged(emoji);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 90,
              child: TextField(
                controller: _ctrl,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26),
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.iconLabel),
                onChanged: (v) {
                  final t = v.trim();
                  if (t.isNotEmpty) widget.onChanged(t);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.emojiHint,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final e in widget.suggestions)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _select(e),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _ctrl.text == e ? primary : Colors.grey.shade300,
                      width: _ctrl.text == e ? 2 : 1,
                    ),
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 22)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
