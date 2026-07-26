import 'package:flutter/material.dart';

import '../helper/clip_note_provider.dart';
import '../util/tags.dart';
import '../util/theme.dart';

/// A horizontal, scrollable row of tag filter chips shown directly below the
/// app bar. Tapping a chip toggles the active tag filter. An "All" chip on
/// the left resets the filter; a "Pinned" chip on the right filters to
/// starred/pinned clips.
class TagFilterBar extends StatelessWidget {
  final List<TagUsage> usage;
  final String? activeTag;
  final ValueChanged<String?> onTagSelected;
  final bool showPinnedShortcut;
  final VoidCallback? onPinnedTap;

  const TagFilterBar({
    super.key,
    required this.usage,
    required this.activeTag,
    required this.onTagSelected,
    this.showPinnedShortcut = false,
    this.onPinnedTap,
  });

  @override
  Widget build(BuildContext context) {
    // Hide the bar entirely when there are no tags to filter by (and no
    // pinned shortcut requested) — avoids empty visual real estate.
    if (usage.isEmpty && !showPinnedShortcut) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.border),
        ),
      ),
      child: SizedBox(
        height: 30,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          children: [
            _FilterChip(
              label: 'All',
              selected: activeTag == null,
              onTap: () => onTagSelected(null),
            ),
            for (final u in usage) ...[
              const SizedBox(width: 4),
              _FilterChip(
                label: '#${u.tag}',
                selected: activeTag == u.tag,
                reserved: kReservedTags.contains(u.tag),
                count: u.count,
                onTap: () =>
                    onTagSelected(activeTag == u.tag ? null : u.tag),
              ),
            ],
            if (showPinnedShortcut && onPinnedTap != null) ...[
              const SizedBox(width: 4),
              _FilterChip(
                label: 'Pinned',
                icon: Icons.push_pin_rounded,
                selected: false,
                onTap: onPinnedTap!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool reserved;
  final int? count;
  final IconData? icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.reserved = false,
    this.count,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final base = reserved ? AppTheme.textSecondary : AppTheme.primary;
    final bg = selected
        ? base.withValues(alpha: 0.12)
        : Colors.transparent;
    final borderColor = selected
        ? base.withValues(alpha: 0.55)
        : AppTheme.border;
    final fg = selected ? base : AppTheme.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 10, color: fg),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    color: fg.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
