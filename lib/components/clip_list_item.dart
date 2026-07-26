import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/clip.dart';
import '../util/theme.dart';

/// Compact, tap-to-copy card with hover actions.
class ClipListItem extends StatefulWidget {
  final Clip clip;
  final bool isFocused;
  final VoidCallback onCopy;
  final VoidCallback onTogglePin;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  /// When non-null, a drag handle is shown on the left. The int is the
  /// item's index within the surrounding [ReorderableListView].
  final int? reorderIndex;

  const ClipListItem({
    super.key,
    required this.clip,
    required this.isFocused,
    required this.onCopy,
    required this.onTogglePin,
    required this.onRemove,
    required this.onEdit,
    this.reorderIndex,
  });

  @override
  State<ClipListItem> createState() => _ClipListItemState();
}

class _ClipListItemState extends State<ClipListItem> {
  bool _hover = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.clip.text));
    widget.onCopy();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.clip;
    final hasTitle = c.title.trim().isNotEmpty;
    final highlight = _hover || widget.isFocused;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _copy,
        onDoubleTap: widget.onTogglePin,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isFocused
                  ? AppTheme.primary
                  : (highlight ? AppTheme.primary.withValues(alpha: 0.35) : AppTheme.border),
              width: widget.isFocused ? 1.5 : 1,
            ),
            boxShadow: highlight
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.reorderIndex != null)
                ReorderableDragStartListener(
                  index: widget.reorderIndex!,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        size: 16,
                        color: AppTheme.textSecondary.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
              if (c.pinned && widget.reorderIndex == null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.push_pin_rounded,
                    size: 12,
                    color: AppTheme.primary,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasTitle)
                      Text(
                        c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          height: 1.2,
                        ),
                      ),
                    Text(
                      c.text,
                      maxLines: hasTitle ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: hasTitle
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Actions — visible on hover / focus.
              AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: highlight ? 1 : 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IconBtn(
                      tooltip: c.pinned ? 'Unpin' : 'Pin',
                      icon: c.pinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      onTap: widget.onTogglePin,
                    ),
                    _IconBtn(
                      tooltip: 'Edit',
                      icon: Icons.edit_outlined,
                      onTap: widget.onEdit,
                    ),
                    _IconBtn(
                      tooltip: 'Delete',
                      icon: Icons.delete_outline_rounded,
                      onTap: widget.onRemove,
                      danger: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool danger;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 15,
            color: danger ? AppTheme.danger : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
