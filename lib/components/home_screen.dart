import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'search.dart';
import 'tag_filter_bar.dart';
import 'clip_bottom_sheet.dart';
import 'clip_list_item.dart';
import 'kbd_chip.dart';
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

  /// Currently selected tag filter, or null for "all clips".
  String? _activeTag;

  /// Latest visible list, refreshed on every build so the hardware key
  /// handler can act on the current filtered results.
  List<Clip> _visible = const [];

  int _snackSerial = 0;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    _searchController.dispose();
    _searchFocus.dispose();
    _listFocus.dispose();
    WebBridge.onSelectionCaptured = null;
    super.dispose();
  }

  void _snack(String message, {SnackBarAction? action}) {
    // Snackbars with an action (e.g. UNDO) stay longer so there's time to act;
    // plain confirmations disappear quickly.
    final duration = action != null
        ? const Duration(milliseconds: 4000)
        : const Duration(milliseconds: 1400);
    final snackSerial = ++_snackSerial;
    final messenger = ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          action: action,
        ),
      );

    Future.delayed(duration, () {
      if (!mounted || snackSerial != _snackSerial) return;
      messenger.hideCurrentSnackBar();
    });
  }

  Future<void> _openEditor({Clip? edit, String? prefillText}) async {
    final provider = context.read<ClipNoteProvider>();
    final suggestions = provider.userTagUsage.map((u) => u.tag).toList();
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
        tagSuggestions: suggestions,
        onSave: (c) async {
          if (edit == null) {
            await provider.addClip(c);
            _snack('Clip saved');
          } else {
            await provider.updateClip(
              c.id,
              text: c.text,
              title: c.title,
              userTags: c.userTags,
            );
            _snack('Clip updated');
          }
        },
      ),
    );
  }

  /// Global hardware-key handler. Returns `true` when we've consumed the key
  /// so Flutter won't dispatch it further. Modifier combos (⌘K/⌘E) fire
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

    // The following are only handled when the user isn't typing in search.
    if (searchHasFocus) return false;

    if (key == LogicalKeyboardKey.arrowDown) {
      if (_visible.isEmpty) return false;
      setState(() =>
          _focusedIndex = (_focusedIndex + 1).clamp(0, _visible.length - 1));
      return true;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_visible.isEmpty) return false;
      setState(() =>
          _focusedIndex = (_focusedIndex - 1).clamp(0, _visible.length - 1));
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
      if (_activeTag != null) {
        setState(() => _activeTag = null);
        return true;
      }
    }
    return false;
  }

  void _onTagTap(String tag) {
    setState(() {
      _activeTag = (_activeTag == tag) ? null : tag;
      _focusedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClipNoteProvider>();
    final visible = provider.search(_query, activeTag: _activeTag);

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
          TagFilterBar(
            usage: provider.userTagUsage,
            activeTag: _activeTag,
            onTagSelected: (t) => setState(() {
              _activeTag = t;
              _focusedIndex = 0;
            }),
          ),
          if (provider.items.isNotEmpty)
            _buildListToolbar(provider, visible.length),
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
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primary, AppTheme.primaryDark],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryDark.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                // Brand mark
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SvgPicture.asset(
                    'assets/logo.svg',
                    width: 22,
                    height: 22,
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
                const SizedBox(width: 10),
                _NewClipButton(onTap: () => _openEditor()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListToolbar(ClipNoteProvider provider, int visibleCount) {
    final totalCount = provider.items.length;
    final countLabel = visibleCount == totalCount
        ? totalCount == 1
            ? '1 clip'
            : '$totalCount clips'
        : '$visibleCount of $totalCount shown';

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            countLabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const Spacer(),
          Tooltip(
            message: 'Delete every saved clip',
            child: InkWell(
              borderRadius: BorderRadius.circular(5),
              onTap: () => _confirmClearAll(provider),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_sweep_outlined,
                      size: 14,
                      color: AppTheme.danger,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Clear all',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.danger,
                      ),
                    ),
                  ],
                ),
              ),
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
              hasQuery
                  ? Icons.search_off_rounded
                  : Icons.content_paste_off_rounded,
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
                    'Press ',
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  KbdChip.meta('E'),
                  const Text(
                    ' to create one.',
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
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
                  onTagTap: _onTagTap,
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
              onTagTap: _onTagTap,
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

  Future<void> _confirmClearAll(ClipNoteProvider provider) async {
    if (provider.items.isEmpty) return;

    // Snapshot the current clips so the action can be undone from the snackbar.
    final snapshot = List<Clip>.from(provider.items);
    await provider.clearAll();
    if (!mounted) return;
    _snack(
      snapshot.length == 1 ? '1 clip cleared' : '${snapshot.length} clips cleared',
      action: SnackBarAction(
        label: 'UNDO',
        textColor: Colors.white,
        onPressed: () => provider.restoreAll(snapshot),
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

class _NewClipButton extends StatefulWidget {
  final VoidCallback onTap;
  const _NewClipButton({required this.onTap});

  @override
  State<_NewClipButton> createState() => _NewClipButtonState();
}

class _NewClipButtonState extends State<_NewClipButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'New clip (⌘E)',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          height: 32,
          decoration: BoxDecoration(
            color:
                _hovered ? Colors.white : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.18 : 0.10),
                blurRadius: _hovered ? 10 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'New',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
