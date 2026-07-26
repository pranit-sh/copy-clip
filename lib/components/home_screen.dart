import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'clip_bottom_sheet.dart';
import 'clip_list_item.dart';
import 'kbd_chip.dart';
import 'search.dart';
import '../helper/clip_note_provider.dart';
import '../models/clip.dart';
import '../util/theme.dart';
import '../web_bridge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _listFocus = FocusNode();
  String _query = '';
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Listen for text sent from the Chrome extension context menu.
    WebBridge.onSelectionCaptured = (selection) {
      if (!mounted) return;
      _openEditor(prefillText: selection);
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _listFocus.dispose();
    WebBridge.onSelectionCaptured = null;
    super.dispose();
  }

  void _snack(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1400),
          action: action,
        ),
      );
  }

  Future<void> _openEditor({Clip? edit, String? prefillText}) async {
    final provider = context.read<ClipNoteProvider>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (_) => ClipEditorSheet(
        initial: edit,
        prefillText: prefillText,
        onSave: (c) async {
          if (edit == null) {
            await provider.addClip(c);
            _snack('Clip saved');
          } else {
            await provider.updateClip(c.id, text: c.text, title: c.title);
            _snack('Clip updated');
          }
        },
      ),
    );
  }

  Future<void> _saveFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      _snack('Clipboard is empty');
      return;
    }
    await _openEditor(prefillText: text);
  }

  void _handleShortcut(KeyEvent event, List<Clip> visible) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    final searchHasFocus = _searchFocus.hasFocus;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() => _focusedIndex =
          (_focusedIndex + 1).clamp(0, visible.length - 1));
    } else if (key == LogicalKeyboardKey.arrowUp) {
      setState(() =>
          _focusedIndex = (_focusedIndex - 1).clamp(0, visible.length - 1));
    } else if (key == LogicalKeyboardKey.enter && visible.isNotEmpty) {
      final c = visible[_focusedIndex.clamp(0, visible.length - 1)];
      Clipboard.setData(ClipboardData(text: c.text));
      _snack('Copied to clipboard');
    } else if (key == LogicalKeyboardKey.escape) {
      if (_query.isNotEmpty) {
        _searchController.clear();
        setState(() => _query = '');
      } else if (searchHasFocus) {
        _searchFocus.unfocus();
      }
    } else if (!searchHasFocus &&
        (key == LogicalKeyboardKey.keyN ||
            key == LogicalKeyboardKey.keyC)) {
      // Single-key shortcuts, only when search doesn't have focus.
      if (key == LogicalKeyboardKey.keyN) {
        _openEditor();
      } else if (key == LogicalKeyboardKey.keyC) {
        _saveFromClipboard();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClipNoteProvider>();
    final visible = provider.search(_query);

    // Keep focused index in-bounds when list shrinks.
    if (_focusedIndex >= visible.length) {
      _focusedIndex = visible.isEmpty ? 0 : visible.length - 1;
    }

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
            const _FocusSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK):
            const _FocusSearchIntent(),
        // NOTE: Chrome reserves ⌘N / Ctrl+N for "new window", so we can't
        // hook that inside the popup. Instead we use plain `N` when the search
        // field doesn't have focus (handled in _handleShortcut).
      },
      child: Actions(
        actions: {
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
            onInvoke: (_) {
              _searchFocus.requestFocus();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            _handleShortcut(event, visible);
            return KeyEventResult.ignored;
          },
          child: Scaffold(
            backgroundColor: AppTheme.bg,
            appBar: _buildAppBar(context),
            body: Column(
              children: [
                _buildQuickBar(context, provider),
                Expanded(
                  child: visible.isEmpty
                      ? _buildEmptyState()
                      : _buildList(visible, provider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.primary,
      elevation: 0,
      titleSpacing: 12,
      toolbarHeight: 52,
      title: Row(
        children: [
          const Icon(Icons.content_paste_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Copy Clip',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SearchField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: (v) => setState(() {
                _query = v;
                _focusedIndex = 0;
              }),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Report a bug',
          iconSize: 18,
          color: Colors.white.withValues(alpha: 0.85),
          icon: const Icon(Icons.bug_report_outlined),
          onPressed: () => launchUrl(
            Uri.parse('https://github.com/pranit-sh/copy-clip/issues'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickBar(BuildContext context, ClipNoteProvider p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _saveFromClipboard,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: const BorderSide(color: AppTheme.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.download_rounded, size: 15),
              label: const Text(
                'Save from clipboard',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 6),
          FilledButton.icon(
            onPressed: () => _openEditor(),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text(
              'New',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasQuery = _query.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasQuery ? Icons.search_off_rounded : Icons.content_paste_off_rounded,
              size: 40,
              color: AppTheme.textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 10),
            Text(
              hasQuery ? 'No matches' : 'No clips yet',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            if (hasQuery)
              const Text(
                'Try a different keyword.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Save from clipboard or press ',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  KbdChip.text(const ['N']),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Clip> visible, ClipNoteProvider provider) {
    // Two sections: pinned (reorderable) + rest.
    final pinned = visible.where((c) => c.pinned).toList();
    final rest = visible.where((c) => !c.pinned).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      children: [
        if (pinned.isNotEmpty) ...[
          const _SectionHeader(label: 'Pinned'),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: pinned.length,
            onReorder: (o, n) => provider.reorderPinned(o, n),
            itemBuilder: (context, i) {
              final clip = pinned[i];
              final indexInVisible = visible.indexOf(clip);
              return KeyedSubtree(
                key: ValueKey('pinned-${clip.id}'),
                child: ClipListItem(
                  clip: clip,
                  isFocused: indexInVisible == _focusedIndex,
                  reorderIndex: pinned.length > 1 ? i : null,
                  onCopy: () => _snack('Copied'),
                  onTogglePin: () => provider.togglePin(clip.id),
                  onRemove: () => _confirmDelete(clip, provider),
                  onEdit: () => _openEditor(edit: clip),
                ),
              );
            },
          ),
        ],
        if (rest.isNotEmpty) ...[
          if (pinned.isNotEmpty) const _SectionHeader(label: 'Recent'),
          ...rest.map((clip) {
            final indexInVisible = visible.indexOf(clip);
            return ClipListItem(
              key: ValueKey(clip.id),
              clip: clip,
              isFocused: indexInVisible == _focusedIndex,
              onCopy: () => _snack('Copied'),
              onTogglePin: () => provider.togglePin(clip.id),
              onRemove: () => _confirmDelete(clip, provider),
              onEdit: () => _openEditor(edit: clip),
            );
          }),
        ],
      ],
    );
  }

  Future<void> _confirmDelete(Clip clip, ClipNoteProvider provider) async {
    await provider.removeById(clip.id);
    if (!mounted) return;
    _snack(
      'Clip deleted',
      action: SnackBarAction(
        label: 'UNDO',
        textColor: Colors.white,
        onPressed: () => provider.addClip(clip),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

// ignore: unused_element
bool get _kIsWebRef => kIsWeb;
