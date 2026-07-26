import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/clip.dart';
import '../util/tags.dart';

/// Single source of truth for clips.
/// Persists to [SharedPreferences] under the key `clips`.
class ClipNoteProvider extends ChangeNotifier {
  static const _storageKey = 'clips';

  final List<Clip> _items = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Clips sorted: pinned first (insertion order preserved),
  /// then unpinned newest-first.
  List<Clip> get items {
    final pinned = _items.where((c) => c.pinned).toList();
    final rest = _items.where((c) => !c.pinned).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return [...pinned, ...rest];
  }

  /// Every user tag currently in use, ranked by frequency (descending),
  /// then alphabetically for stable ordering.
  List<TagUsage> get userTagUsage {
    final counts = <String, int>{};
    for (final c in _items) {
      for (final t in c.userTags) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.compareTo(b.key);
      });
    return entries.map((e) => TagUsage(e.key, e.value)).toList();
  }

  /// Filter by search query. Supports:
  ///   * plain substring on title + text (case-insensitive)
  ///   * `tag:foo` to require a tag (repeatable — all must match)
  ///   * `is:pinned` to restrict to pinned clips
  ///
  /// If [activeTag] is set, results are additionally filtered to clips
  /// carrying that tag (user- or auto-).
  List<Clip> search(String query, {String? activeTag}) {
    final trimmed = query.trim();
    final tokens =
        trimmed.isEmpty ? const <String>[] : trimmed.split(RegExp(r'\s+'));

    final requiredTags = <String>[];
    var pinnedOnly = false;
    final textTokens = <String>[];
    for (final tok in tokens) {
      if (tok.toLowerCase().startsWith('tag:') && tok.length > 4) {
        requiredTags.add(tok.substring(4).toLowerCase());
      } else if (tok.toLowerCase() == 'is:pinned') {
        pinnedOnly = true;
      } else {
        textTokens.add(tok.toLowerCase());
      }
    }
    if (activeTag != null && activeTag.isNotEmpty) {
      requiredTags.add(activeTag.toLowerCase());
    }

    bool matches(Clip c) {
      if (pinnedOnly && !c.pinned) return false;
      for (final t in requiredTags) {
        if (!c.hasTag(t)) return false;
      }
      if (textTokens.isEmpty) return true;
      final hay = '${c.title}\n${c.text}'.toLowerCase();
      for (final w in textTokens) {
        if (!hay.contains(w)) return false;
      }
      return true;
    }

    return items.where(matches).toList();
  }

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _items
        ..clear()
        ..addAll(decoded.map((e) => Clip.fromJson(e as Map<String, dynamic>)));
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> addClip(Clip clip) async {
    // Dedupe: bump identical text to top instead of duplicating.
    final existingIdx = _items.indexWhere((c) => c.text == clip.text);
    if (existingIdx != -1) {
      final existing = _items.removeAt(existingIdx);
      // Merge tags from the new clip into the existing one so re-saving with
      // extra tags doesn't lose information.
      final mergedTags = normalizeTagList([
        ...existing.userTags,
        ...clip.userTags,
      ]);
      _items.insert(0, existing.copyWith(userTags: mergedTags));
    } else {
      _items.insert(0, clip);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> updateClip(
    String id, {
    String? text,
    String? title,
    List<String>? userTags,
  }) async {
    final idx = _items.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    _items[idx] = _items[idx].copyWith(
      text: text,
      title: title,
      userTags: userTags,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> removeById(String id) async {
    _items.removeWhere((c) => c.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> clearAll() async {
    if (_items.isEmpty) return;
    _items.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> togglePin(String id) async {
    final idx = _items.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    _items[idx].pinned = !_items[idx].pinned;
    await _persist();
    notifyListeners();
  }

  /// Reorder pinned clips only. Indexes are relative to the pinned sub-list.
  Future<void> reorderPinned(int oldIndex, int newIndex) async {
    final pinned = _items.where((c) => c.pinned).toList();
    if (oldIndex < 0 || oldIndex >= pinned.length) return;
    if (newIndex > pinned.length) newIndex = pinned.length;
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = pinned.removeAt(oldIndex);
    pinned.insert(newIndex, moved);
    final rest = _items.where((c) => !c.pinned).toList();
    _items
      ..clear()
      ..addAll([...pinned, ...rest]);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_items.map((c) => c.toJson()).toList()),
    );
  }
}

/// A tag name plus the number of clips using it.
class TagUsage {
  final String tag;
  final int count;
  const TagUsage(this.tag, this.count);
}
