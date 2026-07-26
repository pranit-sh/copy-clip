import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  /// Latest visible list, refreshed on every build so the hardware key
  /// handler can act on the current filtered results.
  List<Clip> _visible = const [];

  /// Latest text seen on the system clipboard (for the peek card).
  String? _clipboardText;

  /// Clipboard texts the user explicitly dismissed this session.
  final Set<String> _dismissedClipboardTexts = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Register a hardware-level key handler. Unlike Shortcuts/CallbackShortcuts
    // this does NOT depend on any Focus node being in the current focus chain,
    // which matters for a Chrome-extension popup where focus can end up in a
    // subtree we don't control (or nowhere at all) after modals/text fields.
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
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
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
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

  /// Global hardware-key handler. Returns `true` when we've consumed the key
  /// so Flutter won't dispatch it further. Modifier combos (⌘K/⌘E/⌘⇧V) fire
  /// regardless of focus; arrow/enter/escape only fire when the search field
  /// doesn't have focus (so typing in search still works normally).
  bool _onHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final key = event.logicalKey;
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    final meta = keys.contains(LogicalKeyboardKey.metaLeft) ||
        keys.contains(LogicalKeyboardKey.metaRight);
    final ctrl = keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight);
    final shift = keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight);
    final mod = meta || ctrl;
    final searchHasFocus = _searchFocus.hasFocus;

    // ⌘/Ctrl + K → focus search
    if (mod && !shift && key == LogicalKeyboardKey.keyK) {
      _searchFocus.requestFocus();
      return true;
    }
    // ⌘/Ctrl + E → new clip
    if (mod && !shift && key == LogicalKeyboardKey.keyE) {
      _openEditor();
      return true;
    }
    // ⌘/Ctrl + Shift + V → save clipboard as clip
    if (mod && shift && key == LogicalKeyboardKey.keyV) {
      _saveFromClipboard();
      return true;
    }

    // The following are only handled when the user isn't typing in search.
    if (searchHasFocus) return false;

    if (key == LogicalKeyboardKey.arrowDown) {
      if (_visible.isEmpty) return false;
      setState(() => _focusedIndex =
          (_focusedIndex + 1).clamp(0, _visible.length - 1));
      return true;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_visible.isEmpty) return false;
      setState(() => _focusedIndex =
          (_focusedIndex - 1).clamp(0, _visible.length - 1));
      return true;
    }
    if (key == LogicalKeyboardKey.enter && _visible.isNotEmpty) {
      final c = _visible[_focusedIndex.clamp(0, _visible.length - 1)];
      Clipboard.setData(ClipboardData(text: c.text));
      _snack('Copied to clipboard');
      return true;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (_query.isNotEmpty) {
        _searchController.clear();
        setState(() => _query = '');
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClipNoteProvider>();
    final visible = provider.search(_query);

    // Keep focused index in-bounds when list shrinks.
    if (_focusedIndex >= visible.length) {
      _focusedIndex = visible.isEmpty ? 0 : visible.length - 1;
    }
    // Expose the current visible list to the hardware-key handler.
    _visible = visible;

    return Scaffold(
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
          SvgPicture.asset(
            'assets/logo.svg',
            width: 22,
            height: 22,
          ),
          const SizedBox(width: 16),
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
          const SizedBox(width: 16),
          Tooltip(
            message: 'New clip (⌘E)',
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
                  KbdChip.meta('E'),
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

// ignore: unused_element
bool get _kIsWebRef => kIsWeb;
