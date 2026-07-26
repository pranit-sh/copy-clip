import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'clip_bottom_sheet.dart';
import 'clip_list_item.dart';
import 'clipboard_peek_card.dart';
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _listFocus = FocusNode();
  String _query = '';
  int _focusedIndex = 0;

  /// Latest text seen on the system clipboard (for the peek card).
  String? _clipboardText;

  /// Clipboard texts the user explicitly dismissed this session.
  final Set<String> _dismissedClipboardTexts = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Listen for text sent from the Chrome extension context menu.
    WebBridge.onSelectionCaptured = (selection) {
      if (!mounted) return;
      _openEditor(prefillText: selection);
    };
    // Initial clipboard read after first frame (so we can access services).
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshClipboard());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshClipboard();
    }
  }

  Future<void> _refreshClipboard() async {
    final text = await readClipboardText();
    if (!mounted) return;
    if (text != _clipboardText) {
      setState(() => _clipboardText = text);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    // Clear the peek card once handled.
    setState(() => _clipboardText = null);
  }

  void _dismissClipboardPeek() {
    if (_clipboardText != null) {
      _dismissedClipboardTexts.add(_clipboardText!);
      setState(() => _clipboardText = null);
    }
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
                if (_shouldShowPeek(provider))
                  ClipboardPeekCard(
                    text: _clipboardText!,
                    onSave: _saveFromClipboard,
                    onDismiss: _dismissClipboardPeek,
                  ),
                Expanded(
                  child: visible.isEmpty
                      ? _buildEmptyState()
                      : _buildList(visible, provider),
                ),
                _buildFooter(),
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
          const SizedBox(width: 8),
          Tooltip(
            message: 'New clip (N)',
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => _openEditor(),
                borderRadius: BorderRadius.circular(8),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: const [],
    );
  }

  bool _shouldShowPeek(ClipNoteProvider provider) {
    final t = _clipboardText;
    if (t == null || t.isEmpty) return false;
    if (_dismissedClipboardTexts.contains(t)) return false;
    // Skip if we already have this text saved.
    for (final c in provider.items) {
      if (c.text.trim() == t) return false;
    }
    return true;
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

  Widget _buildFooter() {
    final linkStyle = TextStyle(
      fontSize: 10,
      color: AppTheme.textSecondary.withValues(alpha: 0.9),
      fontWeight: FontWeight.w500,
    );
    final dotStyle = TextStyle(
      fontSize: 10,
      color: AppTheme.textSecondary.withValues(alpha: 0.45),
    );
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        border: Border(
          top: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => launchUrl(
              Uri.parse('https://github.com/pranit-sh/copy-clip/issues'),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text('Report a bug', style: linkStyle),
            ),
          ),
          Text(' · ', style: dotStyle),
          InkWell(
            onTap: () => launchUrl(
              Uri.parse('https://github.com/pranit-sh/copy-clip'),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text('GitHub', style: linkStyle),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => launchUrl(
              Uri.parse('https://github.com/pranit-sh'),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text('by @pranit-sh', style: linkStyle),
            ),
          ),
          Text(' · ', style: dotStyle),
          Text('v2.0.0', style: linkStyle),
        ],
      ),
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
