import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../util/theme.dart';

/// Small keyboard-shortcut chip, e.g. ⌘K, Ctrl+N, or ⌘ + ⏎ icon.
///
/// Each item in [keys] is either a `String` (rendered as monospace text) or an
/// `IconData` (rendered as a small icon). A fixed monospace font keeps glyphs
/// at a predictable size across platforms; icons are used when a glyph like `↵`
/// wouldn't render cleanly.
class KbdChip extends StatelessWidget {
  /// Items to render — each entry is either `String` or `IconData`.
  final List<Object> keys;

  const KbdChip._(this.keys);

  /// Platform-aware `meta` chip. On macOS/web renders "⌘K",
  /// on other platforms renders "Ctrl" + "K" (two chips).
  factory KbdChip.meta(String letter) {
    final isMac = !kIsWeb && Platform.isMacOS;
    final metaLabel = kIsWeb || isMac ? '⌘' : 'Ctrl';
    return KbdChip._(
      kIsWeb || isMac ? [metaLabel + letter] : [metaLabel, letter],
    );
  }

  /// Free-form chip. Each item may be a `String` or an `IconData`.
  /// e.g. `KbdChip.text(['N'])` or `KbdChip.text(['⌘', Icons.keyboard_return_rounded])`
  factory KbdChip.text(List<Object> parts) => KbdChip._(parts);

  /// Convenience: a meta chip followed by an icon (e.g. ⌘ + return icon).
  factory KbdChip.metaIcon(IconData icon) {
    final isMac = !kIsWeb && Platform.isMacOS;
    final metaLabel = kIsWeb || isMac ? '⌘' : 'Ctrl';
    return KbdChip._([metaLabel, icon]);
  }

  @override
  Widget build(BuildContext context) {
    final onLight = DefaultTextStyle.of(context).style.color != Colors.white;
    final fg = onLight ? AppTheme.textSecondary : Colors.white;
    final bg = onLight
        ? AppTheme.textSecondary.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.18);
    final border = onLight
        ? AppTheme.border
        : Colors.white.withValues(alpha: 0.25);

    Widget chip(Widget child) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border, width: 0.8),
          ),
          child: child,
        );

    Widget itemFor(Object item) {
      if (item is IconData) {
        return chip(Icon(item, size: 11, color: fg));
      }
      return chip(
        Text(
          item.toString(),
          style: TextStyle(
            fontSize: 10,
            height: 1.2,
            fontFamily: 'ui-monospace, "SF Mono", Menlo, Consolas, monospace',
            fontWeight: FontWeight.w600,
            color: fg,
            letterSpacing: 0.2,
          ),
        ),
      );
    }

    if (keys.length == 1) return itemFor(keys.first);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          itemFor(keys[i]),
        ],
      ],
    );
  }
}
