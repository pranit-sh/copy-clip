import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/clip.dart';

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

  /// Filter by case-insensitive substring match on title + text.
  List<Clip> search(String query) {
    if (query.trim().isEmpty) return items;
    final q = query.toLowerCase();
    return items
        .where((c) =>
            c.text.toLowerCase().contains(q) ||
            c.title.toLowerCase().contains(q))
        .toList();
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
      _items.insert(0, existing);
    } else {
      _items.insert(0, clip);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> updateClip(String id, {String? text, String? title}) async {
    final idx = _items.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    _items[idx] = _items[idx].copyWith(text: text, title: title);
    await _persist();
    notifyListeners();
  }

  Future<void> removeById(String id) async {
    _items.removeWhere((c) => c.id == id);
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
