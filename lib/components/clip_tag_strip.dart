import 'package:flutter/material.dart';

import '../models/clip.dart';
import '../util/tags.dart';
import '../util/theme.dart';

/// Inline row-level chip strip. Shows up to [max] tags for a clip, with
/// system-owned tags styled differently.
class ClipTagStrip extends StatelessWidget {
  final Clip clip;
  final int max;
  final ValueChanged<String>? onTagTap;

  const ClipTagStrip({
    super.key,
    required this.clip,
    this.max = 3,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    final tags = clip.allTags.take(max).toList();
    if (tags.isEmpty) return const SizedBox.shrink();
    final overflow = clip.allTags.length - tags.length;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        children: [
          for (final t in tags)
            _MiniChip(
              label: t,
              reserved: kReservedTags.contains(t),
              onTap: onTagTap == null ? null : () => onTagTap!(t),
            ),
          if (overflow > 0)
            _MiniChip(
              label: '+$overflow',
              reserved: true,
              onTap: null,
            ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final bool reserved;
  final VoidCallback? onTap;

  const _MiniChip({
    required this.label,
    required this.reserved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = reserved ? AppTheme.textSecondary : AppTheme.primary;
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: base.withValues(alpha: 0.22), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: base,
          letterSpacing: 0.2,
        ),
      ),
    );
    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: child,
    );
  }
}
