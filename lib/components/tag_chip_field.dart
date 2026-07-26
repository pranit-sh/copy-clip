import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'kbd_chip.dart';
import '../util/tags.dart';
import '../util/theme.dart';

/// A compact chip-style tag input.
///
/// * User types a tag → space/comma commits it as a chip.
/// * Backspace on an empty field removes the last chip.
/// * Suggestions from [suggestions] show up below the field, filtered by
///   the current draft text; tapping a suggestion appends it.
/// * Enforces [kMaxTagsPerClip] and normalizes via [normalizeUserTag].
class TagChipField extends StatefulWidget {
  final List<String> value;
  final ValueChanged<List<String>> onChanged;
  final List<String> suggestions;

  const TagChipField({
    super.key,
    required this.value,
    required this.onChanged,
    this.suggestions = const [],
  });

  @override
  State<TagChipField> createState() => _TagChipFieldState();
}

class _TagChipFieldState extends State<TagChipField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commitDraft() {
    final draft = _controller.text;
    if (draft.trim().isEmpty) return;
    final n = normalizeUserTag(draft);
    _controller.clear();
    if (n == null) return;
    if (widget.value.contains(n)) return;
    if (widget.value.length >= kMaxTagsPerClip) return;
    widget.onChanged([...widget.value, n]);
  }

  void _removeAt(int i) {
    final next = [...widget.value]..removeAt(i);
    widget.onChanged(next);
  }

  void _addSuggestion(String s) {
    if (widget.value.contains(s)) return;
    if (widget.value.length >= kMaxTagsPerClip) return;
    widget.onChanged([...widget.value, s]);
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    // Suggestions are intentionally NOT filtered by the current draft text —
    // filtering as the user types changes the number of chips and shifts the
    // layout. We only drop tags that are already added.
    final filteredSuggestions = widget.suggestions
        .where((s) => !widget.value.contains(s))
        .take(6)
        .toList();
    final capReached = widget.value.length >= kMaxTagsPerClip;
    final hasDraft = _controller.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'TAGS (OPTIONAL)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            Text(
              '${widget.value.length}/$kMaxTagsPerClip',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focus.hasFocus ? AppTheme.primary : AppTheme.border,
              width: _focus.hasFocus ? 1.5 : 1,
            ),
          ),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < widget.value.length; i++)
                _TagChip(
                  label: widget.value[i],
                  onRemove: () => _removeAt(i),
                ),
              // Hidden-when-full input.
              if (!capReached)
                IntrinsicWidth(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(minWidth: 80, maxWidth: 200),
                    child: KeyboardListener(
                      focusNode: FocusNode(skipTraversal: true),
                      onKeyEvent: (event) {
                        if (event is! KeyDownEvent) return;
                        if (event.logicalKey == LogicalKeyboardKey.backspace &&
                            _controller.text.isEmpty &&
                            widget.value.isNotEmpty) {
                          _removeAt(widget.value.length - 1);
                        }
                      },
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: widget.value.isEmpty
                              ? 'Type a tag…'
                              : 'Add another…',
                          hintStyle: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          suffix: hasDraft
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      KbdChip.text(const [
                                        Icons.space_bar_rounded,
                                      ]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'to add',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textSecondary
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                        ),
                        onChanged: (v) {
                          // Commit on space or comma.
                          if (v.endsWith(' ') || v.endsWith(',')) {
                            _controller.text = v.substring(0, v.length - 1);
                            _commitDraft();
                          } else {
                            // Rebuild for suggestions.
                            setState(() {});
                          }
                        },
                        onSubmitted: (_) {
                          _commitDraft();
                          _focus.requestFocus();
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (filteredSuggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final s in filteredSuggestions)
                _SuggestionChip(label: s, onTap: () => _addSuggestion(s)),
            ],
          ),
        ],
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _TagChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 4, top: 3, bottom: 3),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 12,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border),
        ),
        child: Text(
          '+ $label',
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
