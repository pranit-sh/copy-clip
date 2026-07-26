import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/clip.dart';
import '../util/theme.dart';
import 'kbd_chip.dart';
import 'tag_chip_field.dart';

/// Bottom sheet used both for creating and editing a clip.
class ClipEditorSheet extends StatefulWidget {
  final Clip? initial;
  final String? prefillText;
  final ValueChanged<Clip> onSave;

  /// Existing tags across the whole store — used to power autocomplete
  /// suggestions in the tag input.
  final List<String> tagSuggestions;

  const ClipEditorSheet({
    super.key,
    this.initial,
    this.prefillText,
    required this.onSave,
    this.tagSuggestions = const [],
  });

  @override
  State<ClipEditorSheet> createState() => _ClipEditorSheetState();
}

class _ClipEditorSheetState extends State<ClipEditorSheet> {
  late final TextEditingController _text;
  late final TextEditingController _title;
  final _textFocus = FocusNode();
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(
      text: widget.initial?.text ?? widget.prefillText ?? '',
    );
    _title = TextEditingController(text: widget.initial?.title ?? '');
    _tags = List<String>.from(widget.initial?.userTags ?? const []);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _title.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  void _save() {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    final title = _title.text.trim();
    final saved = (widget.initial ?? Clip(text: text)).copyWith(
      text: text,
      title: title,
      userTags: _tags,
    );
    widget.onSave(saved);
    Navigator.of(context).pop();
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    FocusNode? focus,
    int minLines = 1,
    int? maxLines = 1,
    TextInputAction action = TextInputAction.next,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          focusNode: focus,
          minLines: minLines,
          maxLines: maxLines,
          textInputAction: action,
          onSubmitted: (_) => onSubmitted?.call(),
          cursorColor: AppTheme.primary,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            filled: true,
            fillColor: AppTheme.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.enter):
            const _SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.enter):
            const _SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const _CancelIntent(),
      },
      child: Actions(
        actions: {
          _SaveIntent: CallbackAction<_SaveIntent>(onInvoke: (_) {
            _save();
            return null;
          }),
          _CancelIntent: CallbackAction<_CancelIntent>(onInvoke: (_) {
            Navigator.of(context).pop();
            return null;
          }),
        },
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              Text(
                isEditing ? 'Edit clip' : 'New clip',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _field(
                controller: _text,
                focus: _textFocus,
                label: 'CONTENT',
                hint: 'Paste or type your clip…',
                minLines: 3,
                maxLines: 6,
                action: TextInputAction.newline,
              ),
              const SizedBox(height: 10),
              _field(
                controller: _title,
                label: 'TITLE (OPTIONAL)',
                hint: 'A short label so you find it later',
                action: TextInputAction.done,
                onSubmitted: _save,
              ),
              const SizedBox(height: 10),
              TagChipField(
                value: _tags,
                onChanged: (v) => setState(() => _tags = v),
                suggestions: widget.tagSuggestions,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        foregroundColor: AppTheme.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppTheme.border),
                        ),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isEditing ? 'Save changes' : 'Save clip',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!isEditing) ...[
                            const SizedBox(width: 8),
                            DefaultTextStyle(
                              style: const TextStyle(color: Colors.white),
                              child: KbdChip.metaIcon(
                                Icons.keyboard_return_rounded,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}
